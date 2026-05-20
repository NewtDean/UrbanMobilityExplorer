//
//  CachedStationDataProvider.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Decorator: live API with actor cache, stale fallback, and bundled last resort.
struct CachedStationDataProvider: StationDataProviding, Sendable {
    let live: StationDataProviding
    let bundled: StationDataProviding
    let cache: StationCacheActor

    init(
        live: StationDataProviding,
        bundled: StationDataProviding,
        cache: StationCacheActor = StationCacheActor()
    ) {
        self.live = live
        self.bundled = bundled
        self.cache = cache
    }

    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork] {
        if !forceRefresh,
           let cached = await cache.cachedNetworks(),
           await cache.isFresh(fetchedAt: cached.fetchedAt) {
            return cached.networks
        }
        do {
            let networks = try await live.fetchNetworks(forceRefresh: true)
            await cache.store(networks: networks)
            return networks
        } catch {
            if let cached = await cache.cachedNetworks(), await cache.isStaleAcceptable(fetchedAt: cached.fetchedAt) {
                return cached.networks
            }
            return try await bundled.fetchNetworks(forceRefresh: false)
        }
    }

    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult {
        if !forceRefresh,
           let entry = await cache.cachedStations(networkId: networkId),
           !entry.stations.isEmpty {
            return filteredResult(from: entry.stations, source: .cache, fetchedAt: entry.fetchedAt, isStale: false, query: query)
        }

        do {
            let result = try await live.fetchStations(networkId: networkId, forceRefresh: true, query: nil)
            if !result.stations.isEmpty {
                await cache.store(stations: result.stations, networkId: networkId, fetchedAt: result.fetchedAt)
            }
            return filteredResult(from: result.stations, source: result.source, fetchedAt: result.fetchedAt, isStale: result.isStale, query: query)
        } catch {
            if let entry = await cache.cachedStations(networkId: networkId),
               !entry.stations.isEmpty,
               await cache.isStaleAcceptable(fetchedAt: entry.fetchedAt) {
                return filteredResult(from: entry.stations, source: .cache, fetchedAt: entry.fetchedAt, isStale: true, query: query)
            }
            do {
                let bundledResult = try await bundled.fetchStations(networkId: networkId, forceRefresh: false, query: nil)
                guard !bundledResult.stations.isEmpty else {
                    throw error
                }
                await cache.store(stations: bundledResult.stations, networkId: networkId)
                return filteredResult(
                    from: bundledResult.stations,
                    source: .bundled,
                    fetchedAt: bundledResult.fetchedAt,
                    isStale: true,
                    query: query
                )
            } catch {
                throw error
            }
        }
    }

    private func filteredResult(
        from stations: [MobilityStation],
        source: DataSourceKind,
        fetchedAt: Date,
        isStale: Bool,
        query: StationSearchQuery?
    ) -> StationFetchResult {
        let filtered: [MobilityStation]
        if let query {
            filtered = GeoUtilities.filter(stations, center: query.center, radiusMeters: query.radiusMeters)
        } else {
            filtered = stations
        }
        return StationFetchResult(stations: filtered, source: source, fetchedAt: fetchedAt, isStale: isStale)
    }

    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation? {
        if let entry = await cache.cachedStations(networkId: networkId),
           let station = entry.stations.first(where: { $0.id == stationId }) {
            return station
        }
        return try await live.fetchStation(networkId: networkId, stationId: stationId)
    }
}
