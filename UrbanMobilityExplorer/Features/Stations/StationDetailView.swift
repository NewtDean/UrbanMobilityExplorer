//
//  StationDetailView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import MapKit
import SwiftUI

struct StationDetailView: View {
    @StateObject private var viewModel: StationDetailViewModel
    private let distanceMeters: CLLocationDistance?

    init(
        station: MobilityStation,
        dependencies: AppDependencies,
        distanceMeters: CLLocationDistance? = nil
    ) {
        self.distanceMeters = distanceMeters
        _viewModel = StateObject(wrappedValue: StationDetailViewModel(station: station, dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mapSection
                availabilitySection
                recommendationSection
                weatherSection
                locationSection
            }
            .padding()
        }
        .navigationTitle(viewModel.station.locationDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? .pink : .primary)
                }
                .accessibilityLabel(
                    viewModel.isFavorite
                        ? String(localized: "Unlike")
                        : String(localized: "Like it!")
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Directions"), action: viewModel.openInMaps)
            }
        }
        .task { await viewModel.onAppear() }
    }

    private var mapSection: some View {
        Map(coordinateRegion: .constant(viewModel.mapRegion), annotationItems: [viewModel.station]) { station in
            MapMarker(coordinate: station.coordinate, tint: .blue)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(String(localized: "Map showing \(viewModel.station.locationDisplayName)"))
    }

    private var availabilitySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label(viewModel.station.availabilityLabel, systemImage: "bicycle")
                    .font(.title3.bold())
                HStack {
                    statBlock(title: String(localized: "Bikes"), value: viewModel.station.freeBikes)
                    statBlock(title: String(localized: "Free docks"), value: viewModel.station.emptySlots)
                    statBlock(title: String(localized: "Total"), value: viewModel.station.totalSlots)
                }
                if let updated = viewModel.station.lastUpdated {
                    Text(String(localized: "Updated \(updated.formatted(date: .abbreviated, time: .shortened))"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(String(localized: "Availability"), systemImage: "chart.bar")
        }
    }

    private var recommendationSection: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading) {
                    Text(String(localized: "Usefulness score"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f / 100", min(100, viewModel.recommendationScore)))
                        .font(.title.bold())
                        .monospacedDigit()
                }
                Spacer()
                StarRatingView(score: viewModel.recommendationScore)
                    .font(.title3)
            }
        } label: {
            Label(String(localized: "Recommendation"), systemImage: "sparkles")
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var weatherSection: some View {
        GroupBox {
            if viewModel.isLoadingWeather {
                ProgressView(String(localized: "Loading weather…"))
            } else if let weather = viewModel.weather {
                Label(weather.summary, systemImage: "cloud.sun")
            } else if let error = viewModel.weatherError {
                Text(error).font(.caption).foregroundStyle(.secondary)
            }
        } label: {
            Label(String(localized: "Weather"), systemImage: "cloud")
        }
    }

    private var locationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                if let address = viewModel.station.address {
                    Text(address)
                }
                Text(String(format: "%.5f, %.5f", viewModel.station.latitude, viewModel.station.longitude))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(String(localized: "Location"), systemImage: "mappin.and.ellipse")
        }
    }

    private func statBlock(title: String, value: Int?) -> some View {
        VStack {
            Text("\(value ?? 0)")
                .font(.title2.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value ?? 0)")
    }
}

#Preview("Station Detail") {
    NavigationStack {
        StationDetailView(station: PreviewData.station, dependencies: AppDependencies.previewForCanvas())
    }
    .previewDependencies()
}
