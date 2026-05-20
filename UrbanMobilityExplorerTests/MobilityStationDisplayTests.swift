//
//  MobilityStationDisplayTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class MobilityStationDisplayTests: XCTestCase {
    func testParseTitleKeepsRemainderAfterFirstHyphenSeparator() {
        let parsed = MobilityStation.parseStationTitle("001192 - National Archives - Kew")
        XCTAssertEqual(parsed.code, "001192")
        XCTAssertEqual(parsed.displayName, "National Archives - Kew")
    }

    func testParseTitleUsesFirstEnDashSeparator() {
        let parsed = MobilityStation.parseStationTitle("001192 – National Archives - Kew")
        XCTAssertEqual(parsed.code, "001192")
        XCTAssertEqual(parsed.displayName, "National Archives - Kew")
    }

    func testParseTitleWithoutSeparatorUsesFullName() {
        let parsed = MobilityStation.parseStationTitle("Hyde Park Corner")
        XCTAssertNil(parsed.code)
        XCTAssertEqual(parsed.displayName, "Hyde Park Corner")
    }

    func testLocationDisplayNameMatchesParsedRemainder() {
        let station = MobilityStation.fixture(name: "42 - Waterloo - Station")
        XCTAssertEqual(station.stationCode, "42")
        XCTAssertEqual(station.locationDisplayName, "Waterloo - Station")
    }
}
