//
//  CityPickerSheet.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Presents `CountrySelectionView` for choosing a CityBikes network from `networks.json`.
struct CityPickerSheet: View {
    @ObservedObject var viewModel: StationListViewModel
    let networks: [MobilityNetwork]

    @Environment(\.dismiss) private var dismiss

    private var selectedNetwork: MobilityNetwork {
        networks.first { $0.id == viewModel.selectedNetworkId }
            ?? MobilityNetwork(
                id: viewModel.selectedNetworkId,
                name: viewModel.selectedNetworkId,
                city: nil,
                country: nil
            )
    }

    var body: some View {
        NavigationStack {
            CountrySelectionView(
                selectedNetwork: selectedNetwork,
                networks: networks,
                isCurrentLocationSelected: viewModel.usesCurrentLocationSelection,
                currentLocationCityTitle: viewModel.currentLocationPickerTitle,
                onSelectCurrentLocation: {
                    Task {
                        await viewModel.selectCurrentLocation()
                        dismiss()
                    }
                },
                onSelect: { network in
                    viewModel.selectCity(network)
                    dismiss()
                }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(StationDetailPanelColors.accentGreen)
                    }
                }
            }
        }
        .task {
            await viewModel.refreshCurrentLocationPickerTitle()
        }
    }
}

#if DEBUG
#Preview("City Picker") {
    CityPickerSheet(
        viewModel: .previewForCanvas(),
        networks: PreviewData.networks
    )
}
#endif
