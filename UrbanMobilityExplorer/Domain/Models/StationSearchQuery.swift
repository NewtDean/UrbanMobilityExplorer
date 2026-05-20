//
//  StationSearchQuery.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit

/// Client-side geographic filter applied **after** fetching stations from CityBikes.
///
/// CityBikes station endpoint: `GET /v2/networks/{networkId}?fields=stations`
/// - **Required path param:** `networkId` (e.g. `santander-cycles`, `divvy`)
/// - **Optional query:** `fields` — comma-separated response filter (`stations`, `id`, `name`, …)
/// - **No** server-side text search, radius, or `q` parameter — name/address matching is done in-app.
struct StationSearchQuery: Sendable, Equatable {
    let centerLatitude: Double
    let centerLongitude: Double
    let radiusMeters: Double

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    nonisolated static func nearby(
        center: CLLocationCoordinate2D,
        radiusMeters: Double = APIConfiguration.defaultSearchRadiusMeters
    ) -> StationSearchQuery {
        StationSearchQuery(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            radiusMeters: radiusMeters
        )
    }

    nonisolated static func matching(region: MKCoordinateRegion) -> StationSearchQuery {
        let radius = max(
            region.span.latitudeDelta * 111_000 / 2,
            region.span.longitudeDelta * 111_000 * cos(region.center.latitude * .pi / 180) / 2
        )
        return StationSearchQuery(
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude,
            radiusMeters: min(max(radius, 200), APIConfiguration.maxSearchRadiusMeters)
        )
    }
}
