//
//  TextCheckmarkCell.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct TextCheckmarkCell: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(title)
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
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("Text checkmark cell") {
    VStack(spacing: 0) {
        TextCheckmarkCell(title: "London · Santander Cycles", isSelected: true, onTap: {})
        Divider()
        TextCheckmarkCell(title: "Paris · Vélib'", isSelected: false, onTap: {})
    }
    .padding(.horizontal, UIConstants.contentPadding)
}
#endif
