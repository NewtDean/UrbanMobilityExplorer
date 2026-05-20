//
//  MapBottomPanel.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

/// Layout metrics for the map discovery sheet.
enum MapBottomPanelMetrics {
    /// Fixed height for the discovery entry sheet (Bikes / Saved only).
    static let entryPanelHeight: CGFloat = 350

    /// Map camera bottom inset — matches the entry sheet height.
    static let minPanelHeight: CGFloat = entryPanelHeight

    /// Matches `MapTopBarGlassBackground` height + room below nav content.
    static let topBarClearance: CGFloat = 150
    /// Top inset for `setVisibleMapRect` — slightly less than `topBarClearance` so the focus is not pushed too high.
    static let mapCameraTopPadding: CGFloat = 112

    /// Gap between the top of a bottom sheet and the location FAB.
    static let fabSpacingAbovePanel: CGFloat = 44

    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }

    /// Gap between sheet top edge and custom nav bar when fully expanded.
    static let maxPanelTopGap: CGFloat = 12

    /// Clears the custom map top bar when the sheet is fully expanded.
    static var maxPanelHeightTopOffset: CGFloat {
        topBarClearance + maxPanelTopGap
    }

      /// Sheet corner radius — larger than default so corners clear the display curve.
    static let sheetCornerRadius: CGFloat = 50

    /// Detail sheet height bounds (content-measured, then clamped).
    static let detailPanelMinHeight: CGFloat = 220
    /// Extra space for sheet chrome + home indicator below measured content.
    static let detailPanelChromeInset: CGFloat = 0

    /// Width used when measuring detail content (full-width sheet).
    static var detailMeasurementWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    /// Single fixed detent for the discovery entry sheet.
    static var entryDetent: PresentationDetent {
        .height(entryPanelHeight)
    }

    static var maxDetent: PresentationDetent {
        .height(maxPanelHeight)
    }

    static func detailDetent(height: CGFloat) -> PresentationDetent {
        .height(clampedDetailHeight(height))
    }

    static func clampedDetailHeight(_ contentHeight: CGFloat) -> CGFloat {
        let measured = contentHeight + detailPanelChromeInset
        return min(max(measured, detailPanelMinHeight), maxPanelHeight)
    }

    static var maxPanelHeight: CGFloat {
        UIScreen.main.bounds.size.height - maxPanelHeightTopOffset
    }

    static var entryDetents: Set<PresentationDetent> {
        [entryDetent]
    }

    static func stackedSecondaryHeight(
        for panel: MapSecondaryPanel,
        detailContentHeight: CGFloat
    ) -> CGFloat {
        clampedDetailHeight(detailContentHeight)
    }

    static var primaryPanelHeight: CGFloat {
        entryPanelHeight
    }

    /// Stations / Saved list sheet — half screen on open, expandable to near full height.
    static var browseListMediumHeight: CGFloat {
        screenHeight * 0.5
    }

    static var browseListLargeHeight: CGFloat {
        maxPanelHeight
    }

    static var browseListMediumDetent: PresentationDetent {
        .height(browseListMediumHeight)
    }

    static var browseListLargeDetent: PresentationDetent {
        .height(browseListLargeHeight)
    }

    static var browseListDetents: Set<PresentationDetent> {
        [browseListMediumDetent, browseListLargeDetent]
    }

    static func browseListPresentationHeight(for detent: PresentationDetent) -> CGFloat {
        if detent == browseListLargeDetent {
            return browseListLargeHeight
        }
        return browseListMediumHeight
    }

    /// Location FAB does not rise above the list sheet’s initial (half-screen) height.
    static var fabMaxObstructionWhenBrowseListExpanded: CGFloat {
        browseListMediumHeight
    }

    static func fabObstructionForBrowseList(detent: PresentationDetent) -> CGFloat {
        min(
            browseListPresentationHeight(for: detent),
            fabMaxObstructionWhenBrowseListExpanded
        )
    }

    /// `fabObstructionForBrowseList` at medium detent + spacing above the sheet top edge.
    static var fabMaxBottomPaddingForBrowseList: CGFloat {
        fabMaxObstructionWhenBrowseListExpanded + fabSpacingAbovePanel
    }

    /// Total height of sheets covering the map from the bottom edge (screen coordinates).
    static func mapBottomObstruction(
        primaryPanelHeight: CGFloat,
        secondaryPanel: MapSecondaryPanel?,
        detailSheetHeight: CGFloat
    ) -> CGFloat {
        guard secondaryPanel != nil else { return primaryPanelHeight }
        let detailHeight = stackedSecondaryHeight(
            for: .stationDetail,
            detailContentHeight: detailSheetHeight
        )
        return max(primaryPanelHeight, detailHeight)
    }
}

// MARK: - Sheet content measurement

private struct SheetContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Measures at full sheet width so multi-line titles wrap correctly (not inside a fixed detent).
private struct SheetContentHeightModifier: ViewModifier {
    @Binding var height: CGFloat
    var measurementWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .top)
            .background {
                content
                    .frame(width: measurementWidth, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: SheetContentHeightPreferenceKey.self,
                                    value: proxy.size.height
                                )
                        }
                    }
                    .hidden()
            }
            .onPreferenceChange(SheetContentHeightPreferenceKey.self) { measured in
                guard measured > 0 else { return }
                height = measured
            }
    }
}

extension View {
    /// Reports intrinsic content height for adaptive `presentationDetents(.height(...))`.
    func reportSheetContentHeight(
        _ height: Binding<CGFloat>,
        measurementWidth: CGFloat = MapBottomPanelMetrics.detailMeasurementWidth
    ) -> some View {
        modifier(SheetContentHeightModifier(height: height, measurementWidth: measurementWidth))
    }
}
