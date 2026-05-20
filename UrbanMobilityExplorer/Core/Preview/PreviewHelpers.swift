//
//  PreviewHelpers.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

#if DEBUG
extension View {
    /// Injects preview `AppDependencies` for SwiftUI canvas.
    func previewDependencies(_ dependencies: AppDependencies? = nil) -> some View {
        environmentObject(dependencies ?? AppDependencies.previewForCanvas())
    }
}

enum PreviewCanvas {
    static let background = Color(.systemGroupedBackground)
}
#endif
