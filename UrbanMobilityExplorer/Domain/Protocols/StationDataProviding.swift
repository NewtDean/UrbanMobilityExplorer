//
//  StationDataProviding.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

enum StationDataError: Error, LocalizedError, Sendable {
    case networkUnavailable
    case invalidResponse
    case notFound
    case cancelled
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            String(localized: "Network is unavailable. Showing cached data when possible.")
        case .invalidResponse:
            String(localized: "Could not read station data.")
        case .notFound:
            String(localized: "Station not found.")
        case .cancelled:
            String(localized: "Request was cancelled.")
        case .underlying(let error):
            error.localizedDescription
        }
    }
}

struct StationFetchResult: Sendable {
    let stations: [MobilityStation]
    let source: DataSourceKind
    let fetchedAt: Date
    let isStale: Bool
}

enum DataSourceKind: String, Sendable {
    case live
    case cache
    case bundled
}

protocol StationDataProviding: Sendable {
    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork]
    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult
    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation?
}

extension StationDataProviding {
    func fetchNetworks() async throws -> [MobilityNetwork] {
        try await fetchNetworks(forceRefresh: false)
    }

    func fetchStations(networkId: String, forceRefresh: Bool) async throws -> StationFetchResult {
        try await fetchStations(networkId: networkId, forceRefresh: forceRefresh, query: nil)
    }
}

protocol FavoritesRepositoryProtocol: Sendable {
    func isFavorite(stationId: String, networkId: String) async -> Bool
    func toggleFavorite(_ station: MobilityStation) async throws
    func favoriteStations() async throws -> [MobilityStation]
    func favoriteIDs() async -> Set<String>
}

protocol WeatherProviding: Sendable {
    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
}

protocol LocationProviding: Sendable {
    var authorizationStatus: LocationAuthorizationStatus { get }
    func requestAuthorization() async
    func currentLocation() async throws -> CLLocationSnapshot
}

struct WeatherSnapshot: Sendable, Equatable {
    let temperatureCelsius: Double
    let windSpeedKmh: Double
    let weatherCode: Int
    let fetchedAt: Date

    var summary: String {
        let temp = Int(temperatureCelsius.rounded())
        return String(localized: "\(temp)°C · \(WeatherSnapshot.conditionLabel(for: weatherCode))")
    }

    static func conditionLabel(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Variable"
        }
    }
}

struct CLLocationSnapshot: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let timestamp: Date
}

enum LocationAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized
    case restricted
}
