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
    static let scoreCalculatorTitle = "Score Calculator"
    static let scoreCalculatorDescription = "Use your physical cards. Enter cards or round scores."
    static let dealerTitle = "Simulator"
    static let dealerDescription = "Draw and play from an app-owned deck on this device."

    static var versionSummary: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let shortVersion = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }
}

enum AppBrandPalette {
    static let ink = Color.hex("182233")
    static let outline = Color.hex("213042")
    static let brandBlue = Color.hex("1F5CA3")
    static let brandBlueDeep = Color.hex("16447A")
    static let brandBlueSky = Color.hex("4682CA")
    static let blueGlow = Color.hex("6AA9E8")
    static let gold = Color.hex("F0C14B")
    static let goldDeep = Color.hex("8A5800")
    static let copper = Color.hex("E06B56")
    static let parchment = Color.hex("FFF9F0")
    static let sage = Color.hex("EDF3FB")
    static let mist = Color.hex("DCE6F0")
    static let jade = brandBlueSky
    static let slate = Color.hex("8FA1B5")
    static let night = Color.hex("0E2542")
    static let nightDeep = Color.hex("0E1B2E")
    static let card = parchment

    // Compatibility aliases while older references resolve.
    static let emerald = brandBlue
    static let emeraldDeep = brandBlueDeep

    static func screenBackground(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? nightDeep : Color.hex("F3F6FA")
    }

    static func panelFill(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.hex("142338") : Color.hex("FFFFFF")
    }

    static func cardFill(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.hex("162740") : parchment
    }

    static func cardBorder(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.09) : brandBlue.opacity(0.12)
    }

    static func keycapBorder(colorScheme: ColorScheme?) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.11) : brandBlue.opacity(0.14)
    }
}
