//
//  FavoritesSheetView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct FavoritesSheetView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var favorites: [MobilityStation] = []
    @State private var isLoading = true

    var onSelect: (MobilityStation) -> Void

    var body: some View {
        NavigationStack {
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
                                recommendationScore: nil,
                                onSelect: { onSelect(station) },
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                        
                    }
                }
            }
            .task { await load() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let repo = dependencies.favoritesRepository else { return }
        favorites = (try? await repo.favoriteStations()) ?? []
    }
}

#Preview("Favorites Sheet – Empty") {
    FavoritesSheetView(onSelect: { _ in })
        .previewDependencies()
}

#Preview("Favorites Sheet – Loaded") {
    NavigationStack {
        List(PreviewData.stations) { station in
            StationRowView(station: station, isFavorite: true, onFavoriteChange: {})
        }
        .navigationTitle(String(localized: "Saved"))
    }
}
