//
//  CityBikesStationDecoder.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import UrbanMobilityNetworking

/// Decodes CityBikes `GET /networks/{id}?fields=stations` payloads (tolerant of per-station quirks).
enum CityBikesStationDecoder: Sendable {
    nonisolated static func decodeStations(from data: Data, networkId: String) -> [MobilityStation] {
        if let typed = decodeTypedResponse(from: data, networkId: networkId), !typed.isEmpty {
            return typed
        }

        return decodeLenientJSONObject(from: data, networkId: networkId)
    }

    private nonisolated static func decodeTypedResponse(
        from data: Data,
        networkId: String
    ) -> [MobilityStation]? {
        do {
            let response = try JSONDecoder().decode(CityBikeNetworkDetailResponse.self, from: data)
            let mapped = (response.network.stations ?? []).map { $0.toDomain(networkId: networkId) }
            return mapped
        } catch {
            return nil
        }
    }

  private nonisolated static func decodeLenientJSONObject(
        from data: Data,
        networkId: String
    ) -> [MobilityStation] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let network = root["network"] as? [String: Any],
            let rawStations = network["stations"] as? [[String: Any]]
        else {
            return []
        }

        var stations: [MobilityStation] = []
        stations.reserveCapacity(rawStations.count)

        for dict in rawStations {
            if let station = mobilityStation(from: dict, networkId: networkId) {
                stations.append(station)
            }
        }

        return stations
    }

    private nonisolated static func mobilityStation(
        from dict: [String: Any],
        networkId: String
    ) -> MobilityStation? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let latitude = dict["latitude"] as? Double,
            let longitude = dict["longitude"] as? Double
        else {
            return nil
        }

        let extra = dict["extra"] as? [String: Any]
        let stationID = MobilityStation.resolveStationID(
            apiID: id,
            extraUID: flexibleString(from: extra?["uid"]),
            latitude: latitude,
            longitude: longitude
        )

        return MobilityStation(
            id: stationID,
            networkId: networkId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            freeBikes: dict["free_bikes"] as? Int,
            emptySlots: dict["empty_slots"] as? Int,
            totalSlots: extra?["slots"] as? Int,
            lastUpdated: nil,
            address: extra?["address"] as? String,
            renting: serviceFlag(from: extra?["renting"]),
            returning: serviceFlag(from: extra?["returning"]),
            ebikes: extra?["ebikes"] as? Int,
            rentalURL: rentalURL(from: extra)
        )
    }

    private nonisolated static func flexibleString(from value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        default:
            return nil
        }
    }

    private nonisolated static func serviceFlag(from value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let int as Int:
            return int != 0
        case let double as Double:
            return double != 0
        default:
            return nil
        }
    }

    private nonisolated static func rentalURL(from extra: [String: Any]?) -> URL? {
        guard let uris = extra?["rental_uris"] as? [String: Any] else { return nil }
        if let ios = uris["ios"] as? String, let url = URL(string: ios) { return url }
        if let android = uris["android"] as? String, let url = URL(string: android) { return url }
        return nil
    }
}
