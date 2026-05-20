//
//  CityBikesDTOTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer
import UrbanMobilityNetworking

final class CityBikesOpenAPIMappingTests: XCTestCase {
    func testStationDTOMapping() throws {
        let json = """
        {
          "id": "station-1",
          "name": "Hyde Park",
          "latitude": 51.5,
          "longitude": -0.15,
          "free_bikes": 3,
          "empty_slots": 7,
          "timestamp": "2026-05-18T10:00:00Z",
          "extra": { "slots": 10, "address": "Hyde Park" }
        }
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(CityBikeStation.self, from: json)
        let station = dto.toDomain(networkId: "santander-cycles")
        XCTAssertEqual(station.id, "station-1")
        XCTAssertEqual(station.freeBikes, 3)
        XCTAssertEqual(station.emptySlots, 7)
        XCTAssertEqual(station.address, "Hyde Park")
        XCTAssertNil(station.renting)
        XCTAssertNil(station.returning)
    }

    func testStationDTOMapsExtraRentingReturning() throws {
        let json = """
        {
          "id": "000db9b6e3849926d4868caf7096780d",
          "name": "Calumet Ave & 21st St",
          "latitude": 41.85418424947,
          "longitude": -87.6191537415,
          "free_bikes": 13,
          "empty_slots": 1,
          "extra": {
            "uid": "a3ac8dfb-a135-11e9-9cda-0a87ae2ba916",
            "renting": 1,
            "returning": 1,
            "ebikes": 1,
            "slots": 15,
            "rental_uris": {
              "ios": "https://chi.lft.to/lastmile_qr_scan"
            }
          }
        }
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(CityBikeStation.self, from: json)
        let station = dto.toDomain(networkId: "motion")
        XCTAssertEqual(station.renting, true)
        XCTAssertEqual(station.returning, true)
        XCTAssertEqual(station.ebikes, 1)
        XCTAssertEqual(station.rentalURL?.absoluteString, "https://chi.lft.to/lastmile_qr_scan")
    }

    func testCallABikeBerlinRentingReturningBoolDecodes() throws {
        let json = """
        {
          "network": {
            "stations": [
              {
                "id": "002040cdaccb62d2a49a4525bfbf5975",
                "name": "Schleidenplatz / Waldeyerstraße",
                "latitude": 52.51483917236328,
                "longitude": 13.473699569702148,
                "timestamp": "2026-05-19T09:23:58.188049+00:00Z",
                "free_bikes": 2,
                "empty_slots": 38,
                "extra": {
                  "uid": "e93e4c86-40fa-3c8d-90d8-d7403dc8e05a",
                  "renting": true,
                  "returning": true,
                  "slots": 40,
                  "rental_uris": {
                    "android": "https://www.callabike.de/app",
                    "ios": "https://www.callabike.de/app"
                  },
                  "virtual": false
                }
              }
            ]
          }
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(CityBikeNetworkDetailResponse.self, from: json)
        let stations = (response.network.stations ?? []).map { $0.toDomain(networkId: "callabike-berlin") }
        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(stations[0].renting, true)
        XCTAssertEqual(stations[0].returning, true)
        XCTAssertEqual(stations[0].rentalURL?.absoluteString, "https://www.callabike.de/app")
    }

    func testBerlinNetworkDetailDecodesFromLiveShape() throws {
        let json = """
        {
          "network": {
            "stations": [
              {
                "id": "14082f376a65474ec279dc0d7f7d37a5",
                "name": "S Springpfuhl",
                "latitude": 52.527694,
                "longitude": 13.537889,
                "timestamp": "2026-05-19T05:48:28.175940+00:00Z",
                "free_bikes": 0,
                "empty_slots": 4,
                "extra": {
                  "uid": "107426897",
                  "number": "1564",
                  "slots": 4,
                  "bike_uids": [],
                  "virtual": true
                }
              }
            ]
          }
        }
        """.data(using: .utf8)!
        let stations = CityBikesStationDecoder.decodeStations(from: json, networkId: "nextbike-berlin")
        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(stations[0].name, "S Springpfuhl")
    }

    func testLondonSantanderStationExtraUIDAsIntDecodesViaDTO() throws {
        let json = """
        {
          "network": {
            "stations": [
              {
                "id": "001420f03e8b4f08f1bcc9bdc0260651",
                "name": "300073 - Prince of Wales Drive, Battersea Park",
                "latitude": 51.47515398,
                "longitude": -0.159169801,
                "free_bikes": 10,
                "empty_slots": 10,
                "extra": {
                  "uid": 756,
                  "name": "Prince of Wales Drive, Battersea Park",
                  "terminalName": "300073",
                  "locked": false,
                  "installed": true
                }
              }
            ]
          }
        }
        """.data(using: .utf8)!
        let stations = CityBikesStationDecoder.decodeStations(from: json, networkId: "santander-cycles")
        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(stations[0].name, "300073 - Prince of Wales Drive, Battersea Park")
    }

    func testNetworkDetailDecodesFieldsStationsOnlyResponse() throws {
        let json = """
        {
          "network": {
            "stations": [
              {
                "id": "abc",
                "name": "Test Dock",
                "latitude": 51.5,
                "longitude": -0.12,
                "free_bikes": 2,
                "empty_slots": 5
              }
            ]
          }
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(CityBikeNetworkDetailResponse.self, from: json)
        XCTAssertNil(response.network.id)
        XCTAssertNil(response.network.name)
        let stations = response.network.stations ?? []
        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(stations[0].toDomain(networkId: "santander-cycles").name, "Test Dock")
    }
}
