//
//  StationCacheModelActorTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftData
import XCTest
@testable import UrbanMobilityExplorer

final class StationCacheModelActorTests: XCTestCase {
    private var container: ModelContainer!
    private var store: StationCacheModelActor!

    override func setUp() async throws {
        let schema = Schema([
            FavoriteStation.self,
            CachedStationRecord.self,
            CachedNetworkRecord.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = StationCacheModelActor(modelContainer: container)
    }

    func testPersistsAndLoadsStations() async throws {
        let fetchedAt = Date()
        let stations = [MobilityStation.fixture(id: "a"), MobilityStation.fixture(id: "b")]
        try await store.replaceStations(stations, networkId: "net", fetchedAt: fetchedAt)

        let loaded = try await store.loadStations(networkId: "net")
        XCTAssertEqual(loaded?.stations.count, 2)
        XCTAssertEqual(loaded?.stations.map(\.id).sorted(), ["a", "b"])
    }

    func testHydratesMemoryCacheActor() async throws {
        let cache = StationCacheActor()
        try await store.replaceStations([.fixture(id: "cached")], networkId: "net", fetchedAt: Date())
        await cache.hydrateFromPersistentStore(store)

        let entry = await cache.cachedStations(networkId: "net")
        XCTAssertEqual(entry?.stations.first?.id, "cached")
    }
}
