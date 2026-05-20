//
//  MapTopBar.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Custom map header with gradient frosted-glass background (non-interactive backdrop).
struct MapTopBar: View {
    let cityName: String
    let networkName: String
    var onProfileTap: (() -> Void)?
    var onSettingsTap: () -> Void

    private var resolvedCity: String {
        cityName.isEmpty ? String(localized: "Loading…") : cityName
    }

    private var resolvedNetwork: String? {
        let trimmed = networkName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                MapTopBarGlassBackground()
                    .allowsHitTesting(false)
                
                HStack(spacing: 12) {
                    Button {
                        onProfileTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 48, height: 48)
                                
                            Image(decorative: "avatar")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(
                                    Circle()
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Profile"))
                    
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .frame(width: 20, height: 20)
                                .foregroundStyle(StationDetailPanelColors.accentGreen)
                            
                            Text(String(localized: "Your location"))
                                .font(.footnote)
                                .foregroundStyle(StationDetailPanelColors.textPrimary.opacity(0.7))
                        }
                        
                        Text(resolvedCity)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: onSettingsTap) {
                        Image(systemName: "building.2")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.primary)
                            .background {
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 44, height: 44)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Choose city"))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .padding(.top, 4)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/// Frosted material + gradient tint, faded out toward the bottom via mask.
private struct MapTopBarGlassBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.14),
                    Color.white.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .mask {
            LinearGradient(
                colors: [.black, .black.opacity(0.92), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview("Map Top Bar") {
    ZStack(alignment: .top) {
        MapDiscoveryView(dependencies: AppDependencies.previewForCanvas(), viewModel: .previewForCanvas())
            .previewDependencies()
            .navigationBarHidden(true)
        MapTopBar(cityName: "London", networkName: "Santander Cycles", onSettingsTap: {})
    }
}
