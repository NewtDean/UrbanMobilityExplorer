//
//  MapPanelStationDetailView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import SwiftUI

/// Station detail in the secondary stacked sheet.
struct MapPanelStationDetailView: View {
    @StateObject private var viewModel: StationDetailViewModel
    let distanceMeters: CLLocationDistance?
    @Binding var detailSheetHeight: CGFloat

    var showsCloseButton: Bool
    var onClose: (() -> Void)?
    var onFavoriteChanged: (() async -> Void)?

    init(
        station: MobilityStation,
        dependencies: AppDependencies,
        distanceMeters: CLLocationDistance?,
        detailSheetHeight: Binding<CGFloat>,
        showsCloseButton: Bool = false,
        onClose: (() -> Void)? = nil,
        onFavoriteChanged: (() async -> Void)? = nil
    ) {
        self.distanceMeters = distanceMeters
        _detailSheetHeight = detailSheetHeight
        _viewModel = StateObject(
            wrappedValue: StationDetailViewModel(station: station, dependencies: dependencies)
        )
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.onFavoriteChanged = onFavoriteChanged
    }

    var body: some View {
        MobilityStationDetailPanelView(
            station: viewModel.station.detailPanelDisplay(distanceMeters: distanceMeters),
            recommendationScore: viewModel.recommendationScore,
            isFavorite: viewModel.isFavorite,
            showsCloseButton: showsCloseButton,
            onClose: onClose,
            onToggleFavorite: {
                let saved = await viewModel.toggleFavorite()
                if saved {
                    await onFavoriteChanged?()
                }
                return saved
            },
            isScanAvailable: viewModel.station.rentalURL != nil,
            onScan: { viewModel.openRentalLink() }
        )
        .reportSheetContentHeight($detailSheetHeight)
        .task(id: viewModel.station.id) {
            await viewModel.onAppear()
        }
    }
}
