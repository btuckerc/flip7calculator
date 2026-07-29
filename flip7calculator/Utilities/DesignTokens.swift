//
//  DesignTokens.swift
//  flip7calculator
//
//  UI overhaul design tokens and theme bridge.
//

import SwiftUI

enum VisualTheme: String, CaseIterable {
    case legacy
    case v2

    var displayName: String {
        switch self {
        case .legacy:
            return "Legacy"
        case .v2:
            return AppBrand.visualThemeV2Name
        }
    }

    var icon: String {
        switch self {
        case .legacy:
            return "clock.arrow.circlepath"
        case .v2:
            return "sparkles.rectangle.stack"
        }
    }
}

private struct VisualThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: VisualTheme = .legacy
}

extension EnvironmentValues {
    var visualTheme: VisualTheme {
        get { self[VisualThemeEnvironmentKey.self] }
        set { self[VisualThemeEnvironmentKey.self] = newValue }
    }
}

enum DesignColor {
    enum Role {
        case surfacePrimary
        case surfaceSecondary
        case surfaceRaised
        case surfaceInteractive
        case textPrimary
        case textSecondary
        case textInverse
        case brandPrimary
        case brandSecondary
        case stateSuccess
        case stateWarning
        case stateDanger
        case playerHighlight
    }

    static func color(_ role: Role, theme: VisualTheme, colorScheme: ColorScheme?) -> Color {
        switch theme {
        case .legacy:
            return legacyColor(role, colorScheme: colorScheme)
        case .v2:
            return v2Color(role, colorScheme: colorScheme)
        }
    }

    private static func legacyColor(_ role: Role, colorScheme: ColorScheme?) -> Color {
        switch role {
        case .surfacePrimary:
            return Color(.systemBackground)
        case .surfaceSecondary:
            return Color(.systemGroupedBackground)
        case .surfaceRaised:
            return Color(.secondarySystemBackground)
        case .surfaceInteractive:
            return Color(.tertiarySystemFill)
        case .textPrimary:
            return .primary
        case .textSecondary:
            return .secondary
        case .textInverse:
            return .white
        case .brandPrimary:
            return .blue
        case .brandSecondary:
            return .indigo
        case .stateSuccess:
            return .green
        case .stateWarning:
            return .orange
        case .stateDanger:
            return .red
        case .playerHighlight:
            return .cyan
        }
    }

    private static func v2Color(_ role: Role, colorScheme: ColorScheme?) -> Color {
        let dark = colorScheme == .dark
        switch role {
        case .surfacePrimary:
            return AppBrandPalette.cardFill(colorScheme: colorScheme)
        case .surfaceSecondary:
            return AppBrandPalette.panelFill(colorScheme: colorScheme)
        case .surfaceRaised:
            return dark ? Color.hex("19324D") : Color.white.opacity(0.94)
        case .surfaceInteractive:
            return dark ? Color.hex("1D3654") : Color.hex("E1EBF7")
        case .textPrimary:
            return dark ? AppBrandPalette.parchment : AppBrandPalette.ink
        case .textSecondary:
            return dark ? Color.hex("A8B8CB") : Color.hex("5B6E87")
        case .textInverse:
            return dark ? AppBrandPalette.ink : AppBrandPalette.parchment
        case .brandPrimary:
            return dark ? AppBrandPalette.blueGlow : AppBrandPalette.brandBlue
        case .brandSecondary:
            return AppBrandPalette.gold
        case .stateSuccess:
            return dark ? AppBrandPalette.blueGlow : AppBrandPalette.brandBlueSky
        case .stateWarning:
            return AppBrandPalette.gold
        case .stateDanger:
            return AppBrandPalette.copper
        case .playerHighlight:
            return dark ? AppBrandPalette.blueGlow : AppBrandPalette.brandBlueSky
        }
    }
}

enum DesignTypography {
    enum Style {
        case display
        case title
        case body
        case label
        case mono
    }

    static func font(_ style: Style) -> Font {
        switch style {
        case .display:
            return .custom("Nunito-Black", size: 34)
        case .title:
            return .custom("Nunito-Bold", size: 24)
        case .body:
            return .system(size: 17, weight: .regular, design: .rounded)
        case .label:
            return .system(size: 13, weight: .semibold, design: .rounded)
        case .mono:
            return .system(size: 14, weight: .medium, design: .monospaced)
        }
    }
}

enum DesignSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum DesignRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let pill: CGFloat = 999
}

enum DesignMotion {
    enum Preset {
        case fast
        case normal
        case emphasis
    }

    static func animation(_ preset: Preset) -> Animation {
        switch preset {
        case .fast:
            return .snappy(duration: 0.18, extraBounce: 0)
        case .normal:
            return .smooth(duration: 0.28)
        case .emphasis:
            return .bouncy(duration: 0.42, extraBounce: 0.08)
        }
    }

    static func shouldReduceMotion(reduceAnimations: Bool, accessibilityReduceMotion: Bool) -> Bool {
        reduceAnimations || accessibilityReduceMotion
    }
}
