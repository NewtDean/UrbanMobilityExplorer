//
//  SwiftDataFavoriteNetworksRepository.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataFavoriteNetworksRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func favoriteNetworkIDs() async -> Set<String> {
        let descriptor = FetchDescriptor<FavoriteNetwork>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return Set(favorites.map(\.networkId))
    }

    func isFavorite(networkId: String) async -> Bool {
        let id = networkId
        let descriptor = FetchDescriptor<FavoriteNetwork>(
            predicate: #Predicate { $0.networkId == id }
        )
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    func toggleFavorite(networkId: String) async throws {
        let id = networkId
        let descriptor = FetchDescriptor<FavoriteNetwork>(
            predicate: #Predicate { $0.networkId == id }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteNetwork(networkId: networkId))
        }
        try modelContext.save()
    }
}
