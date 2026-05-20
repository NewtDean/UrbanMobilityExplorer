//
//  FavoriteStation.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class FavoriteStation {
    @Attribute(.unique) var compoundKey: String
    var stationId: String
    var networkId: String
    var name: String
    var latitude: Double
    var longitude: Double
    var freeBikes: Int?
    var emptySlots: Int?
    var totalSlots: Int?
    var address: String?
    var renting: Bool?
    var returning: Bool?
    var ebikes: Int?
    var savedAt: Date

    init(from station: MobilityStation, savedAt: Date = Date()) {
        self.compoundKey = station.favoriteKey
        self.stationId = station.id
        self.networkId = station.networkId
        self.name = station.name
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.freeBikes = station.freeBikes
        self.emptySlots = station.emptySlots
        self.totalSlots = station.totalSlots
        self.address = station.address
        self.renting = station.renting
        self.returning = station.returning
        self.ebikes = station.ebikes
        self.savedAt = savedAt
    }

    func toDomain() -> MobilityStation {
        MobilityStation(
            id: stationId,
            networkId: networkId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            freeBikes: freeBikes,
            emptySlots: emptySlots,
            totalSlots: totalSlots,
            lastUpdated: savedAt,
            address: address,
            renting: renting,
            returning: returning,
            ebikes: ebikes
        )
    }

    func updateSnapshot(from station: MobilityStation) {
        name = station.name
        latitude = station.latitude
        longitude = station.longitude
        freeBikes = station.freeBikes
        emptySlots = station.emptySlots
        totalSlots = station.totalSlots
        address = station.address
        renting = station.renting
        returning = station.returning
        ebikes = station.ebikes
    }
}
