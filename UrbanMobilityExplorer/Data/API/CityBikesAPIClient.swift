//
//  CityBikesAPIClient.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import UrbanMobilityNetworking

/// Live provider for CityBikes API — https://api.citybik.es/v2 (free, no API key).
struct CityBikesAPIClient: StationDataProviding, Sendable {
    func fetchNetworks(forceRefresh: Bool) async throws -> [MobilityNetwork] {
        _ = forceRefresh
        do {
            let response = try await NetworksAPI.listNetworks()
            return response.networks.map { $0.toDomain() }.sorted { $0.name < $1.name }
        } catch {
            throw mapError(error)
        }
    }

    func fetchStations(
        networkId: String,
        forceRefresh: Bool,
        query: StationSearchQuery?
    ) async throws -> StationFetchResult {
        _ = forceRefresh
        _ = query
        do {
            let response = try await NetworksAPI.getNetworkStations(
                networkId: networkId,
                fields: "stations"
            )
            let stations = (response.network.stations ?? []).map { $0.toDomain(networkId: networkId) }
            guard !stations.isEmpty else {
                throw StationDataError.notFound
            }
            return StationFetchResult(stations: stations, source: .live, fetchedAt: Date(), isStale: false)
        } catch {
            throw mapError(error)
        }
    }

    func fetchStation(networkId: String, stationId: String) async throws -> MobilityStation? {
        let result = try await fetchStations(networkId: networkId, forceRefresh: true, query: nil)
        return result.stations.first { $0.id == stationId }
    }

    private func mapError(_ error: Error) -> StationDataError {
        if error is CancellationError || Task.isCancelled {
            return .cancelled
        }
        if let stationError = error as? StationDataError {
            return stationError
        }
        if let errorResponse = error as? ErrorResponse {
            switch errorResponse {
            case .error(_, _, _, let underlying):
                return .underlying(underlying)
            }
        }
        return .underlying(error)
    }
}
