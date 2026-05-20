//
//  StationCacheActor.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

actor StationCacheActor {
    struct CacheEntry: Sendable {
        let stations: [MobilityStation]
        let fetchedAt: Date
    }

    private var stationsByNetwork: [String: CacheEntry] = [:]
    private var networks: [MobilityNetwork]?
    private var networksFetchedAt: Date?
    private var persistence: StationCacheModelActor?
    private var didHydrateFromDisk = false

    func cachedStations(networkId: String) -> CacheEntry? {
        stationsByNetwork[networkId]
    }

    /// Stations inside a map bounding box — memory cache first, then SwiftData (no network).
    func stationsInRegion(networkId: String, bounds: MapCoordinateBounds) async -> [MobilityStation] {
        if let entry = stationsByNetwork[networkId] {
            return GeoUtilities.filter(entry.stations, in: bounds)
        }
        guard let persistence else { return [] }
        do {
            return try await persistence.loadStations(
                networkId: networkId,
                minLatitude: bounds.minLatitude,
                maxLatitude: bounds.maxLatitude,
                minLongitude: bounds.minLongitude,
                maxLongitude: bounds.maxLongitude
            )
        } catch {
            return []
        }
    }

    func hasPersistedStations(networkId: String) async -> Bool {
        if let entry = stationsByNetwork[networkId], !entry.stations.isEmpty {
            return true
        }
        guard let persistence else { return false }
        return ((try? await persistence.loadStations(networkId: networkId))?.stations.isEmpty) == false
    }

    func store(stations: [MobilityStation], networkId: String, fetchedAt: Date = Date()) {
        guard !stations.isEmpty else {
            return
        }
        stationsByNetwork[networkId] = CacheEntry(stations: stations, fetchedAt: fetchedAt)
        persistStations(stations, networkId: networkId, fetchedAt: fetchedAt)
    }

    func cachedNetworks() -> (networks: [MobilityNetwork], fetchedAt: Date)? {
        guard let networks, let networksFetchedAt else { return nil }
        return (networks, networksFetchedAt)
    }

    func store(networks: [MobilityNetwork], fetchedAt: Date = Date()) {
        self.networks = networks
        networksFetchedAt = fetchedAt
        persistNetworks(networks, fetchedAt: fetchedAt)
    }

    func isFresh(fetchedAt: Date, ttl: TimeInterval = APIConfiguration.cacheTTL) -> Bool {
        Date().timeIntervalSince(fetchedAt) < ttl
    }

    func isStaleAcceptable(fetchedAt: Date, ttl: TimeInterval = APIConfiguration.staleTTL) -> Bool {
        Date().timeIntervalSince(fetchedAt) < ttl
    }

    func clear() {
        stationsByNetwork.removeAll()
        networks = nil
        networksFetchedAt = nil
    }

    /// Loads SwiftData cache into memory once per launch.
    func hydrateFromPersistentStore(_ store: StationCacheModelActor) async {
        guard !didHydrateFromDisk else { return }
        didHydrateFromDisk = true
        persistence = store

        do {
            if let loaded = try await store.loadNetworks() {
                networks = loaded.networks
                networksFetchedAt = loaded.fetchedAt
            }

            let networkIds = try await store.cachedStationNetworkIds()
            for networkId in networkIds {
                guard let entry = try await store.loadStations(networkId: networkId) else { continue }
                stationsByNetwork[networkId] = CacheEntry(stations: entry.stations, fetchedAt: entry.fetchedAt)
            }
        } catch {
        }
    }

    // MARK: - SwiftData write-through

    private func persistStations(
        _ stations: [MobilityStation],
        networkId: String,
        fetchedAt: Date
    ) {
        guard let persistence else { return }
        Task {
            do {
                try await persistence.replaceStations(stations, networkId: networkId, fetchedAt: fetchedAt)
            } catch {
            }
        }
    }

    private func persistNetworks(_ networks: [MobilityNetwork], fetchedAt: Date) {
        guard let persistence else { return }
        Task {
            do {
                try await persistence.replaceNetworks(networks, fetchedAt: fetchedAt)
            } catch {
            }
        }
    }
}
