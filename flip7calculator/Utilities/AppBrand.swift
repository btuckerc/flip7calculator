//
//  AppBrand.swift
//  flip7calculator
//
//  Centralized brand and product copy for the app.
//

import SwiftUI

enum AppBrand {
    static let appName = "Flipping Seven Calculator"
    static let wordmarkLead = "FLIPPING"
    static let wordmarkSeven = "SEVEN"
    static let wordmarkDescriptor = "CALCULATOR"
    static let tagline = "Fast scorekeeping for one-more-card nights"
    static let shortDescription = "Fast flip-card scorekeeping"
    static let appStoreId = "6756905042"
    static let supportURL = "https://btuckerc.dev/contact"
    static let visualThemeV2Name = "Flipping Seven"
    static let independenceNotice = "Independent scorekeeping utility. Not affiliated with or endorsed by any game publisher."
    static let sevenCardBonusLabel = "7-Card Bonus"
    static let sevenCardBonusShortLabel = "7-Card"
    static let sevenCardBonusValue = ScoreEngine.sevenCardBonus
    static let setupHeroSummary = "Built for live tables: fast entry, clear scores, and low-friction round flow."

    static var versionSummary: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let shortVersion = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }
}

enum AppBrandPalette {
    static let ink = Color.hex("1E2636")
    static let outline = Color.hex("213042")
    static let brandBlue = Color.hex("205EA4")
    static let brandBlueDeep = Color.hex("184D8A")
    static let brandBlueSky = Color.hex("4A79C5")
    static let blueGlow = Color.hex("6BA8E5")
    static let gold = Color.hex("F1C24B")
    static let copper = Color.hex("E47B58")
    static let parchment = Color.hex("FFF7EB")
    static let sage = Color.hex("EDF3FB")
    static let mist = Color.hex("DCE6F0")
    static let jade = brandBlueSky
    static let slate = Color.hex("8FA1B5")
    static let night = Color.hex("0F3158")
    static let nightDeep = Color.hex("14243D")
    static let card = parchment

    // Compatibility aliases while the rebrand migrates older color names.
    static let emerald = brandBlue
    static let emeraldDeep = brandBlueDeep

    static func screenGradient(colorScheme: ColorScheme?) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    brandBlueDeep.opacity(0.92),
                    nightDeep,
                    night
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.hex("EEF4FC"),
                parchment,
                Color.hex("D3DDEA")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func panelFill(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.hex("122038") : Color.hex("EAF1FA")
    }

    static func cardFill(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.hex("16263D") : parchment
    }

    static func cardBorder(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? mist.opacity(0.18) : brandBlue.opacity(0.14)
    }
}
