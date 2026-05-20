//
//  MobilityStationIdentityTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class MobilityStationIdentityTests: XCTestCase {
    func testResolveStationIDPrefersLongAPIHash() {
        let id = MobilityStation.resolveStationID(
            apiID: "11058fd9a19c1e3eb1be438a8fe78026",
            extraUID: "001192",
            latitude: 41.88,
            longitude: -87.63
        )
        XCTAssertEqual(id, "11058fd9a19c1e3eb1be438a8fe78026")
    }

    func testFavoriteKeysDifferForDifferentAPIIDs() {
        let a = MobilityStation(
            id: "11058fd9a19c1e3eb1be438a8fe78026",
            networkId: "divvy",
            name: "001192 - Station A",
            latitude: 41.88,
            longitude: -87.63
        )
        let b = MobilityStation(
            id: "a3ac8dfb-a135-11e9-9cda-0a87ae2ba916",
            networkId: "motion",
            name: "001153 - Station B",
            latitude: 41.89,
            longitude: -87.64
        )
        XCTAssertNotEqual(a.favoriteKey, b.favoriteKey)
    }
}
