//
//  CityNameResolver.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation

/// Resolves a display city name from coordinates using Apple's reverse geocoding (MapKit / Core Location).
enum CityNameResolver: Sendable {
    nonisolated static func resolveCityName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            if let locality = placemark.locality, !locality.isEmpty { return locality }
            if let subLocality = placemark.subLocality, !subLocality.isEmpty { return subLocality }
            if let area = placemark.administrativeArea, !area.isEmpty { return area }
            return nil
        } catch {
            return nil
        }
    }
}
