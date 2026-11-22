//
//  ModifierGrid.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct ModifierGrid: View {
    let mode: GameMode
    let addMods: [Int: Int]
    let x2Count: Int
    let subtractMods: [Int: Int]
    let divideByTwoCount: Int
    let availability: RoundDeckAvailability
    let canEditClassicModifiers: Bool
    let canEditVengeanceModifiers: Bool
    let onTapModifier: (Int) -> Void
    let onLongPressModifier: (Int) -> Void
    let onTapX2: () -> Void
    let onLongPressX2: () -> Void
    let onTapSubtractModifier: (Int) -> Void
    let onLongPressSubtractModifier: (Int) -> Void
    let onTapDivideByTwo: () -> Void
    let onLongPressDivideByTwo: () -> Void
    let showCountBadges: Bool

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 6)

    private func isClassicModifierEnabled(_ value: Int) -> Bool {
        guard canEditClassicModifiers else { return false }
        return (addMods[value] ?? 0) > 0 || availability.canAddModifier(value)
    }

    private var isX2Enabled: Bool {
        canEditClassicModifiers && (x2Count > 0 || availability.x2 > 0)
    }

    private func isVengeanceModifierEnabled(_ value: Int) -> Bool {
        guard canEditVengeanceModifiers else { return false }
        return (subtractMods[value] ?? 0) > 0 || availability.canAddSubtractModifier(value)
    }

    private var isDivideByTwoEnabled: Bool {
        canEditVengeanceModifiers && (divideByTwoCount > 0 || availability.divideByTwo > 0)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            if mode == .classic {
                ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                    ModifierTile(
                        label: "+\(value)",
                        accessibilityName: "Plus \(value) modifier",
                        count: addMods[value] ?? 0,
                        accent: DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme),
                        isEnabled: isClassicModifierEnabled(value),
                        showCountBadge: showCountBadges,
                        onTap: { onTapModifier(value) },
                        onLongPress: { onLongPressModifier(value) }
                    )
                }

                ModifierTile(
                    label: "×2",
                    accessibilityName: "Double score multiplier",
                    count: x2Count,
                    accent: DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride),
                    isEnabled: isX2Enabled,
                    showCountBadge: showCountBadges,
                    onTap: onTapX2,
                    onLongPress: onLongPressX2
                )
            } else {
                ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                    ModifierTile(
                        label: "−\(value)",
                        accessibilityName: "Minus \(value) modifier",
                        count: subtractMods[value] ?? 0,
                        accent: DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme),
                        isEnabled: isVengeanceModifierEnabled(value),
                        showCountBadge: showCountBadges,
                        onTap: { onTapSubtractModifier(value) },
                        onLongPress: { onLongPressSubtractModifier(value) }
                    )
                }

                ModifierTile(
                    label: "÷2",
                    accessibilityName: "Divide by two modifier",
                    count: divideByTwoCount,
                    accent: DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride),
                    isEnabled: isDivideByTwoEnabled,
                    showCountBadge: showCountBadges,
                    onTap: onTapDivideByTwo,
                    onLongPress: onLongPressDivideByTwo
                )
            }
        }
    }
}

/// Accessible native Button-backed modifier keycap with clean drag-off cancellation,
/// optional long-press decrement for multi-copy decks, and VoiceOver custom action.
struct ModifierTile: View {
    let label: String
    let accessibilityName: String
    let count: Int
    let accent: Color
    let isEnabled: Bool
    let showCountBadge: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var didTriggerLongPress = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @ScaledMetric(relativeTo: .subheadline) private var scaledLabelSize: CGFloat = 14

    private var isSelected: Bool { count > 0 }

    private var tileHeight: CGFloat {
        horizontalSizeClass == .regular ? 50 : 40
    }

    private var labelFontSize: CGFloat {
        min(horizontalSizeClass == .regular ? scaledLabelSize + 1 : scaledLabelSize, 19)
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var fillColor: Color {
        if isSelected {
            return accent
        }
        return DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
            .opacity(isEnabled ? 1 : 0.42)
    }

    private var borderColor: Color {
        if isSelected {
            return accent.opacity(0.45)
        }
        if !isEnabled {
            return Color.clear
        }
        return visualTheme == .v2 ? AppBrandPalette.keycapBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.45)
    }

    private var labelColor: Color {
        if isSelected {
            return accent.contrastingForeground
        }
        if isEnabled {
            return DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
        }
        return DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.38)
    }

    var body: some View {
        Button {
            if didTriggerLongPress {
                didTriggerLongPress = false
                return
            }
            guard isEnabled else { return }
            HapticFeedback.light()
            onTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(label)
                    .font(.system(size: labelFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                    .foregroundStyle(labelColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: tileHeight)

                if count > 0 && showCountBadge {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent.contrastingForeground)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.black.opacity(0.24)))
                        .padding(3)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(
            KeycapButtonStyle(
                pressedScale: 0.94,
                onPressChanged: { isPressed in
                    if isPressed {
                        didTriggerLongPress = false
                    }
                }
            )
        )
        .disabled(!isEnabled)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.35)
                .onEnded { _ in
                    guard isEnabled else { return }
                    didTriggerLongPress = true
                    guard count > 0 else { return }
                    HapticFeedback.medium()
                    onLongPress()
                }
        )
        .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: count)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(count > 0 ? "\(count) selected" : (isEnabled ? "Not selected" : "Unavailable"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Remove one") {
            if isEnabled, count > 0 {
                onLongPress()
            }
        }
    }
}
