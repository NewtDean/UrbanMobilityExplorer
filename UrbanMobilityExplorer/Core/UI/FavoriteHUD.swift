//
//  FavoriteHUD.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import ProgressHUD
import SwiftUI

/// Shown only when favorite persistence fails and optimistic UI is reverted.
enum FavoriteHUD {
    private static let heartPink = Color.pink
    private static let dismissDelay: TimeInterval = 1.35

    /// - Parameter wasAdding: `true` if the user tried to add a favorite; `false` if they tried to remove one.
    @MainActor
    static func showSaveFailed(wasAdding: Bool) {
        let message = wasAdding
            ? String(localized: "Add to favorites failed")
            : String(localized: "Remove from favorites failed")
        let symbol = wasAdding ? "heart.fill" : "heart.slash"

        // Defer so we are not reparenting HUD views during an active context-menu dismissal.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            ProgressHUD.colorAnimation = heartPink
            ProgressHUD.mediaSize = 56
            ProgressHUD.symbol(message, name: symbol, interaction: true, delay: dismissDelay)
        }
    }
}
