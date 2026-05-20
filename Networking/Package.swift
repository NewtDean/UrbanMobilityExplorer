// swift-tools-version: 6.0
//
//  Package.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "UrbanMobilityNetworking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "UrbanMobilityNetworking",
            targets: ["UrbanMobilityNetworking"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
    ],
    targets: [
        .target(
            name: "UrbanMobilityNetworking",
            dependencies: ["Alamofire"],
            path: ".",
            exclude: [
                "Scripts",
            ],
            sources: [
                "Core",
                "OpenApiClientGenerated/Shared",
                "OpenApiClientGenerated/CityBike_OpenAPI",
                "OpenApiClientGenerated/OpenMeteo_OpenAPI",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
