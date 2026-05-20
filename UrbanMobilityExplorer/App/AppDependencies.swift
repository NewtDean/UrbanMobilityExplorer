//
//  AppDependencies.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class AppDependencies: ObservableObject {
    let stationProvider: StationDataProviding
    let weatherProvider: WeatherProviding
    let locationService: LocationService
    let recommendationEngine: StationRecommendationEngine
    let cache: StationCacheActor
    let searchHistoryStore: SearchHistoryStore
    let localNetworks: LocalNetworksProvider
    let selectedCityStore: SelectedCityStore

    @Published var favoritesRepository: SwiftDataFavoritesRepository?
    @Published var favoriteNetworksRepository: SwiftDataFavoriteNetworksRepository?

    private var cacheHydrationTask: Task<Void, Never>?

    init(
        stationProvider: StationDataProviding? = nil,
        weatherProvider: WeatherProviding = OpenMeteoClient(),
        locationService: LocationService? = nil,
        recommendationEngine: StationRecommendationEngine = StationRecommendationEngine(),
        cache: StationCacheActor = StationCacheActor(),
        searchHistoryStore: SearchHistoryStore = SearchHistoryStore(),
        localNetworks: LocalNetworksProvider? = nil,
        selectedCityStore: SelectedCityStore = SelectedCityStore()
    ) {
        self.cache = cache
        self.weatherProvider = weatherProvider
        self.locationService = locationService ?? LocationService()
        self.recommendationEngine = recommendationEngine
        self.searchHistoryStore = searchHistoryStore
        self.selectedCityStore = selectedCityStore
        if let injected = localNetworks {
            self.localNetworks = injected
        } else if let loaded = try? LocalNetworksProvider() {
            self.localNetworks = loaded
        } else {
            self.localNetworks = LocalNetworksProvider(networks: [])
        }

        if let stationProvider {
            self.stationProvider = stationProvider
        } else {
            let live = CityBikesAPIClient()
            let bundled: StationDataProviding = (try? LocalBundledStationProvider()) ?? EmptyStationProvider()
            self.stationProvider = CachedStationDataProvider(live: live, bundled: bundled, cache: cache)
        }
    }

    func configure(modelContainer: ModelContainer) {
        let context = modelContainer.mainContext
        favoritesRepository = SwiftDataFavoritesRepository(modelContext: context)
        favoriteNetworksRepository = SwiftDataFavoriteNetworksRepository(modelContext: context)
        let cacheStore = StationCacheModelActor(modelContainer: modelContainer)
        let cache = cache
        cacheHydrationTask = Task.detached(priority: .utility) {
            await cache.hydrateFromPersistentStore(cacheStore)
        }
    }

    func prepareCacheIfNeeded() async {
        await cacheHydrationTask?.value
    }

    /// Use from `#Preview` and other nonisolated canvas contexts.
    nonisolated static func previewForCanvas() -> AppDependencies {
        MainActor.assumeIsolated { preview() }
    }

    @MainActor
    static func preview() -> AppDependencies {
        let bundled = try! LocalBundledStationProvider()
        return AppDependencies(stationProvider: bundled)
    }
}
