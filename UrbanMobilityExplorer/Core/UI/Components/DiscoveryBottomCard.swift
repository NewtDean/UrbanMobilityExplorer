//
//  DiscoveryBottomCard.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Compact discovery entry: greeting + Bikes / Saved (fits entry sheet).
struct DiscoveryBottomCard: View {
    @ObservedObject var viewModel: StationListViewModel

    var userName: String
    var onBikesTap: () -> Void = {}
    var onFavoritesTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(userName)! 👋")
                .font(.title3.weight(.bold))
                .foregroundStyle(StationDetailPanelColors.textPrimary)
                .padding(.top, 34)

            Text("Where do you want to get start?")
                .font(.body)
                .foregroundStyle(StationDetailPanelColors.textSecondary)

            HStack(alignment: .top, spacing: 10) {
                CategoryCard(
                    icon: "bicycle",
                    title: String(localized: "Bike Stations"),
                    subtitle: String(localized: "Discover bike stations in your city"),
                    action: onBikesTap
                )
                CategoryCard(
                    icon: "heart.fill",
                    title: String(localized: "Your Favorite"),
                    subtitle: String(localized: "Check your favorite bike stations"),
                    action: onFavoritesTap
                )
            }
            .padding(.top, 10)

            DiscoveryCityWeatherRow(
                weather: viewModel.cityWeather,
                isLoading: viewModel.isLoadingCityWeather
            )
            .padding(.top, 4)
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - City weather

private struct DiscoveryCityWeatherRow: View {
    let weather: WeatherSnapshot?
    let isLoading: Bool

    private let advicePlaceholder = "—"

    var body: some View {
        weatherCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    weatherLeadingSymbol
                        .frame(width: 22, height: 22)

                    Text(summaryText)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 24, alignment: .leading)

                Text(adviceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var weatherLeadingSymbol: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if let weather {
            Image(systemName: weather.presentation.symbolName)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(weather.presentation.tint)
        } else {
            Image(systemName: "cloud")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var summaryText: String {
        if isLoading { return String(localized: "Loading weather…") }
        return weather?.summary ?? "—"
    }

    private var adviceText: String {
        if isLoading { return advicePlaceholder }
        return weather?.mobilityAdvice ?? advicePlaceholder
    }

    private var accessibilitySummary: String {
        if isLoading {
            return String(localized: "Loading weather…")
        }
        if let weather {
            return "\(weather.summary). \(weather.mobilityAdvice)"
        }
        return advicePlaceholder
    }

    @ViewBuilder
    private func weatherCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .categoryCard()
    }
}

// MARK: - Category card

private struct CategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 56, height: 56)
                .background(AppTheme.primaryGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.top, 6)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .categoryCard()
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .onTapGesture(perform: action)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Discovery Card") {
    struct Host: View {
        @StateObject private var viewModel = StationListViewModel.previewForCanvas()

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.gray.opacity(0.2).ignoresSafeArea()
                DiscoveryBottomCard(
                    viewModel: viewModel,
                    userName: UIConstants.defaultGreetingName,
                    onBikesTap: {},
                    onFavoritesTap: {}
                )
                .frame(height: MapBottomPanelMetrics.entryPanelHeight)
                .background(Color.white)
            }
        }
    }
    return Host()
}
