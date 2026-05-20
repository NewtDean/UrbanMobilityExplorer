//
//  MapDiscoveryPanel.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Discovery home in the primary sheet; secondary flows present a **nested** sheet here (SwiftUI allows one sheet per view).
struct MapDiscoveryPanel: View {
    @ObservedObject var viewModel: StationListViewModel
    @EnvironmentObject private var dependencies: AppDependencies

    @Binding var stackedSheet: MapStackedSheet?
    @Binding var detailStation: MobilityStation?
    @Binding var detailSheetHeight: CGFloat
    @Binding var browseListDetent: PresentationDetent

    let userName: String
    var onSelectStationOnMap: (MobilityStation) -> Void

    var body: some View {
        NavigationStack {
            discoveryRoot
                .toolbarVisibility(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .bottomBar)
        }
        .background(Color.clear)
        .sheet(item: $stackedSheet) { sheet in
            stackedSheetContent(sheet)
        }
    }

    @ViewBuilder
    private var discoveryRoot: some View {
        VStack(spacing: 0) {
            DiscoveryBottomCard(
                viewModel: viewModel,
                userName: userName,
                onBikesTap: { stackedSheet = .browseList },
                onFavoritesTap: { stackedSheet = .favoritesList }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
    }

    @ViewBuilder
    private func stackedSheetContent(_ sheet: MapStackedSheet) -> some View {
        switch sheet {
        case .secondary(let panel):
            MapSecondaryPanelSheet(
                panel: panel,
                secondaryPanel: secondaryPanelBinding,
                detailStation: $detailStation,
                detailSheetHeight: $detailSheetHeight,
                viewModel: viewModel,
                onSelectStationOnMap: onSelectStationOnMap
            )
            .environmentObject(dependencies)

        case .cityPicker:
            CityPickerSheet(
                viewModel: viewModel,
                networks: viewModel.availableCities
            )

        case .browseList:
            StationBrowseSheet(viewModel: viewModel, dependencies: dependencies) { station in
                onSelectStationOnMap(station)
            }
            .browseListSheetPresentation(detent: $browseListDetent)

        case .favoritesList:
            FavoritesBrowseSheet(viewModel: viewModel) { station in
                onSelectStationOnMap(station)
            }
            .environmentObject(dependencies)
            .browseListSheetPresentation(detent: $browseListDetent)
        }
    }

    private var secondaryPanelBinding: Binding<MapSecondaryPanel?> {
        Binding(
            get: { stackedSheet?.secondaryPanel },
            set: { newValue in
                if let newValue {
                    stackedSheet = .secondary(newValue)
                } else {
                    stackedSheet = nil
                }
            }
        )
    }
}
