//
//  SearchHistoryStoreTests.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import XCTest
@testable import UrbanMobilityExplorer

@MainActor
final class SearchHistoryStoreTests: XCTestCase {
    func testRecordDedupesAndMovesToFront() {
        let store = SearchHistoryStore(defaultsKey: UUID().uuidString, maxCount: 5)
        store.record("Oxford Street")
        store.record("Hyde Park")
        store.record("Oxford Street")

        XCTAssertEqual(store.items, ["Oxford Street", "Hyde Park"])
    }

    func testRecordTrimsAndIgnoresEmpty() {
        let store = SearchHistoryStore(defaultsKey: UUID().uuidString)
        store.record("   ")
        store.record("  Bank  ")
        XCTAssertEqual(store.items, ["Bank"])
    }

    func testRemoveAndClear() {
        let store = SearchHistoryStore(defaultsKey: UUID().uuidString)
        store.record("A")
        store.record("B")
        store.remove("A")
        XCTAssertEqual(store.items, ["B"])
        store.clear()
        XCTAssertTrue(store.items.isEmpty)
    }
}
