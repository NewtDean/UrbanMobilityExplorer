//
//  StationRecommendationEngineTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class StationRecommendationEngineTests: XCTestCase {
    private let engine = StationRecommendationEngine()

    func testHigherAvailabilityScoresHigher() {
        let high = engine.score(.init(
            station: .fixture(bikes: 15, docks: 15),
            userLocation: nil
        ))
        let low = engine.score(.init(
            station: .fixture(bikes: 0, docks: 0),
            userLocation: nil
        ))
        XCTAssertGreaterThan(high, low)
    }

    func testScoreIsStableRegardlessOfFavoriteState() {
        let score = engine.score(.init(station: .fixture(), userLocation: nil))
        XCTAssertEqual(score, engine.score(.init(station: .fixture(), userLocation: nil)))
    }

    func testProximityIncreasesScore() {
        let near = engine.score(.init(
            station: .fixture(lat: 51.5001, lon: -0.1201),
            userLocation: CLLocationSnapshot(latitude: 51.5, longitude: -0.12, horizontalAccuracy: 5, timestamp: Date())
        ))
        let far = engine.score(.init(
            station: .fixture(lat: 52.0, lon: 0.5),
            userLocation: CLLocationSnapshot(latitude: 51.5, longitude: -0.12, horizontalAccuracy: 5, timestamp: Date())
        ))
        XCTAssertGreaterThan(near, far)
    }
}
