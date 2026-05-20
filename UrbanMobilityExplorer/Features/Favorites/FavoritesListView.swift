//
//  FavoritesListView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct FavoritesListView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @State private var favorites: [MobilityStation] = []
    @State private var stationForDetail: MobilityStation?
    @State private var loadState: FavoritesLoadState = .loading
    @State private var errorMessage: String?

    enum FavoritesLoadState {
        case loading
        case loaded
        case empty
        case error
    }

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading:
                    LoadingStateView(String(localized: "Loading favorites…"))
                case .empty:
                    EmptyStateView(
                        title: String(localized: "No Favorites"),
                        systemImage: "heart",
                        message: String(localized: "Save stations from the list to see them here. Favorites work offline.")
                    )
                case .error:
                    ErrorStateView(message: errorMessage ?? "", retry: { Task { await load() } })
                case .loaded:
                    List {
                        ForEach(favorites) { station in
                            StationRowView(
                                station: station,
                                isFavorite: true,
                                recommendationScore: nil,
                                onSelect: { stationForDetail = station },
                                onFavoriteChange: {
                                    favorites.removeAll { $0.favoriteKey == station.favoriteKey }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(String(localized: "Favorites"))
            .refreshable { await load() }
            .navigationDestination(item: $stationForDetail) { station in
                StationDetailView(station: station, dependencies: dependencies)
            }
            .task { await load() }
        }
    }

    private func load() async {
        loadState = .loading
        guard let repo = dependencies.favoritesRepository else {
            loadState = .error
            errorMessage = String(localized: "Favorites not ready.")
            return
        }
        do {
            favorites = try await repo.favoriteStations()
            loadState = favorites.isEmpty ? .empty : .loaded
        } catch {
            errorMessage = error.localizedDescription
            loadState = .error
        }
    }
}

#Preview("Favorites – Empty") {
    FavoritesListView()
        .previewDependencies()
}

#Preview("Favorites – Loaded") {
    FavoritesListPreviewHost(stations: PreviewData.stations)
        .previewDependencies()
}

#if DEBUG
struct FavoritesListPreviewHost: View {
    let stations: [MobilityStation]

    var body: some View {
        NavigationStack {
            List(stations) { station in
                StationRowView(
                    station: station,
                    isFavorite: true,
                    recommendationScore: nil,
                    onFavoriteChange: {}
                )
            }
            .navigationTitle(String(localized: "Favorites"))
        }
    }
}
#endif
