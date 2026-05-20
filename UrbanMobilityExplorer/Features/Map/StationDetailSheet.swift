//
//  StationDetailSheet.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import CoreLocation
import SwiftUI

/// Bottom sheet for station detail on the map screen.
struct StationDetailSheet: View {
    @StateObject private var viewModel: StationDetailViewModel
    let distanceMeters: CLLocationDistance?
    var onDismiss: () -> Void

    init(
        station: MobilityStation,
        dependencies: AppDependencies,
        distanceMeters: CLLocationDistance?,
        onDismiss: @escaping () -> Void,
        viewModel: StationDetailViewModel? = nil
    ) {
        self.distanceMeters = distanceMeters
        _viewModel = StateObject(
            wrappedValue: viewModel ?? StationDetailViewModel(station: station, dependencies: dependencies)
        )
        self.onDismiss = onDismiss
    }

    var body: some View {
        MobilityStationDetailPanelView(
            station: viewModel.station.detailPanelDisplay(distanceMeters: distanceMeters),
            recommendationScore: viewModel.recommendationScore,
            isFavorite: viewModel.isFavorite,
            showsCloseButton: true,
            onClose: onDismiss,
            onToggleFavorite: { await viewModel.toggleFavorite() },
            isScanAvailable: viewModel.station.rentalURL != nil,
            onScan: { viewModel.openRentalLink() }
        )
        .task {
            await viewModel.onAppear()
        }
    }
}

#if DEBUG
#Preview("Detail Sheet") {
    StationDetailSheet(
        station: PreviewData.station,
        dependencies: AppDependencies.previewForCanvas(),
        distanceMeters: 4_500,
        onDismiss: {},
        viewModel: .previewForCanvas()
    )
    .background(Color.gray.opacity(0.2))
}
#endif
