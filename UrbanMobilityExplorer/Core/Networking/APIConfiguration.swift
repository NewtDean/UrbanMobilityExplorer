//
//  APIConfiguration.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Central API endpoints. CityBikes requires no API key; Open-Meteo is also keyless.
/// Marked `Sendable` + `nonisolated` for Swift 6 (project default isolation is MainActor).
enum APIConfiguration: Sendable {
    nonisolated static let cityBikesBaseURL = URL(string: "https://api.citybik.es/v2")!
    nonisolated static let openMeteoBaseURL = URL(string: "https://api.open-meteo.com/v1")!

    /// Default network for first launch (London Santander Cycles).
    nonisolated static let defaultNetworkId = "santander-cycles"

    nonisolated static let requestTimeout: TimeInterval = 20
    nonisolated static let cacheTTL: TimeInterval = 300
    nonisolated static let staleTTL: TimeInterval = 3600

    /// Default nearby search radius for list sorting hints (map uses full network + viewport filter).
    nonisolated static let defaultSearchRadiusMeters: Double = 2_000
    nonisolated static let maxSearchRadiusMeters: Double = 2_500
    /// Initial map zoom when framing the user / London (street-level overview).
    nonisolated static let defaultMapVisibleRadiusMeters: Double = 4_000
    /// Cap annotations on the walking map.
    nonisolated static let maxMapStationAnnotations = 80
    /// Max distance from user to a network hub to auto-select that network (~80 km).
    nonisolated static let networkMatchMaxDistanceMeters: Double = 80_000
}
