//
//  DesignStyles.swift
//  flip7calculator
//
//  Semantic button and surface styles for UI overhaul migration.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let fillColor = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
        let glowColor = fillColor.opacity(colorScheme == .dark ? 0.34 : 0.22)
        let textColor = DesignColor.color(.textInverse, theme: visualTheme, colorScheme: colorScheme)
        let disabledColor = Color(.systemGray4)

        return configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, DesignSpacing.md)
            .padding(.vertical, DesignSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [fillColor, DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.92)]
                                : [disabledColor, disabledColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.md)
                    .stroke(Color.white.opacity(isEnabled ? 0.14 : 0), lineWidth: 1)
            )
            .shadow(color: isEnabled ? glowColor : .clear, radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(DesignMotion.animation(.fast), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let brand = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)

        return configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(isEnabled ? brand : Color(.systemGray3))
            .padding(.horizontal, DesignSpacing.md)
            .padding(.vertical, DesignSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignRadius.md)
                    .stroke(isEnabled ? brand.opacity(0.35) : Color(.systemGray5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: DesignRadius.md)
                            .fill(
                                isEnabled
                                    ? DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
                                    : brand.opacity(0.04)
                            )
                    )
            )
            .shadow(color: brand.opacity(isEnabled ? 0.08 : 0), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(DesignMotion.animation(.fast), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let brand = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)

        return configuration.label
            .font(.system(size: 15, weight: .medium, design: .rounded))
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
            .animation(DesignMotion.animation(.fast), value: configuration.isPressed)
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
            : DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.2)

        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: visualTheme == .v2
                                ? [raisedSurface, surface]
                                : [surface, surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(border, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(visualTheme == .v2 ? 0.08 : 0), lineWidth: 0.8)
                    .blur(radius: 0.4)
            )
            .shadow(
                color: visualTheme == .v2
                    ? AppBrandPalette.ink.opacity(colorScheme == .dark ? 0.24 : 0.08)
                    : .clear,
                radius: visualTheme == .v2 ? 14 : 0,
                y: visualTheme == .v2 ? 6 : 0
            )
    }
}

struct AppChromeBackground: View {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if visualTheme == .v2 {
                AppBrandPalette.screenGradient(colorScheme: colorScheme)

                Circle()
                    .fill(AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.09 : 0.16))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: 150, y: -230)

                Circle()
                    .fill(AppBrandPalette.brandBlueSky.opacity(colorScheme == .dark ? 0.18 : 0.14))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -150, y: 260)

                RoundedRectangle(cornerRadius: 48)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.02 : 0.06))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 56)
                    .blur(radius: 42)
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
    @Environment(\.colorScheme) private var colorScheme
    let tone: PillBadgeTone

    private var foreground: Color {
        switch tone {
        case .neutral:
            return DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
        case .info:
            return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
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
            return DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme)
        case .info, .success, .warning, .danger:
            return foreground.opacity(0.15)
        }
    }

    func body(content: Content) -> some View {
        content
            .font(DesignTypography.font(.label))
            .foregroundStyle(foreground)
            .padding(.horizontal, DesignSpacing.sm)
            .padding(.vertical, DesignSpacing.xs)
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
