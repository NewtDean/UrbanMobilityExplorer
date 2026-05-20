//
//  CachedStationDataProviderTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class CachedStationDataProviderTests: XCTestCase {
    func testFallsBackToBundledWhenLiveFails() async throws {
        let live = MockStationProvider()
        live.shouldThrow = true
        let bundled = MockStationProvider()
        bundled.stations = [.fixture(id: "offline")]
        let provider = CachedStationDataProvider(live: live, bundled: bundled, cache: StationCacheActor())
        let result = try await provider.fetchStations(networkId: "net", forceRefresh: true, query: nil)
        XCTAssertEqual(result.stations.count, 1)
        XCTAssertEqual(result.source, .bundled)
        XCTAssertTrue(result.isStale)
    }

    func testReturnsCacheWhenLiveFailsAndCacheExists() async throws {
        let live = MockStationProvider()
        let bundled = MockStationProvider()
        let cache = StationCacheActor()
        await cache.store(stations: [.fixture(id: "cached")], networkId: "net", fetchedAt: Date().addingTimeInterval(-400))

        live.shouldThrow = true
        let provider = CachedStationDataProvider(live: live, bundled: bundled, cache: cache)
        let result = try await provider.fetchStations(networkId: "net", forceRefresh: true, query: nil)
        XCTAssertEqual(result.stations.first?.id, "cached")
        XCTAssertEqual(result.source, .cache)
        XCTAssertTrue(result.isStale)
    }
}
