//
//  MockStationProvider.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
@testable import UrbanMobilityExplorer

final class MockStationProvider: StationDataProviding, @unchecked Sendable {
    var networks: [MobilityNetwork] = []
    var stations: [MobilityStation] = []
    var shouldThrow = false

    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork] {
        _ = forceRefresh
        if shouldThrow { throw StationDataError.networkUnavailable }
        return networks
    }

    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult {
        _ = networkId
        _ = forceRefresh
        if shouldThrow { throw StationDataError.networkUnavailable }
        let filtered: [MobilityStation]
        if let query {
            filtered = GeoUtilities.filter(stations, center: query.center, radiusMeters: query.radiusMeters)
        } else {
            filtered = stations
        }
        return StationFetchResult(stations: filtered, source: .live, fetchedAt: Date(), isStale: false)
    }

    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation? {
        stations.first { $0.id == stationId && $0.networkId == networkId }
    }
}

extension MobilityStation {
    static func fixture(
        id: String = "s1",
        networkId: String = "net",
        name: String = "Test Station",
        lat: Double = 51.5,
        lon: Double = -0.12,
        bikes: Int = 5,
        docks: Int = 10
    ) -> MobilityStation {
        MobilityStation(
            id: id,
            networkId: networkId,
            name: name,
            latitude: lat,
            longitude: lon,
            freeBikes: bikes,
            emptySlots: docks,
            totalSlots: bikes + docks,
            lastUpdated: Date(),
            address: "Test Address",
            renting: true,
            returning: docks > 0,
            ebikes: 0
        )
    }
}
