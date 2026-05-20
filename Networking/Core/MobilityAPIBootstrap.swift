//
//  MobilityAPIBootstrap.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

/// Wires generated OpenAPI clients to production endpoints (keyless public APIs).
public enum MobilityAPIBootstrap: Sendable {
    public static func configure(
        cityBikeBaseURL: String = MobilityServiceHost.cityBike,
        openMeteoBaseURL: String = MobilityServiceHost.openMeteo,
        requestTimeout: TimeInterval = 20
    ) {
        let factory = MobilityHTTPRequestBuilderFactory(requestTimeout: requestTimeout)

        CityBikeAPIConfiguration.shared.basePath = cityBikeBaseURL
        CityBikeAPIConfiguration.shared.requestBuilderFactory = factory

        OpenMeteoAPIConfiguration.shared.basePath = openMeteoBaseURL
        OpenMeteoAPIConfiguration.shared.requestBuilderFactory = factory
    }
}
