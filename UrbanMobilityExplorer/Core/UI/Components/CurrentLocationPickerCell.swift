//
//  CurrentLocationPickerCell.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// First row in Choose city: device location with resolved city name or “Unknown”.
struct CurrentLocationPickerCell: View {
    let cityTitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(StationDetailPanelColors.accentGreen)
                .frame(width: 28, alignment: .center)

            Text(cityTitle)
                .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                .foregroundStyle(
                    isSelected ? StationDetailPanelColors.accentGreen : StationDetailPanelColors.textPrimary
                )
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(StationDetailPanelColors.accentGreen)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityLabel(String(localized: "Current location"))
        .accessibilityValue(cityTitle)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("Current location cell") {
    VStack(spacing: 0) {
        CurrentLocationPickerCell(cityTitle: "London", isSelected: true, onTap: {})
        Divider()
        CurrentLocationPickerCell(cityTitle: "Unknown", isSelected: false, onTap: {})
    }
    .padding(.horizontal, UIConstants.contentPadding)
}
#endif
