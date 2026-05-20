//
//  MapPanelFavoritesView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Favorites list pushed inside the discovery sheet.
struct MapPanelFavoritesView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @ObservedObject var viewModel: StationListViewModel
    var onSelectStation: (MobilityStation) -> Void

    @State private var favorites: [MobilityStation] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingStateView(String(localized: "Loading favorites…"))
            } else if favorites.isEmpty {
                EmptyStateView(
                    title: String(localized: "No Favorites"),
                    systemImage: "heart",
                    message: String(localized: "Save stations from the map to see them here.")
                )
            } else {
                List {
                    ForEach(favorites) { station in
                        StationRowView(
                            station: station,
                            isFavorite: true,
                            distanceMeters: viewModel.distanceMeters(for: station),
                            recommendationScore: nil,
                            onSelect: { onSelectStation(station) },
                            onFavoriteChange: {
                                favorites.removeAll { $0.favoriteKey == station.favoriteKey }
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "Saved"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let repo = dependencies.favoritesRepository else { return }
        favorites = (try? await repo.favoriteStations()) ?? []
    }
}
