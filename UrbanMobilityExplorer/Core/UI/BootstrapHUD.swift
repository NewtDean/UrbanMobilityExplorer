//
//  BootstrapHUD.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import ProgressHUD
import SwiftUI

enum BootstrapHUD {
    @MainActor
    static func showLoading() {
        ProgressHUD.colorAnimation = StationDetailPanelColors.accentGreen
        ProgressHUD.animate(String(localized: "Finding your city…"), interaction: false)
    }

    @MainActor
    static func dismiss() {
        ProgressHUD.dismiss()
    }
}
