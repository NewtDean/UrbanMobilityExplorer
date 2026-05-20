//
//  StationMapMarker.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct StationMapMarker: View {
    let bikeCount: Int
    let isSelected: Bool

    var body: some View {
        ZStack {
            Image(decorative: isSelected ? "annotation_selected" : "annotation")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isSelected ? 72 : 64, height: isSelected ? 72 : 64)
            
            if bikeCount > 0 {
                Text("\(bikeCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Circle().fill(.red))
                    .offset(x: 14, y: -14)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .accessibilityLabel(String(localized: "\(bikeCount) bikes available"))
    }
}

#Preview("Map Markers") {
    HStack(spacing: 28) {
        StationMapMarker(bikeCount: 8, isSelected: false)
        StationMapMarker(bikeCount: 3, isSelected: true)
        StationMapMarker(bikeCount: 0, isSelected: false)
    }
    .padding(40)
    .background(Color(.systemGroupedBackground))
}
