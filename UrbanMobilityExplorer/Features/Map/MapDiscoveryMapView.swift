//
//  MapDiscoveryMapView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import MapKit
import SwiftUI

// MARK: - Discovery map (SwiftUI)

/// MapKit map with a default street-level camera (500 m). User pinch-zoom is allowed; sheets do not drive zoom.
struct MapDiscoveryMapView: View {
    @ObservedObject var mapManager: MapManager
    /// When this changes (e.g. new city), the camera re-locks once. Sheet detents do not change this.
    var cameraLockKey: String
    var initialCenter: CLLocationCoordinate2D?
    var stations: [MobilityStation]
    var selectedStationKey: String?
    var userLocation: CLLocationCoordinate2D?
    var onSelectStation: (MobilityStation) -> Void
    var onVisibleRegionChange: (MKCoordinateRegion) -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var appliedCameraLockKey: String?
    /// Suppresses bogus regions from `.automatic` before the city camera is applied.
    @State private var isInitialCameraLocked = false

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if let userLocation {
                Annotation("", coordinate: userLocation, anchor: .center) {
                    UserLocationMarker()
                }
            }

            ForEach(stations, id: \.favoriteKey) { station in
                Annotation(station.locationDisplayName, coordinate: station.coordinate, anchor: .bottom) {
                    Button {
                        onSelectStation(station)
                    } label: {
                        StationMapMarker(
                            bikeCount: station.freeBikes ?? 0,
                            isSelected: station.favoriteKey == selectedStationKey
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        // Fixed insets (detail zoom framing). Do not use dynamic sheet height — that shrinks the map.
        .safeAreaPadding(EdgeInsets(mapManager.focusEdgePadding))
        .onAppear { lockInitialCameraIfNeeded() }
        .onChange(of: cameraLockKey) { _, _ in
            isInitialCameraLocked = false
            lockInitialCameraIfNeeded()
        }
        .onChange(of: initialCenter?.latitude) { _, _ in lockInitialCameraIfNeeded() }
        .onChange(of: initialCenter?.longitude) { _, _ in lockInitialCameraIfNeeded() }
        .onChange(of: mapManager.focusRequest) { _, request in
            guard let request else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .region(request.region)
            }
        }
        .onMapCameraChange(frequency: .continuous) { context in
            guard isInitialCameraLocked else { return }
            onVisibleRegionChange(context.region)
        }
    }

    /// One-time 500 m region (same as station detail). No further camera updates.
    private func lockInitialCameraIfNeeded() {
        guard appliedCameraLockKey != cameraLockKey, let center = initialCenter else { return }
        appliedCameraLockKey = cameraLockKey
        isInitialCameraLocked = false
        cameraPosition = .region(mapManager.cameraRegion(focus: center))
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            isInitialCameraLocked = true
        }
    }
}

// MARK: - User location

private struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 88, height: 88)
                .overlay(Circle().stroke(Color.blue.opacity(0.6), lineWidth: 1))

            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
    }
}

// MARK: - EdgeInsets

private extension EdgeInsets {
    init(_ insets: UIEdgeInsets) {
        self.init(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
}
