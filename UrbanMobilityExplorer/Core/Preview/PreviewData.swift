//
//  PreviewData.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import Foundation

#if DEBUG
enum PreviewData: Sendable {
    nonisolated static let network = MobilityNetwork(
        id: "santander-cycles",
        name: "Santander Cycles",
        city: "London",
        country: "United Kingdom",
        latitude: 51.5074,
        longitude: -0.1278
    )

    nonisolated static let networks = [network]

    nonisolated static let station = MobilityStation(
        id: "preview-station-1",
        networkId: "santander-cycles",
        name: "42 - Waterloo Station",
        latitude: 51.5033,
        longitude: -0.1135,
        freeBikes: 12,
        emptySlots: 8,
        totalSlots: 24,
        lastUpdated: Date(),
        address: "Waterloo Rd, London SE1",
        renting: true,
        returning: true,
        ebikes: 1,
        rentalURL: URL(string: "https://example.com/rent"),
        recommendationScore: 82
    )

    nonisolated static let stationLowAvailability = MobilityStation(
        id: "preview-station-2",
        networkId: "santander-cycles",
        name: "Hyde Park Corner",
        latitude: 51.5027,
        longitude: -0.1529,
        freeBikes: 0,
        emptySlots: 15,
        totalSlots: 22,
        lastUpdated: Date(),
        address: "Hyde Park Corner, London",
        recommendationScore: 35
    )

    nonisolated static let stations = [station, stationLowAvailability]

    nonisolated static let userLocation = CLLocationSnapshot(
        latitude: 51.505,
        longitude: -0.120,
        horizontalAccuracy: 12,
        timestamp: Date()
    )
}
#endif
