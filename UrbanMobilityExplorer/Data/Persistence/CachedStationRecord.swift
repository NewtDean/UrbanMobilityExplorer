//
//  CachedStationRecord.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class CachedStationRecord {
    @Attribute(.unique) var compoundKey: String
    var networkId: String
    var stationId: String
    var name: String
    var latitude: Double
    var longitude: Double
    var freeBikes: Int?
    var emptySlots: Int?
    var totalSlots: Int?
    var lastUpdated: Date?
    var address: String?
    var renting: Bool?
    var returning: Bool?
    var ebikes: Int?
    var rentalURLString: String?
    var recommendationScore: Double?
    var cachedAt: Date

    init(from station: MobilityStation, cachedAt: Date) {
        compoundKey = station.favoriteKey
        networkId = station.networkId
        stationId = station.id
        name = station.name
        latitude = station.latitude
        longitude = station.longitude
        freeBikes = station.freeBikes
        emptySlots = station.emptySlots
        totalSlots = station.totalSlots
        lastUpdated = station.lastUpdated
        address = station.address
        renting = station.renting
        returning = station.returning
        ebikes = station.ebikes
        rentalURLString = station.rentalURL?.absoluteString
        recommendationScore = station.recommendationScore
        self.cachedAt = cachedAt
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
            lastUpdated: lastUpdated,
            address: address,
            renting: renting,
            returning: returning,
            ebikes: ebikes,
            rentalURL: rentalURLString.flatMap(URL.init(string:)),
            recommendationScore: recommendationScore
        )
    }
}
