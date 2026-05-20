//
//  SelectedCityStore.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import Foundation

/// How the user wants the app to anchor map, distance, and “you are here”.
enum CitySelectionMode: Equatable {
    /// Use device GPS when authorized.
    case currentLocation
    /// Use the chosen CityBikes network hub from `networks.json`.
    case network(String)
}

/// Persists city / location preference from the Choose city sheet.
@MainActor
final class SelectedCityStore: ObservableObject {
    @Published private(set) var selectionMode: CitySelectionMode?

    private let modeKey = "citySelectionMode"
    private let networkKey = "selectedCityBikesNetworkId"

    init() {
        selectionMode = Self.loadPersistedMode(modeKey: modeKey, networkKey: networkKey)
    }

    var usesCurrentLocation: Bool {
        if case .currentLocation = selectionMode { return true }
        return false
    }

    var selectedNetworkId: String? {
        if case .network(let id) = selectionMode { return id }
        return nil
    }

    /// `true` after the user picks Current location or a city in Choose city.
    var hasExplicitSelection: Bool {
        selectionMode != nil
    }

    func selectCurrentLocation() {
        selectionMode = .currentLocation
        UserDefaults.standard.set("current", forKey: modeKey)
        UserDefaults.standard.removeObject(forKey: networkKey)
    }

    func save(networkId: String) {
        selectionMode = .network(networkId)
        UserDefaults.standard.set("network", forKey: modeKey)
        UserDefaults.standard.set(networkId, forKey: networkKey)
    }

    func clear() {
        selectionMode = nil
        UserDefaults.standard.removeObject(forKey: modeKey)
        UserDefaults.standard.removeObject(forKey: networkKey)
    }

    private static func loadPersistedMode(modeKey: String, networkKey: String) -> CitySelectionMode? {
        switch UserDefaults.standard.string(forKey: modeKey) {
        case "current":
            return .currentLocation
        case "network":
            if let id = UserDefaults.standard.string(forKey: networkKey), !id.isEmpty {
                return .network(id)
            }
            return nil
        default:
            if let legacyId = UserDefaults.standard.string(forKey: networkKey), !legacyId.isEmpty {
                return .network(legacyId)
            }
            return nil
        }
    }
}
