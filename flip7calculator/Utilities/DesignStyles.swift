//
//  DesignStyles.swift
//  flip7calculator
//
//  Semantic button, keycap, and surface styles.
//

import SwiftUI

/// Lightweight native ButtonStyle for high-frequency tactile controls (number chips,
/// modifier chips, player tiles, and action pills). Pre-warms haptics on press-down
/// and respects both system Reduce Motion and in-app Reduce Animations.
struct KeycapButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var preparesHaptic: Bool = true
    var onPressChanged: ((Bool) -> Void)? = nil

    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !isReducedMotion ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                onPressChanged?(pressed)
                if pressed && preparesHaptic {
                    HapticFeedback.prepareLight()
                }
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        let fillColor = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
        let textColor = fillColor.contrastingForeground
        let disabledColor = Color(.systemGray4)

        return configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(isEnabled ? textColor : Color(.secondaryLabel))
            .padding(.horizontal, DesignSpacing.md)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(isEnabled ? fillColor : disabledColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.14 : 0), lineWidth: 1)
            )
            .shadow(
                color: isEnabled && colorScheme == .light ? fillColor.opacity(0.16) : .clear,
                radius: 8,
                y: 4
            )
            .scaleEffect(configuration.isPressed && !isReducedMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        let brand = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)

        return configuration.label
            .font(.system(.callout, design: .rounded, weight: .semibold))
            .foregroundStyle(isEnabled ? brand : Color(.systemGray3))
            .padding(.horizontal, DesignSpacing.md)
            .padding(.vertical, DesignSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(
                        isEnabled
                            ? DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
                            : brand.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .stroke(isEnabled ? brand.opacity(0.32) : Color(.systemGray5), lineWidth: 1.25)
            )
            .scaleEffect(configuration.isPressed && !isReducedMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        let brand = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)

        return configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundStyle(isEnabled ? brand : Color(.systemGray3))
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, DesignSpacing.xs)
            .background(
                Capsule()
                    .fill(
                        isEnabled
                            ? brand.opacity(configuration.isPressed ? 0.18 : 0.10)
                            : DesignColor.color(.surfaceInteractive, theme: visualTheme, colorScheme: colorScheme)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(brand.opacity(isEnabled ? 0.18 : 0), lineWidth: 1)
            )
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
    }
}

struct SelectionCardButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        let brand = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
        let surface = DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
        let text = DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
        let border = DesignColor.border(theme: visualTheme, colorScheme: colorScheme)

        return configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(isEnabled ? (isSelected ? brand : text) : Color(.systemGray3))
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .fill(isSelected ? brand.opacity(0.14) : surface.opacity(isEnabled ? 0.92 : 0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                    .stroke(isSelected ? brand : border, lineWidth: isSelected ? 1.75 : 1)
            )
            .scaleEffect(configuration.isPressed && !isReducedMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
            .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: isSelected)
    }
}

struct CardSurfaceStyle: ViewModifier {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = DesignRadius.lg

    func body(content: Content) -> some View {
        let surface = DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme)
        let raisedSurface = DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
        let border = visualTheme == .v2
            ? AppBrandPalette.cardBorder(colorScheme: colorScheme)
            : Color(.separator).opacity(0.35)

        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(visualTheme == .v2 ? raisedSurface : surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .shadow(
                color: visualTheme == .v2 && colorScheme == .light ? AppBrandPalette.ink.opacity(0.06) : .clear,
                radius: visualTheme == .v2 && colorScheme == .light ? 10 : 0,
                y: visualTheme == .v2 && colorScheme == .light ? 4 : 0
            )
    }
}

struct AppChromeBackground: View {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if visualTheme == .v2 {
                AppBrandPalette.screenBackground(colorScheme: colorScheme)
            } else {
                Color(.systemGroupedBackground)
            }
        }
        .ignoresSafeArea()
    }
}

enum PillBadgeTone {
    case neutral
    case info
    case success
    case warning
    case danger
}

struct PillBadgeStyle: ViewModifier {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    let tone: PillBadgeTone

    private var foreground: Color {
        switch tone {
        case .neutral:
            return DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
        case .info:
            return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
        case .success:
            return DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
        case .warning:
            return DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
        case .danger:
            return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        }
    }

    private var background: Color {
        switch tone {
        case .neutral:
            return DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
        case .info, .success, .warning, .danger:
            return foreground.opacity(0.15)
        }
    }

    func body(content: Content) -> some View {
        content
            .font(DesignTypography.font(.label))
            .foregroundStyle(foreground)
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(background))
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = DesignRadius.lg) -> some View {
        modifier(CardSurfaceStyle(cornerRadius: cornerRadius))
    }

    func pillBadge(_ tone: PillBadgeTone = .neutral) -> some View {
        modifier(PillBadgeStyle(tone: tone))
    }

    func appChromeBackground() -> some View {
        background(AppChromeBackground())
    }
}
