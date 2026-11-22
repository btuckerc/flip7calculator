//
//  DesignTokens.swift
//  flip7calculator
//
//  Semantic design tokens and visual theme bridge.
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
    static let defaultValue: VisualTheme = .v2
}

private struct AppAccentOverrideKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

extension EnvironmentValues {
    var visualTheme: VisualTheme {
        get { self[VisualThemeEnvironmentKey.self] }
        set { self[VisualThemeEnvironmentKey.self] = newValue }
    }

    var appAccentOverride: Color? {
        get { self[AppAccentOverrideKey.self] }
        set { self[AppAccentOverrideKey.self] = newValue }
    }
}

enum VisualThemeMigration {
    static let themeKey = "visualThemeVersion"
    static let migratedKey = "didMigrateFlippingSevenThemeV2"

    /// Runs once to set new installs to `.v2` while preserving any valid stored preference
    /// (such as an existing user's `"legacy"` selection) even if the migration marker was absent.
    @discardableResult
    static func migrateIfNeeded(defaults: UserDefaults = .standard) -> VisualTheme {
        if !defaults.bool(forKey: migratedKey) {
            if let existingRaw = defaults.string(forKey: themeKey),
               let existing = VisualTheme(rawValue: existingRaw) {
                defaults.set(true, forKey: migratedKey)
                return existing
            }
            defaults.set(VisualTheme.v2.rawValue, forKey: themeKey)
            defaults.set(true, forKey: migratedKey)
            return .v2
        }
        return VisualTheme(rawValue: defaults.string(forKey: themeKey) ?? "") ?? .v2
    }
}

enum DesignColor {
    enum Role {
        case surfacePrimary
        case surfaceSecondary
        case surfaceRaised
        case surfaceKeycap
        case surfaceInteractive
        case textPrimary
        case textSecondary
        case textInverse
        case brandPrimary
        case brandSecondary
        case stateSuccess
        case stateFrozen
        case stateWarning
        case stateDanger
        case playerHighlight
    }

    static func color(
        _ role: Role,
        theme: VisualTheme = .v2,
        colorScheme: ColorScheme?,
        accentOverride: Color? = nil
    ) -> Color {
        if role == .brandPrimary, let accentOverride {
            return accentOverride
        }
        switch theme {
        case .legacy:
            return legacyColor(role, colorScheme: colorScheme)
        case .v2:
            return v2Color(role, colorScheme: colorScheme)
        }
    }

    static func border(theme: VisualTheme, colorScheme: ColorScheme?) -> Color {
        theme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.4)
    }

    static func keycapBorder(theme: VisualTheme, colorScheme: ColorScheme?) -> Color {
        theme == .v2 ? AppBrandPalette.keycapBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.45)
    }

    static func listRowBackground(theme: VisualTheme, colorScheme: ColorScheme?) -> Color {
        theme == .v2
            ? v2Color(.surfaceRaised, colorScheme: colorScheme)
            : Color(.secondarySystemGroupedBackground)
    }

    private static func legacyColor(_ role: Role, colorScheme: ColorScheme?) -> Color {
        switch role {
        case .surfacePrimary:
            return Color(.systemBackground)
        case .surfaceSecondary:
            return Color(.systemGroupedBackground)
        case .surfaceRaised:
            return Color(.secondarySystemBackground)
        case .surfaceKeycap:
            return Color(.tertiarySystemBackground)
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
        case .stateFrozen:
            return .cyan
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
            return dark ? Color.hex("172A44") : Color.white
        case .surfaceKeycap:
            return dark ? Color.hex("203859") : Color.hex("EDF2F8")
        case .surfaceInteractive:
            return dark ? Color.hex("1E3554") : Color.hex("E6EEF7")
        case .textPrimary:
            return dark ? Color.hex("F5F7FB") : AppBrandPalette.ink
        case .textSecondary:
            return dark ? Color.hex("9DB0C7") : Color.hex("566982")
        case .textInverse:
            return dark ? Color.hex("0B1726") : Color.white
        case .brandPrimary:
            return dark ? AppBrandPalette.blueGlow : AppBrandPalette.brandBlue
        case .brandSecondary:
            return dark ? AppBrandPalette.gold : AppBrandPalette.goldDeep
        case .stateSuccess:
            return dark ? Color.hex("34C77B") : Color.hex("16794B")
        case .stateFrozen:
            return dark ? Color.hex("5CC8FA") : Color.hex("197DA8")
        case .stateWarning:
            return dark ? AppBrandPalette.gold : AppBrandPalette.goldDeep
        case .stateDanger:
            return dark ? Color.hex("F06B5E") : Color.hex("C9463B")
        case .playerHighlight:
            return dark ? Color.hex("5CC8FA") : Color.hex("197DA8")
        }
    }
}

enum DesignTypography {
    enum Style {
        case display
        case title
        case headline
        case body
        case label
        case caption
        case mono
    }

    static func font(_ style: Style) -> Font {
        switch style {
        case .display:
            return .custom("Nunito-Black", size: 30, relativeTo: .largeTitle)
        case .title:
            return .system(.title2, design: .rounded, weight: .bold)
        case .headline:
            return .system(.headline, design: .rounded, weight: .semibold)
        case .body:
            return .system(.body, design: .rounded, weight: .regular)
        case .label:
            return .system(.footnote, design: .rounded, weight: .semibold)
        case .caption:
            return .system(.caption, design: .rounded, weight: .medium)
        case .mono:
            return .system(.footnote, design: .monospaced, weight: .semibold)
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
        case press
        case fast
        case normal
        case emphasis
    }

    static func animation(_ preset: Preset, reduced: Bool = false) -> Animation? {
        guard !reduced else { return nil }
        switch preset {
        case .press:
            return .snappy(duration: 0.12, extraBounce: 0)
        case .fast:
            return .snappy(duration: 0.18, extraBounce: 0)
        case .normal:
            return .smooth(duration: 0.24)
        case .emphasis:
            return .smooth(duration: 0.30)
        }
    }

    static func shouldReduceMotion(reduceAnimations: Bool, accessibilityReduceMotion: Bool) -> Bool {
        reduceAnimations || accessibilityReduceMotion
    }
}
