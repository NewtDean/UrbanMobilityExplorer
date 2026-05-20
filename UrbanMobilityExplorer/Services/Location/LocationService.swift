//
//  LocationService.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationSnapshot, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: LocationAuthorizationStatus {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async {
        manager.requestWhenInUseAuthorization()
    }

    func currentLocation() async throws -> CLLocationSnapshot {
        guard authorizationStatus == .authorized else {
            throw StationDataError.underlying(LocationError.notAuthorized)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation?.resume(throwing: LocationError.cancelled)
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            continuation?.resume(returning: CLLocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                horizontalAccuracy: location.horizontalAccuracy,
                timestamp: location.timestamp
            ))
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        _ = manager
    }
}

enum LocationError: Error, LocalizedError {
    case notAuthorized
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notAuthorized: String(localized: "Location access is required for distance sorting.")
        case .cancelled: String(localized: "Location request cancelled.")
        }
    }
}
