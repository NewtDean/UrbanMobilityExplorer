//
//  GeoUtilitiesTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import MapKit
import XCTest
@testable import UrbanMobilityExplorer

final class GeoUtilitiesTests: XCTestCase {
    func testFilterWithinRadius() {
        let center = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12)
        let near = MobilityStation.fixture(lat: 51.5005, lon: -0.1205)
        let far = MobilityStation.fixture(lat: 52.0, lon: 0.0)
        let result = GeoUtilities.filter([near, far], center: center, radiusMeters: 1000)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, near.id)
    }

    func testRegionsOverlapWhenAdjacent() {
        let a = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.40),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        let b = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.521, longitude: 13.401),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        XCTAssertTrue(GeoUtilities.regionsOverlap(a, b))
    }

    func testRegionsDoNotOverlapWhenFarApart() {
        let a = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.40),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        let b = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.50, longitude: -0.12),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        XCTAssertFalse(GeoUtilities.regionsOverlap(a, b))
    }

    func testNearestNetwork() {
        let networks = [
            MobilityNetwork(id: "a", name: "A", city: nil, country: nil, latitude: 51.5, longitude: -0.12),
            MobilityNetwork(id: "b", name: "B", city: nil, country: nil, latitude: 40.7, longitude: -74.0)
        ]
        let center = CLLocationCoordinate2D(latitude: 51.51, longitude: -0.11)
        XCTAssertEqual(GeoUtilities.nearestNetwork(to: center, from: networks)?.id, "a")
    }
}
