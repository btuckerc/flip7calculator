//
//  PlayerPalette.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

/// Player color palette themes - each with a unique curated 8-color set.
/// Colors are carefully chosen to:
/// - Stay distinct from action colors (Bank green, Bust red, Freeze cyan)
/// - Remain visually distinct from each other for up to 8 players
/// - Feel comfortable and avoid harsh/ugly colors
enum PlayerPalette: String, CaseIterable {
    case classic = "Classic"
    case ocean = "Ocean"
    case warm = "Warm"
    case neon = "Neon"
    case pastel = "Pastel"
    case jewel = "Jewel"
    case earth = "Earth"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .classic: return "suit.spade.fill"
        case .ocean: return "water.waves"
        case .warm: return "sun.max.fill"
        case .neon: return "sparkles"
        case .pastel: return "cloud.fill"
        case .jewel: return "diamond.fill"
        case .earth: return "leaf.fill"
        }
    }
    
    /// The curated 8-color set for this palette.
    /// Colors are ordered for maximum visual separation when assigned sequentially.
    var colors: [Color] {
        switch self {
        case .classic:
            return Self.classicColors
        case .ocean:
            return Self.oceanColors
        case .warm:
            return Self.warmColors
        case .neon:
            return Self.neonColors
        case .pastel:
            return Self.pastelColors
        case .jewel:
            return Self.jewelColors
        case .earth:
            return Self.earthColors
        }
    }
    
    // MARK: - Classic Theme (Default)
    // Clean, familiar game colors. Maximum distinction.
    // Avoids red/green/cyan. One color per hue family.
    private static let classicColors: [Color] = [
        Color.hex("FBBF24"),  // Gold
        Color.hex("8B5CF6"),  // Purple
        Color.hex("EC4899"),  // Pink
        Color.hex("2563EB"),  // Blue
        Color.hex("64748B"),  // Slate
        Color.hex("F97316"),  // Orange
        Color.hex("D946EF"),  // Fuchsia
        Color.hex("0D9488"),  // Teal
    ]
    
    // MARK: - Ocean Theme
    // Sea and sky inspired. Blues with warm accents.
    private static let oceanColors: [Color] = [
        Color.hex("1E3A8A"),  // Navy
        Color.hex("0284C7"),  // Sky blue
        Color.hex("0D9488"),  // Teal
        Color.hex("7C3AED"),  // Violet
        Color.hex("D97706"),  // Amber sand
        Color.hex("64748B"),  // Slate
        Color.hex("8B5CF6"),  // Lavender
        Color.hex("EC4899"),  // Coral
    ]
    
    // MARK: - Warm Theme
    // Sunset vibes. Variety of warm hues.
    private static let warmColors: [Color] = [
        Color.hex("FBBF24"),  // Gold
        Color.hex("EC4899"),  // Hot pink
        Color.hex("F97316"),  // Orange
        Color.hex("A855F7"),  // Violet
        Color.hex("D97706"),  // Amber
        Color.hex("F472B6"),  // Coral
        Color.hex("C026D3"),  // Magenta
        Color.hex("92400E"),  // Brown
    ]
    
    // MARK: - Neon Theme
    // Electric and vibrant. High energy.
    private static let neonColors: [Color] = [
        Color.hex("A855F7"),  // Electric purple
        Color.hex("EC4899"),  // Hot pink
        Color.hex("FBBF24"),  // Gold
        Color.hex("2563EB"),  // Electric blue
        Color.hex("F97316"),  // Neon orange
        Color.hex("D946EF"),  // Fuchsia
        Color.hex("6366F1"),  // Indigo
        Color.hex("0D9488"),  // Teal
    ]
    
    // MARK: - Pastel Theme
    // Soft and gentle. Easy on the eyes.
    private static let pastelColors: [Color] = [
        Color.hex("93C5FD"),  // Sky
        Color.hex("C4B5FD"),  // Lavender
        Color.hex("FDE047"),  // Lemon
        Color.hex("F9A8D4"),  // Rose
        Color.hex("FDBA74"),  // Peach
        Color.hex("D8B4FE"),  // Wisteria
        Color.hex("F0ABFC"),  // Orchid
        Color.hex("94A3B8"),  // Slate
    ]
    
    // MARK: - Jewel Theme
    // Rich and luxurious. Deep saturated tones.
    private static let jewelColors: [Color] = [
        Color.hex("7E22CE"),  // Amethyst
        Color.hex("1D4ED8"),  // Sapphire
        Color.hex("CA8A04"),  // Citrine
        Color.hex("BE185D"),  // Ruby rose
        Color.hex("4338CA"),  // Indigo
        Color.hex("D946EF"),  // Fuchsia
        Color.hex("0D9488"),  // Jade
        Color.hex("F59E0B"),  // Topaz
    ]
    
    // MARK: - Earth Theme
    // Natural and grounded. With accent colors.
    private static let earthColors: [Color] = [
        Color.hex("78716C"),  // Stone
        Color.hex("A16207"),  // Ochre
        Color.hex("92400E"),  // Sienna
        Color.hex("64748B"),  // Slate
        Color.hex("854D0E"),  // Umber
        Color.hex("7C3AED"),  // Violet (wildflower)
        Color.hex("0D9488"),  // Teal (water)
        Color.hex("44403C"),  // Charcoal
    ]
}

