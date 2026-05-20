//
//  StationListViewModel.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class StationListViewModel: ObservableObject {
    /// Full station list for the selected network (from API / SwiftData cache).
    @Published private(set) var stations: [MobilityStation] = []
    /// Stations in the current map viewport (client-side only, no network).
    @Published private(set) var mapStations: [MobilityStation] = []
    /// Keeps the user-picked station on the map after camera moves refresh `mapStations`.
    private var mapHighlightStation: MobilityStation?
    @Published private(set) var networks: [MobilityNetwork] = []
    @Published var selectedNetworkId: String = APIConfiguration.defaultNetworkId
    @Published var searchText = ""
    @Published var sortOption: StationSortOption = .nearest
    @Published var filterOption: StationFilterOption = .all
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var dataSource: DataSourceKind = .live
    @Published private(set) var isStale = false
    @Published private(set) var lastFetchedAt: Date?
    @Published private(set) var userLocation: CLLocationSnapshot?
    @Published private(set) var favoriteKeys: Set<String> = []
    @Published private(set) var favoriteNetworkIds: Set<String> = []
    /// City from the nearest CityBikes network (e.g. "Paris").
    @Published private(set) var currentCityName: String = ""
    /// Bike-share system name (e.g. "Vélib'").
    @Published private(set) var currentNetworkName: String = ""
    @Published private(set) var isBootstrapping = false
    /// Legacy combined label; prefer `currentCityName` + `currentNetworkName` in UI.
    @Published private(set) var locationSubtitle: String = ""
    @Published private(set) var mapFocusCoordinate: CLLocationCoordinate2D?
    @Published private(set) var mapFocusRevision = UUID()
    /// Resolved city name for the Current location row in Choose city.
    @Published private(set) var currentLocationPickerTitle: String = String(localized: "Unknown")
    @Published private(set) var cityWeather: WeatherSnapshot?
    @Published private(set) var isLoadingCityWeather = false

    var usesCurrentLocationSelection: Bool {
        dependencies.selectedCityStore.usesCurrentLocation
    }

    /// City hub from the selected network — used for map focus and walking directions.
    var cityHubCoordinate: CLLocationCoordinate2D? {
        mapFocusCoordinate ?? lastFetchAnchor
    }

    /// Map anchor for distance / “you are here”: GPS only when Current location is selected; otherwise city hub.
    var walkingRouteOrigin: CLLocationCoordinate2D? {
        if usesCurrentLocationSelection, let user = userLocation {
            return CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        }
        return cityHubCoordinate
    }
    /// Cities from bundled `networks.json` (settings picker).
    var availableCities: [MobilityNetwork] {
        dependencies.localNetworks.allNetworks
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    private let dependencies: AppDependencies
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var lastFetchAnchor: CLLocationCoordinate2D?
    /// Last `onMapCameraChange` region (unmodified). Used for pin queries while panning.
    private var visibleMapRegion: MKCoordinateRegion?
    private var mapViewportUpdateTask: Task<Void, Never>?
    private var mapViewportUpdateGeneration = 0
    private var networksLoaded = false
    private var hasBootstrapped = false
    /// Networks whose stations were loaded from the API at least once this app session.
    private var sessionFetchedNetworkIds: Set<String> = []
    private var cityWeatherTask: Task<Void, Never>?

    static let defaultMapCenter = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        $searchText
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        dependencies.searchHistoryStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var searchHistory: [String] {
        dependencies.searchHistoryStore.items
    }

    /// Stations matching the current search text (name / address), without list filter options.
    var searchResults: [MobilityStation] {
        filterStationsMatchingSearch(stations)
    }

    var displayedStations: [MobilityStation] {
        var result = filterStationsMatchingSearch(stations)
        switch filterOption {
        case .all: break
        case .hasBikes: result = result.filter { ($0.freeBikes ?? 0) > 0 }
        case .hasDocks: result = result.filter { ($0.emptySlots ?? 0) > 0 }
        case .favoritesOnly:
            result = result.filter { favoriteKeys.contains($0.favoriteKey) }
        }
        return sorted(result)
    }

    func applySearchHistory(_ term: String) {
        searchText = term
    }

    func commitSearchToHistory() {
        dependencies.searchHistoryStore.record(searchText)
    }

    func removeSearchHistory(_ term: String) {
        dependencies.searchHistoryStore.remove(term)
    }

    /// Ensures the full network catalog is loaded before text search.
    func prepareForStationSearch() async {
        await loadAllStationsForSelectedNetwork(forceRefresh: false)
    }

    private func filterStationsMatchingSearch(_ source: [MobilityStation]) -> [MobilityStation] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return source }
        let query = trimmed.lowercased()
        return source.filter { station in
            station.name.lowercased().contains(query) ||
            station.locationDisplayName.lowercased().contains(query) ||
            (station.stationCode?.lowercased().contains(query) ?? false)
        }
    }

    /// Launch: city center + cached stations from SwiftData immediately; network refresh runs in the background.
    func bootstrap() async {
        if hasBootstrapped { return }
        hasBootstrapped = true
        isBootstrapping = true
        defer { isBootstrapping = false }

        async let cacheReady: Void = dependencies.prepareCacheIfNeeded()
        async let favoritesTask: Void = refreshFavoriteKeys()
        async let favoriteNetworksTask: Void = refreshFavoriteNetworkIds()
        _ = await (cacheReady, favoritesTask, favoriteNetworksTask)

        await loadNetworksFromCacheIfNeeded()
        await applyPersistedOrDefaultCity()
        adoptCityAnchorForSelectedNetwork()

        if stations.isEmpty {
            loadState = .loading
        }
        await applyCachedStationsIfAvailable()
        await loadBundledLondonIfNeeded()
        publishMapStationsAroundFocus()
        refreshCityWeather()

        Task(priority: .utility) {
            await refreshCatalogAndStationsFromNetwork()
        }
    }

    /// Choose city → Current location: map and distances use device GPS when available.
    func selectCurrentLocation() async {
        dependencies.selectedCityStore.selectCurrentLocation()
        loadTask?.cancel()
        cityWeatherTask?.cancel()
        cityWeather = nil
        isLoadingCityWeather = true
        stations = []
        mapStations = []
        visibleMapRegion = nil
        if loadState != .idle {
            loadState = .loading
        }
        await applyCurrentLocationAnchor()
        await applyCachedStationsIfAvailable()
        publishMapStationsAroundFocus()
        await refreshStationsFromNetwork()
        await refreshCurrentLocationPickerTitle()
        refreshCityWeather()
    }

    func refreshCurrentLocationPickerTitle() async {
        if dependencies.locationService.authorizationStatus == .notDetermined {
            await dependencies.locationService.requestAuthorization()
        }
        if dependencies.locationService.authorizationStatus == .authorized {
            _ = await resolveDeviceLocation()
        }
        guard let user = userLocation else {
            currentLocationPickerTitle = String(localized: "Unknown")
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        let resolved = await CityNameResolver.resolveCityName(for: coordinate)
        currentLocationPickerTitle = resolved ?? String(localized: "Unknown")
    }

    /// User-selected city: map + cached stations immediately; live fetch in the background.
    func selectCity(_ network: MobilityNetwork) {
        applyCitySelectionImmediately(network)
        refreshCityWeather()
        Task {
            await applyCachedStationsIfAvailable()
            if stations.isEmpty {
                loadState = .loading
            }
            publishMapStationsAroundFocus()
            await refreshStationsFromNetwork()
        }
    }

    /// Recenters map data + returns the coordinate the camera should move to.
    /// Current location → GPS; chosen city → hub; otherwise London (Santander Cycles).
    @discardableResult
    func recenterMap() async -> CLLocationCoordinate2D? {
        let center: CLLocationCoordinate2D?

        if usesCurrentLocationSelection {
            if dependencies.locationService.authorizationStatus == .notDetermined {
                await dependencies.locationService.requestAuthorization()
            }
            if await resolveDeviceLocation(), let user = userLocation {
                let gps = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
                center = gps
                mapFocusCoordinate = gps
                lastFetchAnchor = gps
                selectNetwork(near: gps, persistCityChoice: false)
                await updateCityNameFromDeviceLocation(gps)
            } else {
                center = recenterOnCityHubOrLondon()
            }
        } else if dependencies.selectedCityStore.hasExplicitSelection {
            center = recenterOnCityHubOrLondon()
        } else {
            applyDefaultLondonNetwork()
            center = mapFocusCoordinate
        }

        if let center {
            mapFocusCoordinate = center
            lastFetchAnchor = center
            mapFocusRevision = UUID()
            publishMapStationsAroundFocus()
        }
        return center
    }

    /// Legacy name used by the map location FAB.
    func recenterForWalking() {
        Task { await recenterMap() }
    }

    /// Location FAB: device GPS only when **Current location** is selected; otherwise the chosen city hub.
    func focusCoordinateForLocationFAB() async -> CLLocationCoordinate2D? {
        if usesCurrentLocationSelection {
            if dependencies.locationService.authorizationStatus == .notDetermined {
                await dependencies.locationService.requestAuthorization()
            }
            guard await resolveDeviceLocation(), let user = userLocation else {
                return recenterOnCityHubOrLondon()
            }
            let gps = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
            mapFocusCoordinate = gps
            lastFetchAnchor = gps
            selectNetwork(near: gps, persistCityChoice: false)
            await updateCityNameFromDeviceLocation(gps)
            publishMapStationsAroundFocus()
            return gps
        }

        guard let hub = recenterOnCityHubOrLondon() else { return nil }
        publishMapStationsAroundFocus()
        return hub
    }

    func shouldFrameMapFocusLikeStationDetail(at coordinate: CLLocationCoordinate2D) -> Bool {
        usesCurrentLocationSelection
    }

    /// Centers on the selected city's hub only (settings / city switch).
    func recenterOnSelectedCity() {
        adoptCityAnchorForSelectedNetwork()
        publishMapStationsAroundFocus()
    }

    private func recenterOnCityHubOrLondon() -> CLLocationCoordinate2D? {
        adoptCityAnchorForSelectedNetwork()
        if let hub = mapFocusCoordinate ?? lastFetchAnchor {
            return hub
        }
        applyDefaultLondonNetwork()
        return mapFocusCoordinate
    }

    func onAppear() {
        Task { await refreshFavoriteKeys() }
    }

    func refresh() {
        Task {
            await loadAllStationsForSelectedNetwork(forceRefresh: false)
        }
    }

    /// Ensures `userLocation` is populated when the user requests a walking route.
    @discardableResult
    func ensureDeviceLocation() async -> Bool {
        if userLocation != nil { return true }
        return await resolveDeviceLocation()
    }

    /// Updates map pins from SwiftData / memory for the visible map rect. Does **not** hit the network.
    /// Centers map annotations on a user-selected station (list, search, or map pin).
    func prepareMapForStationSelection(_ station: MobilityStation) {
        mapHighlightStation = station
        let region = MapManager.filterRegion(around: station.coordinate)
        visibleMapRegion = region
        mapStations = mergingMapHighlight(into: mapStationsForRegion(region))
    }

    func clearMapStationSelection() {
        mapHighlightStation = nil
    }

    func refreshCityWeather() {
        cityWeatherTask?.cancel()
        guard let coord = walkingRouteOrigin else {
            cityWeather = nil
            isLoadingCityWeather = false
            return
        }
        let requestAnchor = coord
        cityWeather = nil
        isLoadingCityWeather = true

        cityWeatherTask = Task {
            defer {
                if !Task.isCancelled {
                    isLoadingCityWeather = false
                }
            }
            do {
                let snapshot = try await dependencies.weatherProvider.currentWeather(
                    latitude: requestAnchor.latitude,
                    longitude: requestAnchor.longitude
                )
                guard !Task.isCancelled else { return }
                guard isSameCoordinate(walkingRouteOrigin, requestAnchor) else { return }
                cityWeather = snapshot
            } catch {
                guard !Task.isCancelled else { return }
                guard isSameCoordinate(walkingRouteOrigin, requestAnchor) else { return }
                cityWeather = nil
            }
        }
    }

    private func isSameCoordinate(
        _ lhs: CLLocationCoordinate2D?,
        _ rhs: CLLocationCoordinate2D
    ) -> Bool {
        guard let lhs else { return false }
        let epsilon = 0.0001
        return abs(lhs.latitude - rhs.latitude) < epsilon
            && abs(lhs.longitude - rhs.longitude) < epsilon
    }

    func updateVisibleMapRegion(_ region: MKCoordinateRegion) {
        mapViewportUpdateGeneration += 1
        let generation = mapViewportUpdateGeneration
        mapViewportUpdateTask?.cancel()
        mapViewportUpdateTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, generation == mapViewportUpdateGeneration else { return }
            await applyVisibleMapRegion(region)
        }
    }

    private func applyVisibleMapRegion(_ region: MKCoordinateRegion) async {
        if shouldIgnoreSpuriousCameraRegion(region, previous: visibleMapRegion) {
            return
        }

        visibleMapRegion = region

        if !stations.isEmpty {
            updateMapStations(for: region)
            return
        }

        let networkId = selectedNetworkId
        let bounds = GeoUtilities.bounds(for: region, paddingFactor: MapManager.mapPinQueryPaddingFactor)
        let inRegion = await dependencies.cache.stationsInRegion(networkId: networkId, bounds: bounds)
        guard !Task.isCancelled else { return }
        mapStations = mergingMapHighlight(into: MapManager.stationsInVisibleRegion(region, from: inRegion))
    }

    /// Ignores one-shot camera jumps from sheet layout (non-overlapping, far from the last viewport).
    private func shouldIgnoreSpuriousCameraRegion(
        _ region: MKCoordinateRegion,
        previous: MKCoordinateRegion?
    ) -> Bool {
        guard let previous else { return false }
        let jumpMeters = GeoUtilities.distanceMeters(from: previous.center, to: region.center)
        guard jumpMeters > MapManager.Metrics.filterRadiusMeters * 3 else { return false }
        return !GeoUtilities.regionsOverlap(previous, region)
    }

    /// Re-apply pins around the city hub after sheet transitions that confuse the map camera.
    func restoreMapStationsForMapFocus() {
        publishMapStationsAroundFocus()
    }

    func loadNetworks(forceRefresh: Bool = false) async {
        await loadNetworksFromCacheIfNeeded()
        do {
            try await fetchAndCacheAllNetworks(forceRefresh: forceRefresh)
        } catch {
        }
    }

    private func loadNetworksFromCacheIfNeeded() async {
        guard !networksLoaded else { return }
        if let cached = await dependencies.cache.cachedNetworks() {
            networks = cached.networks
            networksLoaded = true
        }
    }

    private func applyCachedStationsIfAvailable() async {
        guard let entry = await dependencies.cache.cachedStations(networkId: selectedNetworkId) else {
            return
        }
        guard !entry.stations.isEmpty else { return }

        apply(
            StationFetchResult(
                stations: entry.stations,
                source: .cache,
                fetchedAt: entry.fetchedAt,
                isStale: true
            )
        )
    }

    func selectNetwork(_ id: String) {
        let network = networks.first { $0.id == id }
            ?? dependencies.localNetworks.network(id: id)
        guard let network else { return }
        selectCity(network)
    }

    func toggleFavoriteNetwork(_ networkId: String) async {
        guard let repo = dependencies.favoriteNetworksRepository else { return }
        do {
            try await repo.toggleFavorite(networkId: networkId)
            await refreshFavoriteNetworkIds()
            networks = networks.map { net in
                net.markingFavorite(favoriteNetworkIds.contains(net.id))
            }
            if selectedNetworkId == networkId, let network = networks.first(where: { $0.id == networkId }) {
                applyNetworkLabels(network)
            }
        } catch {
        }
    }

    func requestLocationAccess() {
        Task { await dependencies.locationService.requestAuthorization() }
    }

    func refreshFavoriteKeys() async {
        guard let repo = dependencies.favoritesRepository else { return }
        favoriteKeys = await repo.favoriteIDs()
    }

    func refreshFavoriteNetworkIds() async {
        guard let repo = dependencies.favoriteNetworksRepository else { return }
        favoriteNetworkIds = await repo.favoriteNetworkIDs()
        networks = networks.map { $0.markingFavorite(favoriteNetworkIds.contains($0.id)) }
    }

    func isFavorite(_ station: MobilityStation) -> Bool {
        favoriteKeys.contains(station.favoriteKey)
    }

    @discardableResult
    func toggleFavorite(_ station: MobilityStation) async -> Bool {
        guard let repo = dependencies.favoritesRepository else { return false }

        let key = station.favoriteKey
        let wasFavorite = favoriteKeys.contains(key)
        if wasFavorite {
            favoriteKeys.remove(key)
        } else {
            favoriteKeys.insert(key)
        }

        do {
            try await repo.toggleFavorite(station)
            return true
        } catch {
            if wasFavorite {
                favoriteKeys.insert(key)
            } else {
                favoriteKeys.remove(key)
            }
            FavoriteHUD.showSaveFailed(wasAdding: !wasFavorite)
            return false
        }
    }

    /// Straight-line distance from the location anchor (city hub or GPS when Current location).
    func distanceMeters(for station: MobilityStation) -> CLLocationDistance? {
        guard let anchor = walkingRouteOrigin else { return nil }
        return station.straightLineDistanceMeters(to: anchor)
    }

    func recommendationScore(for station: MobilityStation) -> Double {
        station.recommendationScore ?? 0
    }

    // MARK: - Private

    /// Device GPS — only call when **Current location** is selected or walking directions need the user.
    private func resolveDeviceLocation() async -> Bool {
        if dependencies.locationService.authorizationStatus == .notDetermined {
            await dependencies.locationService.requestAuthorization()
        }
        guard dependencies.locationService.authorizationStatus == .authorized else {
            userLocation = nil
            return false
        }
        do {
            let location = try await dependencies.locationService.currentLocation()
            userLocation = location
            return true
        } catch {
            userLocation = nil
            return false
        }
    }

    private func applyPersistedOrDefaultCity() async {
        switch dependencies.selectedCityStore.selectionMode {
        case .currentLocation:
            await applyCurrentLocationAnchor()
        case .network(let id):
            applySavedNetwork(id: id)
        case nil:
            applyDefaultLondonNetwork()
        }
    }

    private func applyDefaultLondonNetwork() {
        guard let network = londonDefaultNetwork() else {
            selectedNetworkId = APIConfiguration.defaultNetworkId
            currentCityName = "London"
            currentNetworkName = ""
            locationSubtitle = currentCityName
            return
        }
        applyNetworkLabels(network)
        selectedNetworkId = network.id
        adoptCityAnchor(for: network)
    }

    private func applySavedNetwork(id: String) {
        if let network = dependencies.localNetworks.network(id: id)
            ?? networks.first(where: { $0.id == id }) {
            applyNetworkLabels(network)
            selectedNetworkId = network.id
            adoptCityAnchor(for: network)
        } else {
            applyDefaultLondonNetwork()
        }
    }

    private func applyCurrentLocationAnchor() async {
        guard await resolveDeviceLocation(), let user = userLocation else {
            applyDefaultLondonNetwork()
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        mapFocusCoordinate = coordinate
        lastFetchAnchor = coordinate
        mapFocusRevision = UUID()
        selectNetwork(near: coordinate, persistCityChoice: false)
        await updateCityNameFromDeviceLocation(coordinate)
    }

    private func updateCityNameFromDeviceLocation(_ coordinate: CLLocationCoordinate2D) async {
        let network = networks.first(where: { $0.id == selectedNetworkId })
            ?? dependencies.localNetworks.network(id: selectedNetworkId)

        if let resolved = await CityNameResolver.resolveCityName(for: coordinate) {
            currentCityName = resolved
        } else if let network {
            currentCityName = network.cityTitle
        } else {
            currentCityName = String(localized: "Unknown")
        }

        if let network {
            currentNetworkName = network.name
            locationSubtitle = network.displayName
        }
    }

    private func londonDefaultNetwork() -> MobilityNetwork? {
        dependencies.localNetworks.network(id: APIConfiguration.defaultNetworkId)
            ?? networks.first { $0.id == APIConfiguration.defaultNetworkId }
    }

    private func loadBundledLondonIfNeeded() async {
        guard stations.isEmpty else { return }
        guard selectedNetworkId == APIConfiguration.defaultNetworkId else { return }
        guard !dependencies.selectedCityStore.hasExplicitSelection else { return }
        guard let bundled = try? LocalBundledStationProvider() else { return }
        guard let result = try? await bundled.fetchStations(
            networkId: APIConfiguration.defaultNetworkId,
            forceRefresh: false,
            query: nil
        ), !result.stations.isEmpty else { return }
        apply(result)
    }

    private func applyCitySelectionImmediately(_ network: MobilityNetwork) {
        loadTask?.cancel()
        cityWeatherTask?.cancel()
        cityWeather = nil
        isLoadingCityWeather = true
        selectedNetworkId = network.id
        applyNetworkLabels(network)
        dependencies.selectedCityStore.save(networkId: network.id)
        adoptCityAnchor(for: network)
        stations = []
        mapStations = []
        visibleMapRegion = nil
        if loadState != .idle {
            loadState = .loading
        }
    }

    private func refreshCatalogAndStationsFromNetwork() async {
        do {
            try await fetchAndCacheAllNetworks(forceRefresh: false)
        } catch {
            if !networksLoaded { await loadNetworksFromCacheIfNeeded() }
        }
        await refreshStationsFromNetwork()
    }

    private func refreshStationsFromNetwork() async {
        let networkId = selectedNetworkId
        await loadAllStationsForSelectedNetwork(forceRefresh: true)
        sessionFetchedNetworkIds.insert(networkId)
        refreshMapStationsForCurrentViewport()
    }

    private func refreshMapStationsForCurrentViewport() {
        publishMapStationsAroundFocus()
    }

    /// Pins for the current map viewport, or the default focus region before the user pans.
    private func publishMapStationsAroundFocus() {
        if let region = visibleMapRegion, !stations.isEmpty {
            updateMapStations(for: region, retainExistingPins: false)
            return
        }
        guard let center = mapFocusCoordinate ?? lastFetchAnchor else {
            mapStations = []
            return
        }
        let region = MapManager.filterRegion(around: center)
        visibleMapRegion = region
        updateMapStations(for: region, retainExistingPins: false)
    }

    private func coordinate(for network: MobilityNetwork) -> CLLocationCoordinate2D? {
        guard let lat = network.latitude, let lon = network.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func adoptCityAnchorForSelectedNetwork() {
        let network = networks.first { $0.id == selectedNetworkId }
            ?? dependencies.localNetworks.network(id: selectedNetworkId)
        if let network {
            adoptCityAnchor(for: network)
        } else if let anchor = lastFetchAnchor {
            mapFocusCoordinate = anchor
            mapFocusRevision = UUID()
        }
    }

    private func adoptCityAnchor(for network: MobilityNetwork) {
        guard let coord = coordinate(for: network) else { return }
        lastFetchAnchor = coord
        mapFocusCoordinate = coord
        mapFocusRevision = UUID()
    }

    private func fetchAndCacheAllNetworks(forceRefresh: Bool) async throws {
        let list = try await dependencies.stationProvider.fetchNetworks(forceRefresh: forceRefresh)
        networks = list.map { $0.markingFavorite(favoriteNetworkIds.contains($0.id)) }
        networksLoaded = true
    }

    private func selectNetwork(near center: CLLocationCoordinate2D, persistCityChoice: Bool = true) {
        guard !networks.isEmpty else {
            selectedNetworkId = APIConfiguration.defaultNetworkId
            if persistCityChoice {
                currentCityName = String(localized: "Unknown")
                currentNetworkName = ""
                locationSubtitle = currentCityName
            }
            return
        }

        let candidates = networks.filter {
            GeoUtilities.networkDistance($0, to: center) <= APIConfiguration.networkMatchMaxDistanceMeters
        }
        let pool = candidates.isEmpty ? networks : candidates
        guard let nearest = GeoUtilities.nearestNetwork(to: center, from: pool) else {
            selectedNetworkId = networks[0].id
            applyNetworkLabels(networks[0])
            if persistCityChoice {
                dependencies.selectedCityStore.save(networkId: networks[0].id)
            }
            return
        }

        selectedNetworkId = nearest.id
        applyNetworkLabels(nearest)
        if persistCityChoice {
            dependencies.selectedCityStore.save(networkId: nearest.id)
        }
    }

    private func applyNetworkLabels(_ network: MobilityNetwork) {
        currentCityName = network.cityTitle
        currentNetworkName = network.name
        locationSubtitle = network.displayName
    }

    private func hasCachedStations(for networkId: String) async -> Bool {
        await dependencies.cache.hasPersistedStations(networkId: networkId)
    }

    private func loadAllStationsForSelectedNetwork(forceRefresh: Bool) async {
        await fetchStations(query: nil, forceRefresh: forceRefresh)
    }

    private func fetchStations(query: StationSearchQuery?, forceRefresh: Bool) async {
        loadTask?.cancel()
        loadTask = Task {
            if stations.isEmpty { loadState = .loading }
            do {
                try Task.checkCancellation()
                let result = try await dependencies.stationProvider.fetchStations(
                    networkId: selectedNetworkId,
                    forceRefresh: forceRefresh,
                    query: query
                )
                try Task.checkCancellation()
                apply(result)
            } catch is CancellationError {
                return
            } catch {
                if stations.isEmpty {
                    loadState = .error(error.localizedDescription)
                } else {
                    loadState = .loaded
                    isStale = true
                }
            }
        }
        await loadTask?.value
    }

    private func apply(_ result: StationFetchResult) {
        let loaded = prepareStationsWithPersistedScores(result.stations, source: result.source)
        stations = loaded
        dataSource = result.source
        isStale = result.isStale
        lastFetchedAt = result.fetchedAt
        loadState = stations.isEmpty ? .empty : .loaded
        if loaded != result.stations || result.source == .live {
            Task {
                await dependencies.cache.store(
                    stations: loaded,
                    networkId: selectedNetworkId,
                    fetchedAt: result.fetchedAt
                )
            }
        }
        publishMapStationsAroundFocus()
    }

    /// Assigns scores on live network data; reuses stored scores from cache otherwise.
    private func prepareStationsWithPersistedScores(
        _ incoming: [MobilityStation],
        source: DataSourceKind
    ) -> [MobilityStation] {
        switch source {
        case .live:
            return assignRecommendationScores(to: incoming)
        case .cache, .bundled:
            guard incoming.contains(where: { $0.recommendationScore == nil }) else { return incoming }
            return assignRecommendationScores(to: incoming)
        }
    }

    private func assignRecommendationScores(to stations: [MobilityStation]) -> [MobilityStation] {
        let anchor = scoreAnchorLocation()
        return stations.map { station in
            let score = dependencies.recommendationEngine.score(
                StationRecommendationEngine.ScoreInput(
                    station: station,
                    userLocation: anchor
                )
            )
            return station.withRecommendationScore(score)
        }
    }

    private func scoreAnchorLocation() -> CLLocationSnapshot? {
        if usesCurrentLocationSelection, let user = userLocation {
            return user
        }
        if let hub = cityHubCoordinate {
            return CLLocationSnapshot(
                latitude: hub.latitude,
                longitude: hub.longitude,
                horizontalAccuracy: 0,
                timestamp: Date()
            )
        }
        return nil
    }

    private func updateMapStations(for region: MKCoordinateRegion, retainExistingPins: Bool = true) {
        let visible = mapStationsForRegion(region)
        let merged: [MobilityStation]
        if retainExistingPins, !mapStations.isEmpty {
            let retainBounds = GeoUtilities.bounds(for: region, paddingFactor: 1.35)
            let retained = mapStations.filter { station in
                !GeoUtilities.filter([station], in: retainBounds).isEmpty
            }
            var keys = Set(retained.map(\.favoriteKey))
            merged = retained + visible.filter { !keys.contains($0.favoriteKey) }
        } else {
            merged = visible
        }
        mapStations = mergingMapHighlight(into: merged)
    }

    /// When a sheet shifts the reported camera, fall back to pins around the map focus instead of clearing.
    private func visibleIfEmptyUseFocus(_ visible: [MobilityStation]) -> [MobilityStation] {
        guard visible.isEmpty, !stations.isEmpty, let anchor = mapFocusCoordinate ?? lastFetchAnchor else {
            return visible
        }
        return mapStationsForRegion(MapManager.filterRegion(around: anchor))
    }

    private func mapStationsForRegion(_ region: MKCoordinateRegion) -> [MobilityStation] {
        MapManager.stationsInVisibleRegion(region, from: stations)
    }

    private func mergingMapHighlight(into stations: [MobilityStation]) -> [MobilityStation] {
        guard let highlight = mapHighlightStation else { return stations }
        if stations.contains(where: { $0.favoriteKey == highlight.favoriteKey }) {
            return stations
        }
        var merged = stations
        merged.insert(highlight, at: 0)
        return merged
    }

    private func sorted(_ stations: [MobilityStation]) -> [MobilityStation] {
        switch sortOption {
        case .mostBikes:
            return stations.sorted { ($0.freeBikes ?? 0) > ($1.freeBikes ?? 0) }
        case .nearest:
            guard let anchor = cityHubCoordinate else { return stations }
            return stations.sorted {
                $0.straightLineDistanceMeters(to: anchor) < $1.straightLineDistanceMeters(to: anchor)
            }
        case .topRated:
            return stations.sorted {
                ($0.recommendationScore ?? 0) > ($1.recommendationScore ?? 0)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
extension StationListViewModel {
  static func preview(
    stations: [MobilityStation] = PreviewData.stations,
    networks: [MobilityNetwork] = PreviewData.networks,
    loadState: LoadState = .loaded,
    locationSubtitle: String = "Santander Cycles · London",
    userLocation: CLLocationSnapshot? = PreviewData.userLocation,
    dataSource: DataSourceKind = .live,
    isStale: Bool = false,
    favoriteKeys: Set<String> = ["santander-cycles|preview-station-1"]
  ) -> StationListViewModel {
    let viewModel = StationListViewModel(dependencies: AppDependencies.previewForCanvas())
    viewModel.stations = stations
    viewModel.mapStations = stations
    viewModel.networks = networks
    viewModel.loadState = loadState
    viewModel.locationSubtitle = locationSubtitle
    viewModel.currentCityName = "London"
    viewModel.currentNetworkName = "Santander Cycles"
    viewModel.cityWeather = WeatherSnapshot(
      temperatureCelsius: 18,
      windSpeedKmh: 12,
      weatherCode: 2,
      fetchedAt: Date()
    )
    viewModel.userLocation = userLocation
    viewModel.dataSource = dataSource
    viewModel.isStale = isStale
    viewModel.favoriteKeys = favoriteKeys
    viewModel.hasBootstrapped = true
    return viewModel
  }

  /// For `#Preview` macros (nonisolated canvas context).
  nonisolated static func previewForCanvas(
    stations: [MobilityStation]? = nil,
    networks: [MobilityNetwork]? = nil,
    loadState: LoadState = .loaded,
    locationSubtitle: String = "Santander Cycles · London",
    userLocation: CLLocationSnapshot? = nil,
    dataSource: DataSourceKind = .live,
    isStale: Bool = false,
    favoriteKeys: Set<String>? = nil
  ) -> StationListViewModel {
    MainActor.assumeIsolated {
      preview(
        stations: stations ?? PreviewData.stations,
        networks: networks ?? PreviewData.networks,
        loadState: loadState,
        locationSubtitle: locationSubtitle,
        userLocation: userLocation ?? PreviewData.userLocation,
        dataSource: dataSource,
        isStale: isStale,
        favoriteKeys: favoriteKeys ?? ["santander-cycles|preview-station-1"]
      )
    }
  }
}
#endif
