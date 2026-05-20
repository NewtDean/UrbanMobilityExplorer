//
//  StationSortMenu.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Sort control for station lists (English menu labels).
struct StationSortMenu: View {
    @Binding var sortOption: StationSortOption

    var body: some View {
        Menu {
            Picker("Sort", selection: $sortOption) {
                ForEach(StationSortOption.allCases) { option in
                    Text(option.menuTitle).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
        .accessibilityLabel("Sort stations")
    }
}
