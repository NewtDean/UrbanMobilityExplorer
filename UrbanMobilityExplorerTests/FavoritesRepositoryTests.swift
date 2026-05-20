//
//  FavoritesRepositoryTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftData
import XCTest
@testable import UrbanMobilityExplorer

@MainActor
final class FavoritesRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: SwiftDataFavoritesRepository!

    override func setUp() async throws {
        let schema = Schema([FavoriteStation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repository = SwiftDataFavoritesRepository(modelContext: container.mainContext)
    }

    func testToggleFavoritePersists() async throws {
        let station = MobilityStation.fixture()
        XCTAssertFalse(await repository.isFavorite(stationId: station.id, networkId: station.networkId))
        try await repository.toggleFavorite(station)
        XCTAssertTrue(await repository.isFavorite(stationId: station.id, networkId: station.networkId))
        let favorites = try await repository.favoriteStations()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.name, station.name)
        try await repository.toggleFavorite(station)
        XCTAssertTrue((try await repository.favoriteStations()).isEmpty)
    }

    func testFavoritesSurviveWithoutNetworkData() async throws {
        let station = MobilityStation.fixture(name: "Offline Favorite")
        try await repository.toggleFavorite(station)
        let loaded = try await repository.favoriteStations()
        XCTAssertEqual(loaded.first?.name, "Offline Favorite")
        XCTAssertEqual(loaded.first?.latitude, station.latitude)
    }

    func testFavoriteOnlyOneStationWhenIDsDiffer() async throws {
        let first = MobilityStation(
            id: "11058fd9a19c1e3eb1be438a8fe78026",
            networkId: "divvy",
            name: "001192 - Ashland",
            latitude: 41.881,
            longitude: -87.663
        )
        let second = MobilityStation(
            id: "c4f2b8e0d1a24b6e9f0a1b2c3d4e5f6",
            networkId: "motion",
            name: "001153 - Clark",
            latitude: 41.892,
            longitude: -87.631
        )

        try await repository.toggleFavorite(first)

        XCTAssertTrue(await repository.isFavorite(stationId: first.id, networkId: first.networkId))
        XCTAssertFalse(await repository.isFavorite(stationId: second.id, networkId: second.networkId))

        let keys = await repository.favoriteIDs()
        XCTAssertEqual(keys, [first.favoriteKey])
    }
}
