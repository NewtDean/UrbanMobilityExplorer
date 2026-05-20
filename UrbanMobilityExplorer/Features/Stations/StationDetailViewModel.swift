//
//  StationDetailViewModel.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import MapKit
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class StationDetailViewModel: ObservableObject {
    @Published var station: MobilityStation
    @Published private(set) var isFavorite = false
    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var isLoadingWeather = false
    @Published private(set) var weatherError: String?

    private let dependencies: AppDependencies

    init(station: MobilityStation, dependencies: AppDependencies) {
        self.station = station
        self.dependencies = dependencies
    }

    /// Persisted score (0–100); does not change when favoriting or weather loads.
    var recommendationScore: Double {
        station.recommendationScore ?? 0
    }

    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: station.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func onAppear() async {
        await refreshFavoriteState()
        await loadWeather()
        await refreshStationIfNeeded()
    }

    /// Optimistic UI: updates `isFavorite` immediately, persists in the background.
    /// - Returns: `false` if persistence failed (caller should revert local UI).
    @discardableResult
    func toggleFavorite() async -> Bool {
        guard let repo = dependencies.favoritesRepository else { return false }

        let previous = isFavorite
        isFavorite.toggle()

        do {
            try await repo.toggleFavorite(station)
            return true
        } catch {
            isFavorite = previous
            FavoriteHUD.showSaveFailed(wasAdding: !previous)
            return false
        }
    }

    /// Opens the CityBikes `extra.rental_uris.ios` deep link (QR / app handoff).
    func openRentalLink() {
        #if canImport(UIKit)
        guard let rentalURL = station.rentalURL else { return }
        UIApplication.shared.open(rentalURL)
        #endif
    }

    func openInMaps() {
        #if canImport(UIKit)
        if let rentalURL = station.rentalURL {
            UIApplication.shared.open(rentalURL)
            return
        }
        #endif
        let placemark = MKPlacemark(coordinate: station.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = station.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func refreshFavoriteState() async {
        guard let repo = dependencies.favoritesRepository else { return }
        isFavorite = await repo.isFavorite(stationId: station.id, networkId: station.networkId)
    }

    private func loadWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        do {
            weather = try await dependencies.weatherProvider.currentWeather(
                latitude: station.latitude,
                longitude: station.longitude
            )
            weatherError = nil
        } catch {
            weatherError = error.localizedDescription
        }
    }

    private func refreshStationIfNeeded() async {
        if let updated = try? await dependencies.stationProvider.fetchStation(
            networkId: station.networkId,
            stationId: station.id
        ) {
            station = station.mergingLiveRefresh(updated)
        }
    }
}

// MARK: - Preview

#if DEBUG
extension StationDetailViewModel {
  static func preview(
    station: MobilityStation = PreviewData.station,
    isFavorite: Bool = true,
    weather: WeatherSnapshot? = WeatherSnapshot(
      temperatureCelsius: 18,
      windSpeedKmh: 12,
      weatherCode: 1,
      fetchedAt: Date()
    )
  ) -> StationDetailViewModel {
    let viewModel = StationDetailViewModel(station: station, dependencies: AppDependencies.previewForCanvas())
    viewModel.isFavorite = isFavorite
    viewModel.weather = weather
    viewModel.isLoadingWeather = false
    return viewModel
  }

  static func previewLoadingWeather() -> StationDetailViewModel {
    let viewModel = preview(weather: nil)
    viewModel.isLoadingWeather = true
    return viewModel
  }

  nonisolated static func previewForCanvas(
    station: MobilityStation? = nil,
    isFavorite: Bool = true,
    weather: WeatherSnapshot? = nil
  ) -> StationDetailViewModel {
    MainActor.assumeIsolated {
      preview(
        station: station ?? PreviewData.station,
        isFavorite: isFavorite,
        weather: weather ?? WeatherSnapshot(
          temperatureCelsius: 18,
          windSpeedKmh: 12,
          weatherCode: 1,
          fetchedAt: Date()
        )
      )
    }
  }

  nonisolated static func previewLoadingWeatherForCanvas() -> StationDetailViewModel {
    MainActor.assumeIsolated { previewLoadingWeather() }
  }
}
#endif
