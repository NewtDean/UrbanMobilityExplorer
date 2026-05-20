//
//  MobilityStation+Display.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import Foundation

extension MobilityStation {
    /// Separator between dock number and place name in CityBikes titles (`"123 - Main St"`).
    nonisolated static let titleSeparator = " - "

    /// Common dash separators seen in CityBikes titles (hyphen, en dash, em dash, minus sign).
    private nonisolated static let titleSeparatorCandidates = [
        " - ",
        " – ",
        " — ",
        " − "
    ]

    /// Leading dock number before the first separator (e.g. `001192`).
    nonisolated var stationCode: String? {
        Self.parseStationTitle(name).code
    }

    /// Place name: everything after the **first** separator, never split again.
    nonisolated var locationDisplayName: String {
        Self.parseStationTitle(name).displayName
    }

    nonisolated static func parseStationTitle(_ fullName: String) -> (code: String?, displayName: String) {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = earliestTitleSeparatorRange(in: trimmed) else {
            return (extractLeadingStationCode(from: trimmed), trimmed)
        }

        let prefix = String(trimmed[..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = String(trimmed[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let code = extractLeadingStationCode(from: prefix),
              !code.isEmpty,
              !displayName.isEmpty else {
            return (nil, trimmed)
        }
        return (code, displayName)
    }

    private nonisolated static func earliestTitleSeparatorRange(in text: String) -> Range<String.Index>? {
        titleSeparatorCandidates
            .compactMap { text.range(of: $0) }
            .min(by: { $0.lowerBound < $1.lowerBound })
    }

    /// First contiguous digit run at the start of the prefix (dock number).
    private nonisolated static func extractLeadingStationCode(from segment: String) -> String? {
        let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let digits = trimmed.prefix(while: \.isNumber)
        if !digits.isEmpty { return String(digits) }
        return trimmed
    }
}
