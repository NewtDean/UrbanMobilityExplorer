//
//  EmptyStationProvider.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

struct EmptyStationProvider: StationDataProviding, Sendable {
    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork] {
        _ = forceRefresh
        return []
    }
    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult {
        _ = networkId
        _ = forceRefresh
        _ = query
        return StationFetchResult(stations: [], source: .bundled, fetchedAt: Date(), isStale: true)
    }
    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation? { nil }
}
