//
//  LocalNetworksProvider.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Reads the bundled CityBikes network catalog from `networks.json` for city picking.
struct LocalNetworksProvider: Sendable {
    private let networks: [MobilityNetwork]

    init(networks: [MobilityNetwork]) {
        self.networks = networks
    }

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "networks", withExtension: "json") else {
            throw LocalNetworksError.missingResource
        }
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(LocalNetworksFile.self, from: data)
        networks = payload.networks
            .map { $0.toDomain() }
            .sorted { $0.cityTitle.localizedCaseInsensitiveCompare($1.cityTitle) == .orderedAscending }
    }

    var allNetworks: [MobilityNetwork] { networks }

    func network(id: String) -> MobilityNetwork? {
        networks.first { $0.id == id }
    }

    func search(query: String) -> [MobilityNetwork] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return networks }
        let q = trimmed.lowercased()
        return networks.filter {
            $0.cityTitle.lowercased().contains(q) ||
            $0.name.lowercased().contains(q) ||
            $0.id.lowercased().contains(q) ||
            ($0.country?.lowercased().contains(q) ?? false)
        }
    }
}

enum LocalNetworksError: Error {
    case missingResource
}

// MARK: - JSON

private struct LocalNetworksFile: Decodable, Sendable {
    let networks: [LocalNetworkRecord]
}

private struct LocalNetworkRecord: Decodable, Sendable {
    let id: String
    let name: String
    let location: LocalNetworkLocation?
}

private struct LocalNetworkLocation: Decodable, Sendable {
    let latitude: Double
    let longitude: Double
    let city: String
    let country: String?
}

private extension LocalNetworkRecord {
    func toDomain() -> MobilityNetwork {
        MobilityNetwork(
            id: id,
            name: name,
            city: location?.city,
            country: location?.country,
            latitude: location?.latitude,
            longitude: location?.longitude
        )
    }
}
