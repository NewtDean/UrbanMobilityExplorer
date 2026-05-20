//
//  CountrySelectionView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// City / bike-share network picker (UI reused from Beatbot country selection; data from `networks.json`).
struct CountrySelectionView: View {

    private enum LoadState {
        case loading
        case success
        case failed
    }

    @State private var networks: [MobilityNetwork]
    @State private var keyword = ""
    @State private var selectedNetwork: MobilityNetwork
    @State private var loadState: LoadState

    private let prefetchedNetworks: [MobilityNetwork]
    private let isCurrentLocationSelected: Bool
    private let currentLocationCityTitle: String
    private var onSelectCurrentLocation: (() -> Void)?
    private var onSelect: ((MobilityNetwork) -> Void)?

    init(
        selectedNetwork: MobilityNetwork,
        networks: [MobilityNetwork] = [],
        isCurrentLocationSelected: Bool = false,
        currentLocationCityTitle: String = String(localized: "Unknown"),
        onSelectCurrentLocation: (() -> Void)? = nil,
        onSelect: ((MobilityNetwork) -> Void)? = nil
    ) {
        self._selectedNetwork = State(initialValue: selectedNetwork)
        self.prefetchedNetworks = networks
        self._networks = State(initialValue: networks)
        self._loadState = State(initialValue: networks.isEmpty ? .loading : .success)
        self.isCurrentLocationSelected = isCurrentLocationSelected
        self.currentLocationCityTitle = currentLocationCityTitle
        self.onSelectCurrentLocation = onSelectCurrentLocation
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { _ in
            switch loadState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed:
                ContentUnavailableView(
                    String(localized: "Unable to load cities"),
                    systemImage: "network.slash",
                    description: Text(String(localized: "Could not read the bundled networks catalog."))
                )

            case .success:
                if displayedNetworks.isEmpty && !cleanedKeyword.isEmpty {
                    ContentUnavailableView.search(text: cleanedKeyword)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: .zero) {
                            if showsCurrentLocationRow {
                                CurrentLocationPickerCell(
                                    cityTitle: currentLocationCityTitle,
                                    isSelected: isCurrentLocationSelected,
                                    onTap: { onSelectCurrentLocation?() }
                                )
                                Divider()
                            }

                            ForEach(displayedNetworks) { network in
                                TextCheckmarkCell(
                                    title: network.selectionTitle,
                                    isSelected: !isCurrentLocationSelected && network.id == selectedNetwork.id
                                ) {
                                    selectedNetwork = network
                                    onSelect?(network)
                                }

                                Divider()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, UIConstants.contentPadding)
                    }
                }
            }
        }
        .searchable(
            text: $keyword,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "Search city or network")
        )
        .navigationTitle(String(localized: "Choose city"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadNetworksIfNeeded()
        }
    }
}

// MARK: - Private

extension CountrySelectionView {

    private var cleanedKeyword: String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Current location is always the first row when not filtering the list.
    private var showsCurrentLocationRow: Bool {
        cleanedKeyword.isEmpty
    }

    private var displayedNetworks: [MobilityNetwork] {
        guard !cleanedKeyword.isEmpty else { return networks }
        return networks.filter { $0.matchesSearch(cleanedKeyword) }
    }

    @MainActor
    private func loadNetworksIfNeeded() async {
        guard networks.isEmpty else {
            syncSelection(with: networks)
            loadState = .success
            return
        }

        if !prefetchedNetworks.isEmpty {
            applyLoadedNetworks(prefetchedNetworks)
            return
        }

        loadState = .loading
        let loaded = (try? LocalNetworksProvider())?.allNetworks ?? []

        guard !loaded.isEmpty else {
            loadState = .failed
            return
        }
        applyLoadedNetworks(loaded)
    }

    private func applyLoadedNetworks(_ loaded: [MobilityNetwork]) {
        networks = loaded
        syncSelection(with: loaded)
        loadState = .success
    }

    private func syncSelection(with list: [MobilityNetwork]) {
        if let match = list.first(where: { $0.id == selectedNetwork.id }) {
            selectedNetwork = match
        }
    }
}

#if DEBUG
#Preview("Country selection") {
    NavigationStack {
        CountrySelectionView(
            selectedNetwork: PreviewData.networks[0],
            networks: PreviewData.networks,
            isCurrentLocationSelected: false,
            currentLocationCityTitle: "London",
            onSelectCurrentLocation: {},
            onSelect: { _ in }
        )
    }
}
#endif
