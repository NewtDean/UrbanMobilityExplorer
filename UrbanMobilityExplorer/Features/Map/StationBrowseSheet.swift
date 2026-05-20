//
//  StationBrowseSheet.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct StationBrowseSheet: View {
    @ObservedObject var viewModel: StationListViewModel
    let dependencies: AppDependencies
    var onSelect: (MobilityStation) -> Void

    @Environment(\.dismiss) private var dismiss

    private var trimmedSearch: String {
        viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            browseContent
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String(localized: "Search by station name")
                )
                .navigationTitle(String(localized: "Stations"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        StationSortMenu(sortOption: $viewModel.sortOption)
                    }
                }
        }
        .background(Color.white)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.searchText = "" }
        .task {
            if viewModel.stations.isEmpty {
                await viewModel.bootstrap()
            }
            await viewModel.prepareForStationSearch()
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        switch viewModel.loadState {
        case .idle, .loading where viewModel.stations.isEmpty:
            LoadingStateView()
        case .error(let message) where viewModel.stations.isEmpty:
            ErrorStateView(message: message, retry: viewModel.refresh)
        case .empty:
            EmptyStateView(
                title: String(localized: "No Stations"),
                systemImage: "bicycle",
                message: String(localized: "Try another filter or network.")
            )
        default:
            if viewModel.displayedStations.isEmpty, !trimmedSearch.isEmpty {
                ContentUnavailableView.search(text: trimmedSearch)
            } else {
                List(viewModel.displayedStations, id: \.favoriteKey) { station in
                    StationRowView(
                        station: station,
                        isFavorite: viewModel.isFavorite(station),
                        distanceMeters: viewModel.distanceMeters(for: station),
                        recommendationScore: viewModel.sortOption == .topRated
                            ? viewModel.recommendationScore(for: station)
                            : nil,
                        onSelect: {
                            viewModel.commitSearchToHistory()
                            onSelect(station)
                        },
                        onFavoriteChange: {
                            Task { await viewModel.refreshFavoriteKeys() }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
    }
}

#Preview("Browse Sheet") {
    StationBrowseSheet(
        viewModel: .previewForCanvas(),
        dependencies: AppDependencies.previewForCanvas(),
        onSelect: { _ in }
    )
    .previewDependencies()
}

#Preview("Browse Sheet – Empty") {
    StationBrowseSheet(
        viewModel: .previewForCanvas(stations: [], loadState: .empty),
        dependencies: AppDependencies.previewForCanvas(),
        onSelect: { _ in }
    )
    .previewDependencies()
}
