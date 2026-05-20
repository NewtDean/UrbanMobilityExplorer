//
//  StarRatingDisplayTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class StarRatingDisplayTests: XCTestCase {
    func testFilledUnits() {
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 90), 4.5, accuracy: 0.001)
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 100), 5, accuracy: 0.001)
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 20), 1, accuracy: 0.001)
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 10), 0.5, accuracy: 0.001)
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 0), 0, accuracy: 0.001)
    }

    func testSymbolNamesForNinetyPoints() {
        let units = StarRatingDisplay.filledUnits(score: 90)
        XCTAssertEqual(StarRatingDisplay.symbolName(starIndex: 1, filledUnits: units), "star.fill")
        XCTAssertEqual(StarRatingDisplay.symbolName(starIndex: 4, filledUnits: units), "star.fill")
        XCTAssertEqual(StarRatingDisplay.symbolName(starIndex: 5, filledUnits: units), "star.leadinghalf.filled")
    }

    func testSymbolNamesForEightyTwoPoints() {
        let units = StarRatingDisplay.filledUnits(score: 82)
        XCTAssertEqual(StarRatingDisplay.symbolName(starIndex: 4, filledUnits: units), "star.fill")
        XCTAssertEqual(StarRatingDisplay.symbolName(starIndex: 5, filledUnits: units), "star")
    }

    func testClampsAboveMax() {
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: 150), 5, accuracy: 0.001)
    }

    func testClampsBelowZero() {
        XCTAssertEqual(StarRatingDisplay.filledUnits(score: -10), 0, accuracy: 0.001)
    }

    func testFormattedStarRating() {
        XCTAssertEqual(StarRatingDisplay.formattedStarRating(score: 90), "4.5")
        XCTAssertEqual(StarRatingDisplay.formattedStarRating(score: 82), "4.1")
        XCTAssertEqual(StarRatingDisplay.formattedStarRating(score: 85), "4.3")
    }
}
