//
//  StationCacheModelActor.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

/// SwiftData persistence for station/network cache (survives app restarts).
@ModelActor
actor StationCacheModelActor {
    func loadNetworks() throws -> (networks: [MobilityNetwork], fetchedAt: Date)? {
        let descriptor = FetchDescriptor<CachedNetworkRecord>()
        let records = try modelContext.fetch(descriptor)
        guard !records.isEmpty else { return nil }
        let fetchedAt = records.map(\.cachedAt).max() ?? .distantPast
        let networks = records
            .map { $0.toDomain() }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return (networks, fetchedAt)
    }

    func replaceNetworks(_ networks: [MobilityNetwork], fetchedAt: Date) throws {
        try modelContext.delete(model: CachedNetworkRecord.self)
        for network in networks {
            modelContext.insert(CachedNetworkRecord(from: network, cachedAt: fetchedAt))
        }
        try modelContext.save()
    }

    func loadStations(
        networkId: String,
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) throws -> [MobilityStation] {
        let id = networkId
        let descriptor = FetchDescriptor<CachedStationRecord>(
            predicate: #Predicate { record in
                record.networkId == id &&
                record.latitude >= minLatitude &&
                record.latitude <= maxLatitude &&
                record.longitude >= minLongitude &&
                record.longitude <= maxLongitude
            }
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func loadStations(networkId: String) throws -> (stations: [MobilityStation], fetchedAt: Date)? {
        let id = networkId
        let descriptor = FetchDescriptor<CachedStationRecord>(
            predicate: #Predicate { $0.networkId == id }
        )
        let records = try modelContext.fetch(descriptor)
        guard !records.isEmpty else { return nil }
        let fetchedAt = records.map(\.cachedAt).max() ?? .distantPast
        return (records.map { $0.toDomain() }, fetchedAt)
    }

    func replaceStations(
        _ stations: [MobilityStation],
        networkId: String,
        fetchedAt: Date
    ) throws {
        let id = networkId
        try modelContext.delete(
            model: CachedStationRecord.self,
            where: #Predicate { $0.networkId == id }
        )
        for station in stations {
            modelContext.insert(CachedStationRecord(from: station, cachedAt: fetchedAt))
        }
        try modelContext.save()
    }

    func cachedStationNetworkIds() throws -> [String] {
        let descriptor = FetchDescriptor<CachedStationRecord>()
        let records = try modelContext.fetch(descriptor)
        return Array(Set(records.map(\.networkId)))
    }
}
