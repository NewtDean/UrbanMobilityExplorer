//
//  FavoriteNetwork.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class FavoriteNetwork {
    @Attribute(.unique) var networkId: String
    var savedAt: Date

    init(networkId: String, savedAt: Date = Date()) {
        self.networkId = networkId
        self.savedAt = savedAt
    }
}
