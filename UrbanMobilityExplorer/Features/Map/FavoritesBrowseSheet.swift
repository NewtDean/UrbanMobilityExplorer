//
//  FavoritesBrowseSheet.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Saved stations list — same sheet chrome as `StationBrowseSheet` (half height on open, drag to expand).
struct FavoritesBrowseSheet: View {
    @ObservedObject var viewModel: StationListViewModel
    @EnvironmentObject private var dependencies: AppDependencies
    var onSelect: (MobilityStation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var favorites: [MobilityStation] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            favoritesContent
                .navigationTitle(String(localized: "Saved"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
        .background(Color.white)
        .task { await load() }
    }

    @ViewBuilder
    private var favoritesContent: some View {
        if isLoading {
            LoadingStateView(String(localized: "Loading favorites…"))
        } else if favorites.isEmpty {
            EmptyStateView(
                title: String(localized: "No Favorites"),
                systemImage: "heart",
                message: String(localized: "Save stations from the map to see them here.")
            )
        } else {
            List(favorites) { station in
                StationRowView(
                    station: station,
                    isFavorite: true,
                    distanceMeters: viewModel.distanceMeters(for: station),
                    recommendationScore: nil,
                    onSelect: { onSelect(station) },
                    onFavoriteChange: {
                        favorites.removeAll { $0.favoriteKey == station.favoriteKey }
                    }
                )
            }
            .listStyle(.plain)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let repo = dependencies.favoritesRepository else { return }
        favorites = (try? await repo.favoriteStations()) ?? []
    }
}

// MARK: - Shared list sheet chrome (Stations + Saved)

extension View {
    /// Half-height on open, expandable to near full height; detent drives map FAB position.
    func browseListSheetPresentation(detent: Binding<PresentationDetent>) -> some View {
        self
            .presentationDetents(MapBottomPanelMetrics.browseListDetents, selection: detent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(MapBottomPanelMetrics.sheetCornerRadius)
            .presentationBackground(Color.white)
            .presentationBackgroundInteraction(.enabled(upThrough: MapBottomPanelMetrics.browseListLargeDetent))
            .presentationContentInteraction(.scrolls)
    }
}

#if DEBUG
#Preview("Favorites Sheet") {
    FavoritesBrowseSheet(
        viewModel: .previewForCanvas(),
        onSelect: { _ in }
    )
    .environmentObject(AppDependencies.previewForCanvas())
    .previewDependencies()
}
#endif
