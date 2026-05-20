//
//  AppTheme.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI

enum AppTheme {
    static let primaryGreen = Color(red: 0.16, green: 0.80, blue: 0.25)
    static let primaryGreenDark = Color(red: 0.12, green: 0.65, blue: 0.20)
    static let cardBackground = Color(.systemBackground)
    static let sheetBackground = Color(.secondarySystemBackground)
    static let mapMarkerGreen = Color(red: 0.16, green: 0.80, blue: 0.25)

    static let cardCornerRadius: CGFloat = 24
    static let buttonCornerRadius: CGFloat = 28
    static let shadowRadius: CGFloat = 12
}

struct PrimaryGreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? AppTheme.primaryGreenDark : AppTheme.primaryGreen)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CategoryCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: AppTheme.shadowRadius, y: 4)
    }
}

extension View {
    func categoryCard() -> some View {
        modifier(CategoryCardStyle())
    }
}

#Preview("Primary Button") {
    VStack(spacing: 16) {
        Button {} label: {
            Label("Get directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
        }
        .buttonStyle(PrimaryGreenButtonStyle())
    }
    .padding()
}
