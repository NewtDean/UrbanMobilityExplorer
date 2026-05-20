//
//  SearchHistoryStore.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Combine
import Foundation

/// Persists recent station search terms (client-side; CityBikes has no query-history API).
@MainActor
final class SearchHistoryStore: ObservableObject {
    @Published private(set) var items: [String] = []

    private let defaultsKey: String
    private let maxCount: Int

    init(defaultsKey: String = "stationSearchHistory", maxCount: Int = 10) {
        self.defaultsKey = defaultsKey
        self.maxCount = maxCount
        items = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
    }

    func record(_ rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        var next = items.filter { $0.compare(query, options: .caseInsensitive) != .orderedSame }
        next.insert(query, at: 0)
        items = Array(next.prefix(maxCount))
        UserDefaults.standard.set(items, forKey: defaultsKey)
    }

    func remove(_ query: String) {
        items.removeAll { $0.compare(query, options: .caseInsensitive) == .orderedSame }
        UserDefaults.standard.set(items, forKey: defaultsKey)
    }

    func clear() {
        items = []
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
