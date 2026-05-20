//
//  SwiftDataFavoritesRepository.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func isFavorite(stationId: String, networkId: String) async -> Bool {
        let key = MobilityStation.favoriteKey(networkId: networkId, stationId: stationId)
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.compoundKey == key }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    func toggleFavorite(_ station: MobilityStation) async throws {
        let key = station.favoriteKey
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.compoundKey == key }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteStation(from: station))
        }
        try modelContext.save()
    }

    func favoriteStations() async throws -> [MobilityStation] {
        var descriptor = FetchDescriptor<FavoriteStation>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func favoriteIDs() async -> Set<String> {
        let descriptor = FetchDescriptor<FavoriteStation>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return Set(favorites.map(\.compoundKey))
    }
}
