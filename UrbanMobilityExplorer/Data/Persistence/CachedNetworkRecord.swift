//
//  CachedNetworkRecord.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class CachedNetworkRecord {
    @Attribute(.unique) var id: String
    var name: String
    var city: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    var cachedAt: Date

    init(from network: MobilityNetwork, cachedAt: Date) {
        id = network.id
        name = network.name
        city = network.city
        country = network.country
        latitude = network.latitude
        longitude = network.longitude
        self.cachedAt = cachedAt
    }

    func toDomain() -> MobilityNetwork {
        MobilityNetwork(
            id: id,
            name: name,
            city: city,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
    }
}
