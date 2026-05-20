//
//  MobilityStation.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import CoreLocation

/// Domain model for an urban mobility station (bike/scooter share).
struct MobilityStation: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let networkId: String
    let name: String
    let latitude: Double
    let longitude: Double
    let freeBikes: Int?
    let emptySlots: Int?
    let totalSlots: Int?
    let lastUpdated: Date?
    let address: String?
    /// From `extra.renting` (1 = open, 0 = closed). Not all networks provide this.
    let renting: Bool?
    /// From `extra.returning` (1 = open, 0 = closed).
    let returning: Bool?
    /// From `extra.ebikes` when available.
    let ebikes: Int?
    /// From `extra.rental_uris` (iOS/Android deep link).
    let rentalURL: URL?
    /// Persisted usefulness score (0–100). Set on network fetch; never changes until the next live refresh.
    let recommendationScore: Double?

    nonisolated init(
        id: String,
        networkId: String,
        name: String,
        latitude: Double,
        longitude: Double,
        freeBikes: Int? = nil,
        emptySlots: Int? = nil,
        totalSlots: Int? = nil,
        lastUpdated: Date? = nil,
        address: String? = nil,
        renting: Bool? = nil,
        returning: Bool? = nil,
        ebikes: Int? = nil,
        rentalURL: URL? = nil,
        recommendationScore: Double? = nil
    ) {
        self.id = id
        self.networkId = networkId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.freeBikes = freeBikes
        self.emptySlots = emptySlots
        self.totalSlots = totalSlots
        self.lastUpdated = lastUpdated
        self.address = address
        self.renting = renting
        self.returning = returning
        self.ebikes = ebikes
        self.rentalURL = rentalURL
        self.recommendationScore = recommendationScore
    }

    nonisolated func withRecommendationScore(_ score: Double) -> MobilityStation {
        MobilityStation(
            id: id,
            networkId: networkId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            freeBikes: freeBikes,
            emptySlots: emptySlots,
            totalSlots: totalSlots,
            lastUpdated: lastUpdated,
            address: address,
            renting: renting,
            returning: returning,
            ebikes: ebikes,
            rentalURL: rentalURL,
            recommendationScore: score
        )
    }

    /// Keeps the stored score when live station fields (bikes/docks) update without a full network rescore.
    nonisolated func mergingLiveRefresh(_ updated: MobilityStation) -> MobilityStation {
        MobilityStation(
            id: updated.id,
            networkId: updated.networkId,
            name: updated.name,
            latitude: updated.latitude,
            longitude: updated.longitude,
            freeBikes: updated.freeBikes,
            emptySlots: updated.emptySlots,
            totalSlots: updated.totalSlots,
            lastUpdated: updated.lastUpdated,
            address: updated.address,
            renting: updated.renting,
            returning: updated.returning,
            ebikes: updated.ebikes,
            rentalURL: updated.rentalURL,
            recommendationScore: recommendationScore ?? updated.recommendationScore
        )
    }

    nonisolated var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var availabilityLabel: String {
        let bikes = freeBikes ?? 0
        let slots = emptySlots ?? 0
        if bikes == 0 && slots == 0 { return String(localized: "No data") }
        return String(localized: "\(bikes) bikes · \(slots) docks free")
    }

    nonisolated var availabilityScore: Double {
        let bikes = Double(freeBikes ?? 0)
        let slots = Double(emptySlots ?? 0)
        guard bikes + slots > 0 else { return 0 }
        return min(1.0, (bikes + slots) / 20.0)
    }

    nonisolated func distanceMeters(from location: CLLocation) -> CLLocationDistance {
        location.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }

    /// Great-circle distance to a coordinate (city hub or map focus).
    nonisolated func straightLineDistanceMeters(to anchor: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: anchor.latitude, longitude: anchor.longitude))
    }
}

struct MobilityNetwork: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let name: String
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    var isFavorite: Bool

    nonisolated init(
        id: String,
        name: String,
        city: String? = nil,
        country: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.isFavorite = isFavorite
    }

    var displayName: String {
        if let city, !city.isEmpty { return "\(name) · \(city)" }
        return name
    }

    /// City label for the map navigation bar.
    var cityTitle: String {
        if let city, !city.isEmpty { return city }
        return name
    }

    /// Single-line label for city/network pickers (`CountrySelectionView`).
    var selectionTitle: String {
        let cityLabel = cityTitle
        if cityLabel != name, !name.isEmpty {
            return "\(cityLabel) · \(name)"
        }
        return cityLabel
    }

    func matchesSearch(_ query: String) -> Bool {
        let q = query.lowercased()
        return cityTitle.lowercased().contains(q)
            || name.lowercased().contains(q)
            || id.lowercased().contains(q)
            || (country?.lowercased().contains(q) ?? false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, city, country, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isFavorite = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
    }

    nonisolated func markingFavorite(_ isFavorite: Bool) -> MobilityNetwork {
        MobilityNetwork(
            id: id,
            name: name,
            city: city,
            country: country,
            latitude: latitude,
            longitude: longitude,
            isFavorite: isFavorite
        )
    }
}

enum StationSortOption: String, CaseIterable, Identifiable, Sendable {
    case topRated
    case nearest
    case mostBikes

    var id: String { rawValue }

    /// English labels for the station list sort menu.
    var menuTitle: String {
        switch self {
        case .topRated: "Highest rating"
        case .nearest: "Nearest"
        case .mostBikes: "Most bikes"
        }
    }
}

enum StationFilterOption: String, CaseIterable, Identifiable, Sendable {
    case all
    case hasBikes
    case hasDocks
    case favoritesOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .hasBikes: String(localized: "Has bikes")
        case .hasDocks: String(localized: "Has docks")
        case .favoritesOnly: String(localized: "Favorites")
        }
    }
}
