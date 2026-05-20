//
//  MapManager.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

// MARK: - Camera request

struct MapFocusRequest: Equatable {
    let region: MKCoordinateRegion
    let token: UUID

    static func == (lhs: MapFocusRequest, rhs: MapFocusRequest) -> Bool {
        lhs.token == rhs.token
    }
}

// MARK: - Map manager

/// Single place for discovery-map camera, zoom, insets, and region math.
@MainActor
final class MapManager: ObservableObject {
    enum Metrics {
        /// East–west geographic diameter (meters) — always used for map zoom.
        static let eastWestDiameterMeters: Double = 500
        /// North–south diameter (meters); kept equal for a consistent street-level square.
        static let northSouthDiameterMeters: Double = 500
        /// Radius for filtering stations around the map focus.
        static var filterRadiusMeters: Double { eastWestDiameterMeters / 2 }
        /// Extra screen-space Y offset applied on top of sheet-aware framing (negative = move target up).
        static let detailFocusScreenOffset: CGFloat = 88
        static let deviceLocationFocusScreenOffset: CGFloat = -88
        static let horizontalPadding: CGFloat = 20
    }

    @Published private(set) var focusRequest: MapFocusRequest?

    // MARK: - Camera

    /// Moves the map to a station (500 m). Use only for explicit station picks — not sheet layout changes.
    func focus(on coordinate: CLLocationCoordinate2D) {
        focusLikeStationDetail(on: coordinate)
    }

    /// Recenters on a city hub (sheet-aware framing, no extra vertical tweak).
    func recenter(on coordinate: CLLocationCoordinate2D) {
        applyFocus(on: coordinate, additionalScreenOffsetY: 0)
    }

    /// Station detail sheet — target aligned with the pin using `detailFocusScreenOffset`.
    func focusLikeStationDetail(on coordinate: CLLocationCoordinate2D) {
        applyFocus(on: coordinate, additionalScreenOffsetY: Metrics.detailFocusScreenOffset)
    }

    /// Location FAB / Current location — uses `deviceLocationFocusScreenOffset`.
    func focusDeviceLocation(on coordinate: CLLocationCoordinate2D) {
        applyFocus(on: coordinate, additionalScreenOffsetY: Metrics.deviceLocationFocusScreenOffset)
    }

    /// Region that places `coordinate` in the visible map area above the discovery sheet.
    func focusRegion(
        for coordinate: CLLocationCoordinate2D,
        additionalScreenOffsetY: CGFloat = 0
    ) -> MKCoordinateRegion {
        let span = streetLevelSpan(around: coordinate)
        let insets = focusEdgePadding
        return GeoUtilities.region(
            framing: coordinate,
            span: span,
            mapSize: UIScreen.main.bounds.size,
            topInset: insets.top,
            bottomInset: insets.bottom,
            additionalScreenOffsetY: additionalScreenOffsetY
        )
    }

    func cameraRegion(focus coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        focusRegion(for: coordinate)
    }

    private func applyFocus(on coordinate: CLLocationCoordinate2D, additionalScreenOffsetY: CGFloat) {
        focusRequest = MapFocusRequest(
            region: focusRegion(for: coordinate, additionalScreenOffsetY: additionalScreenOffsetY),
            token: UUID()
        )
    }

    private func streetLevelSpan(around coordinate: CLLocationCoordinate2D) -> MKCoordinateSpan {
        let latDelta = Metrics.northSouthDiameterMeters / 111_000
        let cosLat = max(0.2, cos(coordinate.latitude * .pi / 180))
        let lonDelta = Metrics.eastWestDiameterMeters / (111_000 * cosLat)
        return MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    }

    // MARK: - Insets

    var focusEdgePadding: UIEdgeInsets {
        UIEdgeInsets(
            top: MapBottomPanelMetrics.mapCameraTopPadding,
            left: Metrics.horizontalPadding,
            bottom: MapBottomPanelMetrics.minPanelHeight,
            right: Metrics.horizontalPadding
        )
    }

    func layoutEdgePadding(bottomObstruction: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(
            top: MapBottomPanelMetrics.mapCameraTopPadding,
            left: Metrics.horizontalPadding,
            bottom: bottomObstruction,
            right: Metrics.horizontalPadding
        )
    }

    // MARK: - Station filtering

    func regionForStationFilter(around center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        Self.filterRegion(around: center)
    }

    func clampVisibleRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        Self.clampVisibleRegion(region)
    }

    func stationsWithinFilterRadius(
        of center: CLLocationCoordinate2D,
        from stations: [MobilityStation],
        limit: Int = APIConfiguration.maxMapStationAnnotations
    ) -> [MobilityStation] {
        Self.stationsWithinFilterRadius(of: center, from: stations, limit: limit)
    }

    /// Stations whose coordinates lie inside the map's visible rectangle (no radial cap).
    func stationsInVisibleRegion(
        _ region: MKCoordinateRegion,
        from stations: [MobilityStation]
    ) -> [MobilityStation] {
        Self.stationsInVisibleRegion(region, from: stations)
    }

    static func filterRegion(around center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            latitudinalMeters: Metrics.northSouthDiameterMeters,
            longitudinalMeters: Metrics.eastWestDiameterMeters
        )
    }

    static func clampVisibleRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let maxDiameter = max(Metrics.eastWestDiameterMeters, Metrics.northSouthDiameterMeters)
        let latMeters = region.span.latitudeDelta * 111_000
        guard latMeters > maxDiameter * 1.15 else { return region }
        return filterRegion(around: region.center)
    }

    static func stationsWithinFilterRadius(
        of center: CLLocationCoordinate2D,
        from stations: [MobilityStation],
        limit: Int = APIConfiguration.maxMapStationAnnotations
    ) -> [MobilityStation] {
        Array(
            GeoUtilities.filter(stations, center: center, radiusMeters: Metrics.filterRadiusMeters)
                .prefix(limit)
        )
    }

    /// Geographic padding applied to the MapKit camera rect when querying pins.
    static let mapPinQueryPaddingFactor = 1.2

    /// All stations inside the camera bounding box. No distance cap (map pins only).
    static func stationsInVisibleRegion(
        _ region: MKCoordinateRegion,
        from stations: [MobilityStation]
    ) -> [MobilityStation] {
        GeoUtilities.filter(stations, in: region, paddingFactor: mapPinQueryPaddingFactor)
    }

    /// Use the MapKit camera region as reported by `onMapCameraChange`.
    /// Do not shrink/offset for sheet insets — that produced a query box ~45% of the map height
    /// and pins vanished on small pans even when still on screen.
    static func regionForStationFiltering(from cameraRegion: MKCoordinateRegion) -> MKCoordinateRegion {
        cameraRegion
    }
}
