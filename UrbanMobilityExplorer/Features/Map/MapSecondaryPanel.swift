//
//  MapSecondaryPanel.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Sheet presented **on top of** the discovery panel (one stacked sheet at a time).
enum MapStackedSheet: Identifiable, Hashable {
    case secondary(MapSecondaryPanel)
    case cityPicker
    case browseList
    case favoritesList

    var id: String {
        switch self {
        case .secondary(let panel):
            panel.id
        case .cityPicker:
            "cityPicker"
        case .browseList:
            "browseList"
        case .favoritesList:
            "favoritesList"
        }
    }

    var secondaryPanel: MapSecondaryPanel? {
        if case .secondary(let panel) = self { return panel }
        return nil
    }

    var isBrowseListStyle: Bool {
        switch self {
        case .browseList, .favoritesList:
            true
        default:
            false
        }
    }
}

/// Second-tier sheet stacked above the discovery sheet (station detail only).
enum MapSecondaryPanel: Identifiable, Hashable {
    /// Station payload lives in `detailStation` so switching pins does not dismiss the sheet.
    case stationDetail

    var id: String {
        "stationDetail"
    }
}
