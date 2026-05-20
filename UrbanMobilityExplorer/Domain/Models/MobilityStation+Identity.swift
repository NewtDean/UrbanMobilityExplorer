//
//  MobilityStation+Identity.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

extension MobilityStation {
    /// Stable favorite / persistence key: `networkId` + CityBikes `id` (32-char hash).
    nonisolated var favoriteKey: String {
        Self.favoriteKey(networkId: networkId, stationId: id)
    }

    nonisolated static func favoriteKey(networkId: String, stationId: String) -> String {
        "\(networkId)|\(stationId)"
    }

    /// CityBikes exposes a unique station hash on the `id` field; fall back only when it is missing or too short.
    nonisolated static func resolveStationID(
        apiID: String,
        extraUID: String?,
        latitude: Double,
        longitude: Double
    ) -> String {
        let trimmedAPI = apiID.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAPI.count >= 16 {
            return trimmedAPI
        }

        let trimmedUID = extraUID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedUID.count >= 16 {
            return trimmedUID
        }

        if !trimmedAPI.isEmpty {
            return trimmedAPI
        }

        return String(format: "%.6f,%.6f", latitude, longitude)
    }
}
