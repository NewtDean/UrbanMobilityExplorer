//
//  UrbanMobilityExplorerApp.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import ProgressHUD
import SwiftData
import SwiftUI
import UrbanMobilityNetworking

@main
struct UrbanMobilityExplorerApp: App {
    @StateObject private var dependencies = AppDependencies()

    init() {
        MobilityAPIBootstrap.configure(
            cityBikeBaseURL: APIConfiguration.cityBikesBaseURL.absoluteString,
            openMeteoBaseURL: APIConfiguration.openMeteoBaseURL.absoluteString,
            requestTimeout: APIConfiguration.requestTimeout
        )
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteStation.self,
            FavoriteNetwork.self,
            CachedStationRecord.self,
            CachedNetworkRecord.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(dependencies)
                .preferredColorScheme(.light)
                .progressHUD()
                .task {
                    dependencies.configure(modelContainer: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
