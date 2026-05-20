//
//  MobilityStationDetailPanelView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct MobilityStationDetailPanelView: View {
    let station: MobilityStationDetailDisplay
    var recommendationScore: Double?
    var isFavorite: Bool = false
    var showsCloseButton: Bool = true
    var onClose: (() -> Void)?
    /// Persist favorite; return `false` to revert optimistic UI and show an error alert.
    var onToggleFavorite: (() async -> Bool)?
    var isScanAvailable: Bool = false
    var onScan: (() -> Void)?

    @State private var displayFavorite: Bool
    @State private var showReportAlert = false

    init(
        station: MobilityStationDetailDisplay,
        recommendationScore: Double? = nil,
        isFavorite: Bool = false,
        showsCloseButton: Bool = true,
        onClose: (() -> Void)? = nil,
        onToggleFavorite: (() async -> Bool)? = nil,
        isScanAvailable: Bool = false,
        onScan: (() -> Void)? = nil
    ) {
        self.station = station
        self.recommendationScore = recommendationScore
        self.isFavorite = isFavorite
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        self.onToggleFavorite = onToggleFavorite
        self.isScanAvailable = isScanAvailable
        self.onScan = onScan
        _displayFavorite = State(initialValue: isFavorite)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection
        }
        .onChange(of: isFavorite) { _, newValue in
            displayFavorite = newValue
        }
        .alert(String(localized: "Report issues"), isPresented: $showReportAlert) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "Thanks for reporting an issue at \(station.displayName). Our team will review it shortly."
                )
            )
        }
    }

    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        stationTitleText
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                        if displayFavorite {
                            Image(systemName: "heart.fill")
                                .font(.body)
                                .foregroundStyle(.pink)
                                .accessibilityLabel(String(localized: "Favorite"))
                                .offset(y: 5)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .frame(width: 20, height: 20)
                            .foregroundStyle(StationDetailPanelColors.textSecondary)

                        Text(station.distance)
                            .font(.subheadline)
                            .foregroundStyle(StationDetailPanelColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    
                    if let recommendationScore {
                        HStack(spacing: 6) {
                            StarRatingView(score: recommendationScore)
                                .font(.caption)

                            Text(StarRatingDisplay.formattedStarRating(score: recommendationScore))
                                .font(.subheadline)
                                .foregroundStyle(StationDetailPanelColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 16)

                Image(decorative: "Divvy-Bike_new_0119_v3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 80)
                    .layoutPriority(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            if station.isRentingAvailable || station.isReturningAvailable {
                Text("Available for 24 hours")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(StationDetailPanelColors.textPrimary)
            }

            HStack(spacing: 16) {
                ConnectionChip(label: station.connectionType, style: .rapid)
                ConnectionChip(label: station.powerKW, style: .power)
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .top, spacing: 0) {
                StatColumn(label: "E-bikes", value: station.ebikes, valueColor: StationDetailPanelColors.textPrimary)
                StatColumn(
                    label: "Renting",
                    value: station.rentingText,
                    valueColor: station.isRentingAvailable ? StationDetailPanelColors.accentGreen : .red
                )
                StatColumn(
                    label: "Returning",
                    value: station.returningText,
                    valueColor: station.isReturningAvailable ? StationDetailPanelColors.accentGreen : .red
                )
            }

            HStack {
                Button {
                    onScan?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(Color.white)

                        Text("Scan")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(StationDetailPanelColors.accentGreen)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .disabled(!isScanAvailable)
                .opacity(isScanAvailable ? 1 : 0.45)
                .accessibilityLabel(String(localized: "Scan QR code"))
                
                Button {
                    Task { await toggleFavorite() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: displayFavorite ? "heart.slash" : "heart")
                            .foregroundStyle(displayFavorite ? Color.white : Color.pink)

                        Text(displayFavorite ? "Unlike" : "Like it!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(displayFavorite ? Color.white : Color.pink)
                            .padding(.vertical, 14)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(displayFavorite ? Color.pink : Color.white)
                .overlay {
                    Capsule()
                        .stroke(displayFavorite ? Color.clear : Color.pink, lineWidth: 1.5)
                }
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .disabled(onToggleFavorite == nil)
                .accessibilityLabel(displayFavorite ? "Unlike" : "Like it!")
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stationTitleText: some View {
        Text(station.displayName)
            .font(.title2.weight(.bold))
            .foregroundStyle(StationDetailPanelColors.textPrimary)
    }

    private func toggleFavorite() async {
        guard let onToggleFavorite else { return }

        let previous = displayFavorite
        displayFavorite.toggle()

        let saved = await onToggleFavorite()
        if !saved {
            displayFavorite = previous
        }
    }
}

// MARK: - Subviews

enum StationDetailPanelColors {
    static let headerBackground = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let accentGreen = Color(red: 0.18, green: 0.72, blue: 0.45)
    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.57)
}

private struct ConnectionChip: View {
    enum Style {
        case rapid
        case power
    }

    let label: String
    let style: Style

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style == .rapid ? "bicycle" : "contact.sensor")
                .frame(width: 24, height: 24)
                .foregroundStyle(StationDetailPanelColors.accentGreen)

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StationDetailPanelColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .overlay {
            Capsule()
                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
        }
        .clipShape(Capsule())
    }
}

private struct StatColumn: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(StationDetailPanelColors.textSecondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Mobility Station Panel - is Favorite") {
    MobilityStationDetailPanelView(
        station: .preview,
        recommendationScore: 82,
        isFavorite: true
    )
    .padding(.bottom, 8)
    .background(Color.gray.opacity(0.2))
}

#Preview("Mobility Station Panel - is not Favorite") {
    MobilityStationDetailPanelView(
        station: .preview,
        recommendationScore: 82,
        isFavorite: false
    )
    .padding(.bottom, 8)
    .background(Color.gray.opacity(0.2))
}
