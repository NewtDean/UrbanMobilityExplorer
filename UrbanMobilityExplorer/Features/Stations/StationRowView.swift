//
//  StationRowView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI
import CoreLocation

struct StationRowView: View {
    let station: MobilityStation
    let isFavorite: Bool
    let distanceMeters: CLLocationDistance?
    let recommendationScore: Double?
    var onSelect: (() -> Void)?
    var onFavoriteChange: (() -> Void)?

    @EnvironmentObject private var dependencies: AppDependencies
    @State private var displayFavorite: Bool
    @State private var showReportAlert = false

    init(
        station: MobilityStation,
        isFavorite: Bool,
        distanceMeters: CLLocationDistance? = nil,
        recommendationScore: Double? = nil,
        onSelect: (() -> Void)? = nil,
        onFavoriteChange: (() -> Void)? = nil
    ) {
        self.station = station
        self.isFavorite = isFavorite
        self.distanceMeters = distanceMeters
        self.recommendationScore = recommendationScore
        self.onSelect = onSelect
        self.onFavoriteChange = onFavoriteChange
        _displayFavorite = State(initialValue: isFavorite)
    }

    private var distanceText: String {
        station.detailPanelDisplay(distanceMeters: distanceMeters).distance
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectableContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect?()
                }
            
            HStack {
                    HStack {
                        StarRatingView(score: recommendationScore ?? 0)
                            .font(.caption)
                        
                        Text(StarRatingDisplay.formattedStarRating(score: recommendationScore ?? 0))
                            .font(.subheadline)
                            .foregroundStyle(StationDetailPanelColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                
                Spacer()
                
                rowMenu
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: isFavorite) { _, newValue in
            displayFavorite = newValue
        }
        .alert(String(localized: "Report issues"), isPresented: $showReportAlert) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "Thanks for reporting an issue at \(station.locationDisplayName). Our team will review it shortly."
                )
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(
            onSelect != nil
                ? String(localized: "Double tap for station details")
                : ""
        )
    }

    /// Main text + bike image — entire region opens detail (not only labels).
    private var selectableContent: some View {
        HStack(alignment: .top, spacing: 12) {
            mainColumn
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(decorative: "Divvy-Bike_new_0119_v3")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 60)
                .accessibilityHidden(true)
        }
    }

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 6) {
                Text(station.locationDisplayName)
                    .font(.headline)
                    .lineLimit(2)
                if displayFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .accessibilityLabel(String(localized: "Favorite"))
                        .offset(y: 2)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "bicycle")
                    .frame(height: 14)
                    .foregroundStyle(StationDetailPanelColors.accentGreen)

                Text("\(station.freeBikes ?? 0)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StationDetailPanelColors.textSecondary)

                Text("·")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StationDetailPanelColors.textSecondary)

                Image(systemName: "contact.sensor")
                    .frame(height: 14)
                    .foregroundStyle(StationDetailPanelColors.accentGreen)

                Text("\(station.emptySlots ?? 0)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StationDetailPanelColors.textSecondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(StationDetailPanelColors.textSecondary)

                Text(distanceText)
                    .font(.subheadline)
                    .foregroundStyle(StationDetailPanelColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rowMenu: some View {
        Menu {
            Button {
                Task { await toggleFavorite() }
            } label: {
                Label(
                    displayFavorite
                        ? String(localized: "Unlike")
                        : String(localized: "Like it!"),
                    systemImage: displayFavorite ? "heart.slash" : "heart"
                )
            }

            Button {
                showReportAlert = true
            } label: {
                Label(String(localized: "Report issues"), systemImage: "exclamationmark.bubble")
            }
        } label: {
            Image(systemName: "ellipsis")
                .contentShape(Rectangle())
                .foregroundStyle(StationDetailPanelColors.textSecondary)
        }
        .accessibilityLabel(String(localized: "More options"))
    }

    private func toggleFavorite() async {
        let previous = displayFavorite
        let isRemoving = previous
        displayFavorite.toggle()

        guard let repo = dependencies.favoritesRepository else {
            displayFavorite = previous
            return
        }

        do {
            try await repo.toggleFavorite(station)
            if isRemoving {
                try? await Task.sleep(for: .milliseconds(350))
            }
            onFavoriteChange?()
        } catch {
            displayFavorite = previous
            FavoriteHUD.showSaveFailed(wasAdding: !previous)
        }
    }
}

#Preview("Row – With score") {
    List {
        StationRowView(
            station: PreviewData.station,
            isFavorite: true,
            distanceMeters: 450,
            recommendationScore: 82,
            onSelect: {}
        )
    }
    .previewDependencies()
}

#Preview("Row – Plain") {
    List {
        StationRowView(
            station: PreviewData.stationLowAvailability,
            isFavorite: false,
            distanceMeters: nil,
            recommendationScore: nil,
            onSelect: {}
        )
    }
    .previewDependencies()
}
