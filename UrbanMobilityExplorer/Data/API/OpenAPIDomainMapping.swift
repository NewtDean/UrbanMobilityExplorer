//
//  OpenAPIDomainMapping.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import UrbanMobilityNetworking

extension CityBikeNetworkSummary {
    nonisolated func toDomain() -> MobilityNetwork {
        MobilityNetwork(
            id: id,
            name: name,
            city: location?.city,
            country: location?.country,
            latitude: location?.latitude,
            longitude: location?.longitude
        )
    }
}

extension CityBikeStation {
    nonisolated func toDomain(networkId: String) -> MobilityStation {
        let updated: Date? = {
            guard let timestamp else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: timestamp) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: timestamp)
        }()
        let stationID = MobilityStation.resolveStationID(
            apiID: id,
            extraUID: extra?.uid,
            latitude: latitude,
            longitude: longitude
        )
        return MobilityStation(
            id: stationID,
            networkId: networkId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            freeBikes: freeBikes,
            emptySlots: emptySlots,
            totalSlots: extra?.slots,
            lastUpdated: updated,
            address: extra?.address,
            renting: Self.serviceFlag(extra?.renting),
            returning: Self.serviceFlag(extra?.returning),
            ebikes: extra?.ebikes,
            rentalURL: extra?.rentalUris?.preferredURL
        )
    }

    nonisolated private static func serviceFlag(_ value: Int?) -> Bool? {
        switch value {
        case .none: return nil
        case .some(0): return false
        default: return true
        }
    }
}

extension CityBikeRentalURIs {
    nonisolated var preferredURL: URL? {
        if let ios, let url = URL(string: ios) { return url }
        if let android, let url = URL(string: android) { return url }
        return nil
    }
}

extension OpenMeteoForecastResponse {
    func toWeatherSnapshot(fetchedAt: Date = Date()) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: currentWeather.temperature,
            windSpeedKmh: currentWeather.windspeed,
            weatherCode: currentWeather.weathercode,
            fetchedAt: fetchedAt
        )
    }
}

