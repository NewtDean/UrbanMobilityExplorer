//
//  StationRecommendationEngine.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import CoreLocation

/// Lightweight heuristic scoring — no external AI API.
struct StationRecommendationEngine: Sendable {
    struct ScoreInput: Sendable {
        let station: MobilityStation
        let userLocation: CLLocationSnapshot?
    }

  /// Heuristic 0–100 score from station inventory and distance to the city hub (or device).
    nonisolated func score(_ input: ScoreInput) -> Double {
        var total = 0.0
        total += input.station.availabilityScore * 40
        total += bikeDockBalanceScore(input.station) * 20

        if let location = input.userLocation {
            let meters = CLLocation(latitude: location.latitude, longitude: location.longitude)
                .distance(from: CLLocation(latitude: input.station.latitude, longitude: input.station.longitude))
            total += proximityScore(meters: meters) * 25
        } else {
            total += 10
        }

        return min(100, max(0, total))
    }

    nonisolated func sorted(_ stations: [MobilityStation], inputs: (MobilityStation) -> ScoreInput) -> [MobilityStation] {
        stations.sorted { score(inputs($0)) > score(inputs($1)) }
    }

    nonisolated private func bikeDockBalanceScore(_ station: MobilityStation) -> Double {
        let bikes = Double(station.freeBikes ?? 0)
        let docks = Double(station.emptySlots ?? 0)
        guard bikes > 0, docks > 0 else { return bikes > 0 || docks > 0 ? 0.3 : 0 }
        let ratio = min(bikes, docks) / max(bikes, docks)
        return ratio
    }

    nonisolated private func proximityScore(meters: CLLocationDistance) -> Double {
        switch meters {
        case ..<500: return 1.0
        case ..<1500: return 0.75
        case ..<3000: return 0.5
        case ..<8000: return 0.25
        default: return 0.1
        }
    }

}
