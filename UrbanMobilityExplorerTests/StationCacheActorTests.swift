//
//  StationCacheActorTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class StationCacheActorTests: XCTestCase {
    func testStoreAndRetrieveStations() async {
        let cache = StationCacheActor()
        let stations = [MobilityStation.fixture(id: "a"), MobilityStation.fixture(id: "b")]
        await cache.store(stations: stations, networkId: "net", fetchedAt: Date())
        let entry = await cache.cachedStations(networkId: "net")
        XCTAssertEqual(entry?.stations.count, 2)
    }

    func testFreshnessTTL() async {
        let cache = StationCacheActor()
        let old = Date().addingTimeInterval(-400)
        XCTAssertFalse(await cache.isFresh(fetchedAt: old, ttl: 300))
        XCTAssertTrue(await cache.isStaleAcceptable(fetchedAt: old, ttl: 3600))
    }
}
