//
//  StateViews.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct LoadingStateView: View {
    let message: String

    init(_ message: String = String(localized: "Loading stations…")) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .accessibilityLabel(message)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(String(localized: "Something went wrong"))
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button(String(localized: "Try Again"), action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StaleDataBanner: View {
    let source: DataSourceKind
    let isStale: Bool

    var body: some View {
        if isStale || source != .live {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                Text(bannerText)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5))
            .accessibilityElement(children: .combine)
        }
    }

    private var bannerText: String {
        switch source {
        case .live: String(localized: "Data may be outdated")
        case .cache: String(localized: "Showing cached data")
        case .bundled: String(localized: "Offline sample data")
        }
    }
}

#Preview("Loading") {
    LoadingStateView()
}

#Preview("Empty") {
    EmptyStateView(
        title: "No Stations",
        systemImage: "bicycle",
        message: "Try another network or adjust filters."
    )
}

#Preview("Error") {
    ErrorStateView(message: "Network is unavailable.", retry: {})
}

#Preview("Stale Banner") {
    VStack {
        StaleDataBanner(source: .cache, isStale: true)
        StaleDataBanner(source: .bundled, isStale: true)
    }
}
