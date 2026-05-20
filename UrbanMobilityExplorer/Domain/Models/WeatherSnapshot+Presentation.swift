//
//  WeatherSnapshot+Presentation.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

extension WeatherSnapshot {
    struct Presentation: Equatable {
        let symbolName: String
        let tint: Color
    }

    var presentation: Presentation {
        Self.presentation(for: weatherCode)
    }

    /// One-line cycling tip for the discovery panel (English; wraps to ~2 lines).
    var mobilityAdvice: String {
        Self.mobilityAdvice(for: weatherCode)
    }

    /// WMO weather codes (Open-Meteo) → SF Symbol + tint for discovery / detail UI.
    static func presentation(for code: Int) -> Presentation {
        switch code {
        case 0:
            Presentation(symbolName: "sun.max.fill", tint: .yellow)
        case 1:
            Presentation(symbolName: "sun.max.fill", tint: Color(red: 1, green: 0.82, blue: 0.2))
        case 2:
            Presentation(symbolName: "cloud.sun.fill", tint: Color(red: 0.35, green: 0.62, blue: 0.95))
        case 3:
            Presentation(symbolName: "cloud.fill", tint: Color(red: 0.12, green: 0.22, blue: 0.42))
        case 45, 48:
            Presentation(symbolName: "cloud.fog.fill", tint: .gray)
        case 51, 53, 55, 56, 57:
            Presentation(symbolName: "cloud.drizzle.fill", tint: .blue)
        case 61, 63, 65, 66, 67, 80, 81, 82:
            Presentation(symbolName: "cloud.rain.fill", tint: .blue)
        case 71, 73, 75, 77, 85, 86:
            Presentation(symbolName: "cloud.snow.fill", tint: Color(red: 0.45, green: 0.75, blue: 0.95))
        case 95, 96, 99:
            Presentation(symbolName: "cloud.bolt.rain.fill", tint: Color(red: 0.18, green: 0.22, blue: 0.48))
        default:
            Presentation(symbolName: "cloud.sun.fill", tint: .secondary)
        }
    }

  /// WMO weather codes (Open-Meteo) → short English riding guidance for the discovery card.
  static func mobilityAdvice(for code: Int) -> String {
    switch code {
    case 0:
      "Clear skies—great for riding. Use sunscreen and carry water on longer trips."
    case 1:
      "Mostly clear and pleasant—ideal for cycling. Sunglasses help with low glare."
    case 2:
      "Partly cloudy—comfortable riding weather. A light layer is enough for most routes."
    case 3:
      "Overcast skies—still fine to ride. Wear something bright so drivers can see you."
    case 45, 48:
      "Foggy conditions—ride slowly, use lights, and stick to familiar, well-lit streets."
    case 51, 53, 55:
      "Light drizzle—roads may be slick. Brake early and consider a shorter ride."
    case 56, 57:
      "Freezing drizzle—icy patches are likely. Walk the bike or choose another option."
    case 61, 63, 65:
      "Rainy weather—consider another mode of transport or wait for a drier window."
    case 66, 67:
      "Freezing rain—unsafe for bikes. Please use transit or another way to travel."
    case 71, 73, 75:
      "Snow on the ground—tires slip easily. Skip the ride unless paths are fully cleared."
    case 77:
      "Snow grains and poor grip—keep rides short or use a safer transport option."
    case 80, 81, 82:
      "Rain showers expected—reduce riding time and pick sheltered routes if you go out."
    case 85, 86:
      "Snow showers—cold and slippery. Another transport option is safer today."
    case 95:
      "Thunderstorms nearby—do not ride. Wait indoors until the storm has passed."
    case 96, 99:
      "Severe storms with hail—stay off the bike and use another way to get around."
    default:
      "Changeable conditions—check the sky often and adjust your route if it worsens."
    }
  }
}
