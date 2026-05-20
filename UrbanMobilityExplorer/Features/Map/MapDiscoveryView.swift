//
//  MapDiscoveryView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import MapKit
import SwiftUI

struct MapDiscoveryView: View {
    @StateObject private var viewModel: StationListViewModel
    @StateObject private var mapManager = MapManager()
    @EnvironmentObject private var dependencies: AppDependencies

    @State private var selectedStation: MobilityStation?
    @State private var showMenu = false
    /// Nested sheet on top of the discovery panel (secondary flows, city picker, browse list).
    @State private var stackedSheet: MapStackedSheet?
    @State private var detailStation: MobilityStation?
    @State private var detailSheetHeight: CGFloat = MapBottomPanelMetrics.detailPanelMinHeight
    @State private var browseListDetent: PresentationDetent = MapBottomPanelMetrics.browseListMediumDetent
    /// Always-on discovery entry sheet (fixed 200pt).
    @State private var showDiscoveryPanel = true
    private let userName = UIConstants.defaultGreetingName

    init(dependencies: AppDependencies, viewModel: StationListViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? StationListViewModel(dependencies: dependencies))
    }

    var body: some View {
        mapChrome
        .tint(AppTheme.primaryGreen)
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            await viewModel.bootstrap()
        }
        .onChange(of: stackedSheet) { _, sheet in
            if sheet?.isBrowseListStyle == true {
                browseListDetent = MapBottomPanelMetrics.browseListMediumDetent
                viewModel.restoreMapStationsForMapFocus()
            }
            guard sheet == nil else { return }
            selectedStation = nil
            detailStation = nil
            viewModel.clearMapStationSelection()
        }
        .onChange(of: viewModel.mapFocusRevision) { _, _ in
            guard let center = viewModel.mapFocusCoordinate else { return }
            if viewModel.shouldFrameMapFocusLikeStationDetail(at: center) {
                mapManager.focusDeviceLocation(on: center)
            } else {
                mapManager.recenter(on: center)
            }
        }
        // Map camera is locked once on first city center — do not refocus when city/sheet changes.
        .sheet(isPresented: $showDiscoveryPanel) {
            MapDiscoveryPanel(
                viewModel: viewModel,
                stackedSheet: $stackedSheet,
                detailStation: $detailStation,
                detailSheetHeight: $detailSheetHeight,
                browseListDetent: $browseListDetent,
                userName: userName,
                onSelectStationOnMap: { station in
                    openStationFromMap(station)
                }
            )
            .environmentObject(dependencies)
            .presentationDetents(MapBottomPanelMetrics.entryDetents)
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(MapBottomPanelMetrics.sheetCornerRadius)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.enabled(upThrough: MapBottomPanelMetrics.entryDetent))
            .presentationBackground(Color.white)
        }
        .confirmationDialog(String(localized: "Menu"), isPresented: $showMenu) {
            Button(String(localized: "All stations")) { stackedSheet = .browseList }
            Button(String(localized: "Enable location")) { viewModel.requestLocationAccess() }
            Button(String(localized: "Refresh data")) { viewModel.refresh() }
        }
    }

    /// Map, top bar, and FAB — fixed when the discovery sheet keyboard appears.
    private var mapChrome: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            locationFAB
        }
        .overlay(alignment: .top) {
            MapTopBar(
                cityName: viewModel.currentCityName,
                networkName: viewModel.currentNetworkName,
                onSettingsTap: { stackedSheet = .cityPicker }
            )
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        MapDiscoveryMapView(
            mapManager: mapManager,
            cameraLockKey: viewModel.selectedNetworkId,
            initialCenter: viewModel.mapFocusCoordinate,
            stations: viewModel.mapStations,
            selectedStationKey: (selectedStation ?? detailStation)?.favoriteKey,
            userLocation: viewModel.walkingRouteOrigin,
            onSelectStation: { station in
                openStationFromMap(station)
            },
            onVisibleRegionChange: { region in
                viewModel.updateVisibleMapRegion(region)
            }
        )
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var locationFAB: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    Task {
                        guard let center = await viewModel.focusCoordinateForLocationFAB() else { return }
                        if viewModel.usesCurrentLocationSelection {
                            mapManager.focusDeviceLocation(on: center)
                        } else {
                            mapManager.recenter(on: center)
                        }
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryGreen)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                }
                .padding(.trailing, 16)
                .padding(.bottom, fabBottomPadding)
                .animation(.easeInOut(duration: 0.25), value: fabBottomPadding)
            }
        }
        .accessibilityLabel(String(localized: "Recenter map"))
    }

    private var fabBottomPadding: CGFloat {
        fabObstructionHeight + MapBottomPanelMetrics.fabSpacingAbovePanel
    }

    /// Height of bottom UI covering the map (sheet stack from the bottom edge).
    private var fabObstructionHeight: CGFloat {
        if let secondaryPanel = stackedSheet?.secondaryPanel {
            return MapBottomPanelMetrics.stackedSecondaryHeight(
                for: secondaryPanel,
                detailContentHeight: detailSheetHeight
            )
        }
        if stackedSheet?.isBrowseListStyle == true {
            return MapBottomPanelMetrics.fabObstructionForBrowseList(detent: browseListDetent)
        }
        if showDiscoveryPanel {
            return MapBottomPanelMetrics.primaryPanelHeight
        }
        return 0
    }

    private var mapBottomObstructionHeight: CGFloat {
        if stackedSheet?.isBrowseListStyle == true {
            return MapBottomPanelMetrics.browseListPresentationHeight(for: browseListDetent)
        }
        return MapBottomPanelMetrics.mapBottomObstruction(
            primaryPanelHeight: MapBottomPanelMetrics.primaryPanelHeight,
            secondaryPanel: stackedSheet?.secondaryPanel,
            detailSheetHeight: detailSheetHeight
        )
    }

    private func openStationFromMap(_ station: MobilityStation) {
        selectedStation = station
        detailStation = station
        viewModel.prepareMapForStationSelection(station)
        mapManager.focus(on: station.coordinate)
        stackedSheet = .secondary(.stationDetail)
    }

}


// MARK: - Previews

#Preview("Map – Loaded") {
    MapDiscoveryView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas()
    )
    .previewDependencies()
}

#Preview("Map – Loading") {
    MapDiscoveryView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas(stations: [], loadState: .loading, locationSubtitle: "Loading…", userLocation: nil)
    )
    .previewDependencies()
}

#Preview("Map – Stale data") {
    MapDiscoveryView(
        dependencies: AppDependencies.previewForCanvas(),
        viewModel: .previewForCanvas(dataSource: .cache, isStale: true)
    )
    .previewDependencies()
}
