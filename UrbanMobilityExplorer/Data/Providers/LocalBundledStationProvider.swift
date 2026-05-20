//
//  LocalBundledStationProvider.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import UrbanMobilityNetworking

/// Offline fallback using bundled JSON for review without network.
struct LocalBundledStationProvider: StationDataProviding, Sendable {
    private let networks: [MobilityNetwork]
    private let stationsByNetwork: [String: [MobilityStation]]

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "london_stations", withExtension: "json") else {
            throw StationDataError.notFound
        }
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(BundledLondonFile.self, from: data)
        let networkId = file.network.id
        let stations = (file.network.stations ?? []).map { $0.toDomain(networkId: networkId) }
        networks = [
            MobilityNetwork(
                id: networkId,
                name: file.network.name ?? networkId,
                city: file.network.location?.city,
                country: file.network.location?.country,
                latitude: file.network.location?.latitude,
                longitude: file.network.location?.longitude
            )
        ]
        stationsByNetwork = [networkId: stations]
    }

    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork] {
        _ = forceRefresh
        return networks.sorted { $0.name < $1.name }
    }

    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult {
        _ = forceRefresh
        guard var stations = stationsByNetwork[networkId] else {
            throw StationDataError.notFound
        }
        if let query {
            stations = GeoUtilities.filter(stations, center: query.center, radiusMeters: query.radiusMeters)
        }
        return StationFetchResult(stations: stations, source: .bundled, fetchedAt: Date(), isStale: false)
    }

    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation? {
        stationsByNetwork[networkId]?.first { $0.id == stationId }
    }
}

// MARK: - Bundled `london_stations.json` (CityBikes API shape)

private struct BundledLondonFile: Decodable, Sendable {
    let network: BundledLondonNetwork
}

private struct BundledLondonNetwork: Decodable, Sendable {
    let id: String
    let name: String?
    let location: BundledLondonLocation?
    let stations: [CityBikeStation]?
}

private struct BundledLondonLocation: Decodable, Sendable {
    let latitude: Double?
    let longitude: Double?
    let city: String?
    let country: String?
}
