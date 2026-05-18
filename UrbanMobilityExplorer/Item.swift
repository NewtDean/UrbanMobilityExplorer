//
//  Item.swift
//  UrbanMobilityExplorer
//
//  Created by Newt on 2026/5/18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
