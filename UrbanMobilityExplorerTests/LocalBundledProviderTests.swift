//
//  LocalBundledProviderTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

final class LocalBundledProviderTests: XCTestCase {
    func testLoadsBundledJSON() throws {
        let provider = try LocalBundledStationProvider()
        let networks = try awaitResult { try await provider.fetchNetworks() }
        XCTAssertFalse(networks.isEmpty)
        let result = try awaitResult {
            try await provider.fetchStations(networkId: APIConfiguration.defaultNetworkId, forceRefresh: false)
        }
        XCTAssertGreaterThanOrEqual(result.stations.count, 1)
    }
}

private func awaitResult<T>(_ operation: () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var output: Result<T, Error>!
    Task {
        do {
            output = .success(try await operation())
        } catch {
            output = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try output.get()
}
