//
//  MobilityStationDetailDisplay.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import Foundation

/// View-model for `MobilityStationDetailPanelView` (mapped from domain station).
struct MobilityStationDetailDisplay: Equatable, Sendable {
    /// Original station title from the API.
    var name: String
    /// Dock number before the first ` - ` (or en-dash variant), when present.
    var stationCode: String?
    /// Full place name after that first separator (may contain additional ` - ` segments).
    var displayName: String
    var distance: String
    var connectionType: String
    var powerKW: String
    var ebikes: String
    var rentingText: String
    var isRentingAvailable: Bool
    var returningText: String
    var isReturningAvailable: Bool
}

extension MobilityStation {
    nonisolated func detailPanelDisplay(distanceMeters: CLLocationDistance? = nil) -> MobilityStationDetailDisplay {
        let distance = Self.formatDistance(distanceMeters)
        let bikes = freeBikes ?? 0
        let docks = emptySlots ?? 0
        let rentingState = Self.resolveAvailabilityFlag(apiFlag: renting, inventoryFallback: bikes > 0)
        let returningState = Self.resolveAvailabilityFlag(apiFlag: returning, inventoryFallback: docks > 0)

        let title = MobilityStation.parseStationTitle(name)

        return MobilityStationDetailDisplay(
            name: name,
            stationCode: title.code,
            displayName: title.displayName,
            distance: distance,
            connectionType: "Free bikes: \(bikes)",
            powerKW: "Empty slots: \(docks)",
            ebikes: ebikes.map { "\($0)" } ?? "—",
            rentingText: rentingState.text,
            isRentingAvailable: rentingState.isAvailable,
            returningText: returningState.text,
            isReturningAvailable: returningState.isAvailable
        )
    }

    nonisolated private static func formatDistance(_ meters: CLLocationDistance?) -> String {
        guard let meters else { return "—" }
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", meters / 1000)
    }

    /// Prefer API `extra.renting` / `extra.returning`; fall back to inventory only when API omits the flag.
    nonisolated private static func resolveAvailabilityFlag(
        apiFlag: Bool?,
        inventoryFallback: Bool
    ) -> (text: String, isAvailable: Bool) {
        if let apiFlag {
            return (apiFlag ? "Available" : "Unavailable", apiFlag)
        }
        return (inventoryFallback ? "Available" : "Unavailable", inventoryFallback)
    }
}

#if DEBUG
extension MobilityStationDetailDisplay {
    nonisolated static let preview = PreviewData.station.detailPanelDisplay(distanceMeters: 4_500)
}
#endif
