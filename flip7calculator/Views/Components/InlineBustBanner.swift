//
//  InlineBustBanner.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct InlineBustBanner: View {
    let duplicateNumber: Int
    let onConfirmBust: () -> Void
    let onUndo: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var dangerColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(dangerColor)

            Text("Duplicate \(duplicateNumber): Bust?")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))

            Spacer()

            Button(action: {
                HapticFeedback.light()
                onUndo()
            }) {
                Text("Undo")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accentColor.opacity(0.14))
                    )
            }
            .buttonStyle(KeycapButtonStyle(pressedScale: 0.95))

            Button(action: {
                HapticFeedback.error()
                onConfirmBust()
            }) {
                Text("Bust")
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(dangerColor.contrastingForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(dangerColor)
                    )
            }
            .buttonStyle(KeycapButtonStyle(pressedScale: 0.95))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(dangerColor.opacity(colorScheme == .dark ? 0.16 : 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(dangerColor.opacity(0.34), lineWidth: 1)
                )
        )
        .transition(.opacity)
    }
}
