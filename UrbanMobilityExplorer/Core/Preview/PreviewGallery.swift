//
//  PreviewGallery.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

#if DEBUG
#Preview("UI Gallery") {
    NavigationStack {
        List {
            Section("Screens") {
                NavigationLink("Map Discovery") {
                    MapDiscoveryView(dependencies: AppDependencies.previewForCanvas(), viewModel: .previewForCanvas())
                        .previewDependencies()
                        .navigationBarHidden(true)
                }
                NavigationLink("Station List") {
                    StationListView(dependencies: AppDependencies.previewForCanvas(), viewModel: .previewForCanvas())
                        .previewDependencies()
                }
                NavigationLink("Station Detail (legacy)") {
                    StationDetailView(station: PreviewData.station, dependencies: AppDependencies.previewForCanvas())
                        .previewDependencies()
                }
            }

            Section("Sheets") {
                NavigationLink("Browse Sheet") {
                    StationBrowseSheet(
                        viewModel: .previewForCanvas(),
                        dependencies: AppDependencies.previewForCanvas(),
                        onSelect: { _ in }
                    )
                    .previewDependencies()
                }
                NavigationLink("Detail Panel") {
                    MobilityStationDetailPanelView(station: .preview)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
                NavigationLink("Detail Sheet") {
                    StationDetailSheet(
                        station: PreviewData.station,
                        dependencies: AppDependencies.previewForCanvas(),
                        distanceMeters: 4_500,
                        onDismiss: {},
                        viewModel: .previewForCanvas()
                    )
                    .previewDependencies()
                    .background(Color.gray.opacity(0.2))
                }
                NavigationLink("Favorites List") {
                    FavoritesListPreviewHost(stations: PreviewData.stations)
                }
                NavigationLink("Favorites Sheet") {
                    FavoritesSheetView(onSelect: { _ in })
                        .previewDependencies()
                }
            }

            Section("Components") {
                HStack {
                    Text("90 pts")
                    StarRatingView(score: 90)
                }
                HStack {
                    Text("82 pts")
                    StarRatingView(score: 82)
                }
                NavigationLink("Discovery Card") { DiscoveryCardPreviewHost() }
                NavigationLink("Map Markers") { MapMarkersPreviewHost() }
                NavigationLink("Station Rows") { StationRowsPreviewHost() }
                NavigationLink("State Views") { StateViewsPreviewHost() }
            }
        }
        .navigationTitle("UI Gallery")
    }
}

private struct DiscoveryCardPreviewHost: View {
    @StateObject private var viewModel = StationListViewModel.previewForCanvas()

    var body: some View {
        DiscoveryBottomCard(
            viewModel: viewModel,
            userName: UIConstants.defaultGreetingName,
            onBikesTap: {},
            onFavoritesTap: {}
        )
        .padding()
        .background(PreviewCanvas.background)
    }
}

private struct MapMarkersPreviewHost: View {
    var body: some View {
        HStack(spacing: 24) {
            StationMapMarker(bikeCount: 5, isSelected: false)
            StationMapMarker(bikeCount: 12, isSelected: true)
            StationMapMarker(bikeCount: 0, isSelected: false)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PreviewCanvas.background)
    }
}

private struct StationRowsPreviewHost: View {
    var body: some View {
        List {
            StationRowView(
                station: PreviewData.station,
                isFavorite: true,
                distanceMeters: 450,
                recommendationScore: 82
            )
            StationRowView(station: PreviewData.stationLowAvailability, isFavorite: false, recommendationScore: nil)
        }
    }
}

private struct StateViewsPreviewHost: View {
    var body: some View {
        TabView {
            LoadingStateView().tabItem { Label("Loading", systemImage: "hourglass") }
            EmptyStateView(title: "Empty", systemImage: "bicycle", message: "No stations").tabItem { Label("Empty", systemImage: "tray") }
            ErrorStateView(message: "Network error", retry: {}).tabItem { Label("Error", systemImage: "exclamationmark.triangle") }
            StaleDataBanner(source: .cache, isStale: true).tabItem { Label("Banner", systemImage: "clock") }
        }
    }
}
#endif
