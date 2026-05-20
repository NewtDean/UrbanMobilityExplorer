//
//  RootTabView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var dependencies: AppDependencies

    var body: some View {
        MapDiscoveryView(dependencies: dependencies)
            .tint(AppTheme.primaryGreen)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview("Root") {
    RootTabView()
        .previewDependencies()
        .preferredColorScheme(.light)
}