/// Resolves player colors from palettes.
/// Provides backward compatibility and convenient access methods.
struct PlayerColorResolver {
    
    /// Generates distinct colors for any number of players using the specified palette.
    /// - Parameters:
    ///   - count: Number of players (1-8)
    ///   - palette: The color palette to use
    /// - Returns: Array of colors for each player
    static func colors(count: Int, palette: PlayerPalette) -> [Color] {
        guard count > 0 else { return [] }
        let paletteColors = palette.colors
        return Array(paletteColors.prefix(min(count, paletteColors.count)))
    }
    
    /// Returns preview colors for a palette (shows first 6).
    /// Used in settings UI for palette selection.
    static func previewColors(palette: PlayerPalette) -> [Color] {
        return colors(count: 6, palette: palette)
    }
    
    /// Validates that a palette's colors are safe (for testing/debugging).
    /// Returns any issues found with the palette.
    static func validatePalette(_ palette: PlayerPalette) -> [String] {
        var issues: [String] = []
        let colors = palette.colors
        
        // Check distance from reserved colors
        for (index, color) in colors.enumerated() {
            if !ColorDistance.isSafeFromReserved(color) {
                let distance = ColorDistance.distanceToNearestReserved(color)
                issues.append("Color \(index + 1) in \(palette.displayName) is too close to a reserved color (distance: \(String(format: "%.3f", distance)))")
            }
        }
        
        // Check mutual distinctness
        for i in 0..<colors.count {
            for j in (i + 1)..<colors.count {
                let distance = ColorDistance.perceptualDistance(colors[i], colors[j])
                if distance < ColorDistance.minimumPlayerSeparation {
                    issues.append("Colors \(i + 1) and \(j + 1) in \(palette.displayName) are too similar (distance: \(String(format: "%.3f", distance)))")
                }
            }
        }
        
        return issues
    }
}

// MARK: - Migration Support

extension PlayerPalette {
    /// Maps old palette raw values to new ones for backward compatibility.
    /// Used when loading persisted settings that may have old palette names.
    static func fromLegacyRawValue(_ rawValue: String) -> PlayerPalette {
        // Direct match
        if let palette = PlayerPalette(rawValue: rawValue) {
            return palette
        }
        
        // Map old palette names to new ones
        switch rawValue.lowercased() {
        case "bold":
            return .jewel  // Rich, vibrant colors similar to old bold
        case "cool":
            return .ocean  // Cool tones map to ocean
        case "muted":
            return .earth  // Muted/desaturated maps to earth
        case "candy":
            return .pastel // Candy was lighter, pastel is similar
        default:
            return .classic  // Default to classic as the primary palette
        }
    }
}
