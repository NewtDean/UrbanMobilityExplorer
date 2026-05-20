//
//  MobilityServiceHost.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Base URLs for public mobility data providers (no API keys).
public enum MobilityServiceHost: Sendable {
    public static let cityBike = "https://api.citybik.es/v2"
    public static let openMeteo = "https://api.open-meteo.com/v1"
}
