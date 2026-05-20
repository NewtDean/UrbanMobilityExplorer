//
//  StarRatingView.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Maps a 0–100 score to five stars (20 points per star, 10 per half star).
enum StarRatingDisplay {
    static let defaultMaxScore = 100.0
    static let defaultStarCount = 5

    /// Filled star units in `[0, starCount]` (e.g. 90 → 4.5).
    static func filledUnits(
        score: Double,
        maxScore: Double = defaultMaxScore,
        starCount: Int = defaultStarCount
    ) -> Double {
        guard maxScore > 0, starCount > 0 else { return 0 }
        let units = (score / maxScore) * Double(starCount)
        return min(max(units, 0), Double(starCount))
    }

    /// Star count as a decimal string rounded to one place (e.g. 82 pts → `"4.1"`).
    static func formattedStarRating(
        score: Double,
        maxScore: Double = defaultMaxScore,
        starCount: Int = defaultStarCount
    ) -> String {
        guard score > 0 else {
            return "No ratings yet"
        }
        let units = filledUnits(score: score, maxScore: maxScore, starCount: starCount)
        let rounded = (units * 10).rounded() / 10
        return String(format: "%.1f", rounded)
    }

    static func symbolName(starIndex: Int, filledUnits: Double) -> String {
        let index = Double(starIndex)
        if filledUnits >= index {
            return "star.fill"
        }
        if filledUnits >= index - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}

struct StarRatingView: View {
    let score: Double
    var maxScore: Double = StarRatingDisplay.defaultMaxScore
    var starCount: Int = StarRatingDisplay.defaultStarCount

    private var filledUnits: Double {
        StarRatingDisplay.filledUnits(score: score, maxScore: maxScore, starCount: starCount)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...starCount, id: \.self) { index in
                Image(systemName: StarRatingDisplay.symbolName(starIndex: index, filledUnits: filledUnits))
                    .foregroundStyle(.yellow)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let rounded = (filledUnits * 2).rounded() / 2
        return String(localized: "\(Int(rounded)) of \(starCount) stars, score \(Int(score.rounded())) out of \(Int(maxScore.rounded()))")
    }
}

#if DEBUG
#Preview("Star ratings") {
    VStack(alignment: .leading, spacing: 16) {
        StarRatingView(score: 90)
        StarRatingView(score: 82)
        StarRatingView(score: 50)
        StarRatingView(score: 10)
        StarRatingView(score: 100)
        StarRatingView(score: 0)
    }
    .padding()
}
#endif
