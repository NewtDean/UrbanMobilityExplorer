//
//  MapSecondaryPanelSheet.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Native bottom sheet stacked above the discovery sheet (station detail).
struct MapSecondaryPanelSheet: View {
    let panel: MapSecondaryPanel
    @Binding var secondaryPanel: MapSecondaryPanel?
    @Binding var detailStation: MobilityStation?
    @Binding var detailSheetHeight: CGFloat
    @ObservedObject var viewModel: StationListViewModel
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.dismiss) private var dismiss

    var onSelectStationOnMap: (MobilityStation) -> Void

    var body: some View {
        Group {
            if let station = detailStation {
                MapPanelStationDetailView(
                    station: station,
                    dependencies: dependencies,
                    distanceMeters: viewModel.distanceMeters(for: station),
                    detailSheetHeight: $detailSheetHeight,
                    showsCloseButton: true,
                    onClose: { dismiss() },
                    onFavoriteChanged: { await viewModel.refreshFavoriteKeys() }
                )
                .id(stationDetailIdentity(station))
            }
        }
        .background(Color.white)
        .presentationDetents([detailDetent])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(MapBottomPanelMetrics.sheetCornerRadius)
        .presentationBackgroundInteraction(.enabled(upThrough: detailDetent))
        .presentationContentInteraction(.scrolls)
        .presentationBackground(Color.white)
        .animation(.easeInOut(duration: 0.25), value: detailSheetHeight)
    }

    private var detailDetent: PresentationDetent {
        MapBottomPanelMetrics.detailDetent(height: detailSheetHeight)
    }

    private func stationDetailIdentity(_ station: MobilityStation) -> String {
        "\(station.networkId)-\(station.id)"
    }
}
