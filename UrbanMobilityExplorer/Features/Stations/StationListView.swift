//
//  StationListView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct StationListView: View {
    @StateObject private var viewModel: StationListViewModel
    @EnvironmentObject private var dependencies: AppDependencies
    @State private var stationForDetail: MobilityStation?

    init(dependencies: AppDependencies, viewModel: StationListViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? StationListViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading where viewModel.stations.isEmpty:
                    LoadingStateView()
                case .error(let message) where viewModel.stations.isEmpty:
                    ErrorStateView(message: message, retry: viewModel.refresh)
                case .empty:
                    EmptyStateView(
                        title: String(localized: "No Stations"),
                        systemImage: "bicycle",
                        message: String(localized: "Try another network or adjust your filters.")
                    )
                default:
                    stationList
                }
            }
            .navigationTitle(String(localized: "Stations"))
            .searchable(text: $viewModel.searchText, prompt: String(localized: "Search stations"))
            .toolbar { toolbarContent }
            .refreshable { viewModel.refresh() }
            .onAppear { viewModel.onAppear() }
        }
    }

    @ViewBuilder
    private var stationList: some View {
        List(viewModel.displayedStations, id: \.favoriteKey) { station in
            StationRowView(
                station: station,
                isFavorite: viewModel.isFavorite(station),
                distanceMeters: viewModel.distanceMeters(for: station),
                recommendationScore: viewModel.sortOption == .topRated
                    ? viewModel.recommendationScore(for: station)
                    : nil,
                onSelect: { stationForDetail = station },
                onFavoriteChange: {
                    Task { await viewModel.refreshFavoriteKeys() }
                }
            )
        }
        .listStyle(.plain)
        .overlay(alignment: .top) {
            StaleDataBanner(source: viewModel.dataSource, isStale: viewModel.isStale)
        }
        .navigationDestination(item: $stationForDetail) { station in
            StationDetailView(
                station: station,
                dependencies: dependencies,
                distanceMeters: viewModel.distanceMeters(for: station)
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker(String(localized: "Network"), selection: $viewModel.selectedNetworkId) {
                    ForEach(viewModel.networks) { network in
                        Text(network.displayName).tag(network.id)
                    }
                }
                .onChange(of: viewModel.selectedNetworkId) { _, newValue in
                    viewModel.selectNetwork(newValue)
                }
            } label: {
                Label(String(localized: "Network"), systemImage: "globe")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(StationSortOption.allCases) { option in
                        Text(option.menuTitle).tag(option)
                    }
                }
                Divider()
                Picker(String(localized: "Filter"), selection: $viewModel.filterOption) {
                    ForEach(StationFilterOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityLabel("Sort stations")
        }
        if dependencies.locationService.authorizationStatus == .notDetermined {
            ToolbarItem(placement: .bottomBar) {
                Button(String(localized: "Enable Location for Distance")) {
                    viewModel.requestLocationAccess()
                }
                .font(.footnote)
            }
        }
    }
}

#Preview("Station List") {
    StationListView(dependencies: AppDependencies.previewForCanvas(), viewModel: .previewForCanvas())
        .previewDependencies()
}

#Preview("Station List – Loading") {
    StationListView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas(stations: [], loadState: .loading)
    )
    .previewDependencies()
}

#Preview("Station List – Error") {
    StationListView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas(stations: [], loadState: .error("Could not load stations."))
    )
    .previewDependencies()
}
