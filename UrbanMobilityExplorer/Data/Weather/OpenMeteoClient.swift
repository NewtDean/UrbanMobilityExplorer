//
//  OpenMeteoClient.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation
import UrbanMobilityNetworking

struct OpenMeteoClient: WeatherProviding, Sendable {
    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        do {
            let response = try await ForecastAPI.getCurrentWeatherForecast(
                latitude: latitude,
                longitude: longitude,
                currentWeather: true
            )
            return response.toWeatherSnapshot()
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw error
            }
            throw error
        }
    }
}
