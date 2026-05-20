//
//  GeoUtilities.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import MapKit

struct MapCoordinateBounds: Sendable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
}

enum GeoUtilities: Sendable {
    nonisolated static func distanceMeters(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    nonisolated static func filter(
        _ stations: [MobilityStation],
        center: CLLocationCoordinate2D,
        radiusMeters: Double
    ) -> [MobilityStation] {
        stations.filter { station in
            distanceMeters(from: center, to: station.coordinate) <= radiusMeters
        }
    }

    nonisolated static func bounds(
        for region: MKCoordinateRegion,
        paddingFactor: Double = 1.05
    ) -> MapCoordinateBounds {
        let halfLat = region.span.latitudeDelta * paddingFactor / 2
        let halfLon = region.span.longitudeDelta * paddingFactor / 2
        return MapCoordinateBounds(
            minLatitude: region.center.latitude - halfLat,
            maxLatitude: region.center.latitude + halfLat,
            minLongitude: region.center.longitude - halfLon,
            maxLongitude: region.center.longitude + halfLon
        )
    }

    nonisolated static func filter(
        _ stations: [MobilityStation],
        in region: MKCoordinateRegion,
        paddingFactor: Double = 1.05
    ) -> [MobilityStation] {
        filter(stations, in: bounds(for: region, paddingFactor: paddingFactor))
    }

    nonisolated static func filter(
        _ stations: [MobilityStation],
        in bounds: MapCoordinateBounds
    ) -> [MobilityStation] {
        stations.filter { station in
            station.latitude >= bounds.minLatitude && station.latitude <= bounds.maxLatitude &&
            station.longitude >= bounds.minLongitude && station.longitude <= bounds.maxLongitude
        }
    }

    /// True when two map regions share any geographic overlap (used to ignore sheet layout camera glitches).
    nonisolated static func regionsOverlap(
        _ lhs: MKCoordinateRegion,
        _ rhs: MKCoordinateRegion,
        paddingFactor: Double = 1.0
    ) -> Bool {
        let a = bounds(for: lhs, paddingFactor: paddingFactor)
        let b = bounds(for: rhs, paddingFactor: paddingFactor)
        let latOverlap = a.minLatitude <= b.maxLatitude && a.maxLatitude >= b.minLatitude
        let lonOverlap = a.minLongitude <= b.maxLongitude && a.maxLongitude >= b.minLongitude
        return latOverlap && lonOverlap
    }

    nonisolated static func nearestNetwork(
        to coordinate: CLLocationCoordinate2D,
        from networks: [MobilityNetwork]
    ) -> MobilityNetwork? {
        networks.min { lhs, rhs in
            networkDistance(lhs, to: coordinate) < networkDistance(rhs, to: coordinate)
        }
    }

    nonisolated static func coordinate(
        _ coordinate: CLLocationCoordinate2D,
        offsetNorthMeters: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude + offsetNorthMeters / 111_000,
            longitude: coordinate.longitude
        )
    }

    nonisolated static func networkDistance(_ network: MobilityNetwork, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let lat = network.latitude, let lon = network.longitude else { return .greatestFiniteMagnitude }
        return distanceMeters(from: coordinate, to: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }

    /// ~1 km visible span for a street-level map.
    nonisolated static func region(
        center: CLLocationCoordinate2D,
        radiusMeters: Double = APIConfiguration.defaultSearchRadiusMeters
    ) -> MKCoordinateRegion {
        let delta = (radiusMeters * 2) / 111_000
        return region(
            framing: center,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta),
            mapSize: UIScreen.main.bounds.size,
            topInset: 0,
            bottomInset: 0
        )
    }

    /// Shifts the map center so `coordinate` appears in the middle of the unobstructed map area.
    nonisolated static func region(
        framing coordinate: CLLocationCoordinate2D,
        span: MKCoordinateSpan,
        mapSize: CGSize,
        topInset: CGFloat,
        bottomInset: CGFloat,
        additionalScreenOffsetY: CGFloat = 0
    ) -> MKCoordinateRegion {
        guard mapSize.height > 0, mapSize.width > 0 else {
            return MKCoordinateRegion(center: coordinate, span: span)
        }

        let visibleHeight = mapSize.height - topInset - bottomInset
        guard visibleHeight > 32 else {
            return MKCoordinateRegion(center: coordinate, span: span)
        }

        // Visible center sits above the screen center when a bottom sheet covers the map.
        // Negative `additionalScreenOffsetY` moves the target up on screen (detail / GPS tuning).
        let visibleCenterY = topInset + visibleHeight / 2 + additionalScreenOffsetY
        let screenCenterY = mapSize.height / 2
        let deltaY = visibleCenterY - screenCenterY
        let latitudeOffset = deltaY / mapSize.height * span.latitudeDelta

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude + latitudeOffset,
                longitude: coordinate.longitude
            ),
            span: span
        )
    }
}
