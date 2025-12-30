//
//  PlayerPaletteTests.swift
//  flip7calculatorTests
//
//  Tests for player color palettes ensuring distinctness and safety from reserved colors.
//

import Testing
import SwiftUI
@testable import flip7calculator

struct PlayerPaletteTests {
    
    // MARK: - Palette Color Count Tests
    
    @Test("Each palette has exactly 8 colors")
    func testAllPalettesHave8Colors() {
        for palette in PlayerPalette.allCases {
            #expect(palette.colors.count == 8, "Palette \(palette.displayName) should have 8 colors")
        }
    }
    
    // MARK: - Reserved Color Distance Tests
    
    @Test("Classic palette colors are safe from reserved colors")
    func testClassicPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.classic)
    }
    
    @Test("Ocean palette colors are safe from reserved colors")
    func testOceanPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.ocean)
    }
    
    @Test("Warm palette colors are safe from reserved colors")
    func testWarmPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.warm)
    }
    
    @Test("Neon palette colors are safe from reserved colors")
    func testNeonPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.neon)
    }
    
    @Test("Pastel palette colors are safe from reserved colors")
    func testPastelPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.pastel)
    }
    
    @Test("Jewel palette colors are safe from reserved colors")
    func testJewelPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.jewel)
    }
    
    @Test("Earth palette colors are safe from reserved colors")
    func testEarthPaletteSafeFromReserved() {
        validatePaletteSafeFromReserved(.earth)
    }
    
    // MARK: - Inter-Color Distinctness Tests
    
    @Test("Classic palette colors are distinct from each other")
    func testClassicPaletteDistinctness() {
        validatePaletteDistinctness(.classic)
    }
    
    @Test("Ocean palette colors are distinct from each other")
    func testOceanPaletteDistinctness() {
        validatePaletteDistinctness(.ocean)
    }
    
    @Test("Warm palette colors are distinct from each other")
    func testWarmPaletteDistinctness() {
        validatePaletteDistinctness(.warm)
    }
    
    @Test("Neon palette colors are distinct from each other")
    func testNeonPaletteDistinctness() {
        validatePaletteDistinctness(.neon)
    }
    
    @Test("Pastel palette colors are distinct from each other")
    func testPastelPaletteDistinctness() {
        validatePaletteDistinctness(.pastel)
    }
    
    @Test("Jewel palette colors are distinct from each other")
    func testJewelPaletteDistinctness() {
        validatePaletteDistinctness(.jewel)
    }
    
    @Test("Earth palette colors are distinct from each other")
    func testEarthPaletteDistinctness() {
        validatePaletteDistinctness(.earth)
    }
    
    // MARK: - Legacy Migration Tests
    
    @Test("Legacy 'classic' palette migrates correctly")
    func testClassicMigration() {
        let migrated = PlayerPalette.fromLegacyRawValue("Classic")
        #expect(migrated == .jewel)
    }
    
    @Test("Legacy 'cool' palette migrates correctly")
    func testCoolMigration() {
        let migrated = PlayerPalette.fromLegacyRawValue("Cool")
        #expect(migrated == .ocean)
    }
    
    @Test("Legacy 'muted' palette migrates correctly")
    func testMutedMigration() {
        let migrated = PlayerPalette.fromLegacyRawValue("Muted")
        #expect(migrated == .earth)
    }
    
    @Test("Legacy 'candy' palette migrates correctly")
    func testCandyMigration() {
        let migrated = PlayerPalette.fromLegacyRawValue("Candy")
        #expect(migrated == .pastel)
    }
    
    @Test("Unknown legacy palette defaults to ocean")
    func testUnknownMigration() {
        let migrated = PlayerPalette.fromLegacyRawValue("NonExistent")
        #expect(migrated == .ocean)
    }
    
    @Test("Direct new palette names work via rawValue")
    func testDirectNewPaletteNames() {
        #expect(PlayerPalette(rawValue: "Ocean") == .ocean)
        #expect(PlayerPalette(rawValue: "Warm") == .warm)
        #expect(PlayerPalette(rawValue: "Neon") == .neon)
        #expect(PlayerPalette(rawValue: "Pastel") == .pastel)
        #expect(PlayerPalette(rawValue: "Jewel") == .jewel)
        #expect(PlayerPalette(rawValue: "Earth") == .earth)
    }
    
    // MARK: - Color Resolver Tests
    
    @Test("PlayerColorResolver returns correct number of colors")
    func testColorResolverCount() {
        for palette in PlayerPalette.allCases {
            for count in 1...8 {
                let colors = PlayerColorResolver.colors(count: count, palette: palette)
                #expect(colors.count == count, "Should return \(count) colors for palette \(palette.displayName)")
            }
        }
    }
    
    @Test("PlayerColorResolver returns empty array for count 0")
    func testColorResolverZeroCount() {
        for palette in PlayerPalette.allCases {
            let colors = PlayerColorResolver.colors(count: 0, palette: palette)
            #expect(colors.isEmpty)
        }
    }
    
    @Test("Preview colors returns 6 colors")
    func testPreviewColors() {
        for palette in PlayerPalette.allCases {
            let preview = PlayerColorResolver.previewColors(palette: palette)
            #expect(preview.count == 6)
        }
    }
    
    // MARK: - Validation Test
    
    @Test("Validation reports no issues for all palettes")
    func testValidationReportsNoIssues() {
        for palette in PlayerPalette.allCases {
            let issues = PlayerColorResolver.validatePalette(palette)
            #expect(issues.isEmpty, "Palette \(palette.displayName) has issues: \(issues.joined(separator: ", "))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func validatePaletteSafeFromReserved(_ palette: PlayerPalette) {
        let colors = palette.colors
        for (index, color) in colors.enumerated() {
            let isSafe = ColorDistance.isSafeFromReserved(color)
            let nearestDistance = ColorDistance.distanceToNearestReserved(color)
            #expect(isSafe, "Color \(index + 1) in \(palette.displayName) is too close to reserved colors (distance: \(String(format: "%.3f", nearestDistance)))")
        }
    }
    
    private func validatePaletteDistinctness(_ palette: PlayerPalette) {
        let colors = palette.colors
        let areDistinct = ColorDistance.areDistinct(colors)
        let minSeparation = ColorDistance.minimumSeparation(colors)
        #expect(areDistinct, "Colors in \(palette.displayName) are not distinct enough (min separation: \(String(format: "%.3f", minSeparation)))")
    }
}

// MARK: - Color Distance Tests

struct ColorDistanceTests {
    
    @Test("sRGB distance of identical colors is 0")
    func testIdenticalColorsDistance() {
        let color = Color.red
        let distance = ColorDistance.sRGBDistance(color, color)
        #expect(distance == 0)
    }
    
    @Test("sRGB distance of black and white is approximately sqrt(3)")
    func testBlackWhiteDistance() {
        let black = Color(red: 0, green: 0, blue: 0)
        let white = Color(red: 1, green: 1, blue: 1)
        let distance = ColorDistance.sRGBDistance(black, white)
        // sqrt(1 + 1 + 1) ≈ 1.732
        #expect(abs(distance - 1.732) < 0.01)
    }
    
    @Test("Perceptual distance weights green more heavily")
    func testPerceptualDistanceWeighting() {
        let black = Color(red: 0, green: 0, blue: 0)
        let pureRed = Color(red: 1, green: 0, blue: 0)
        let pureGreen = Color(red: 0, green: 1, blue: 0)
        
        let redDistance = ColorDistance.perceptualDistance(black, pureRed)
        let greenDistance = ColorDistance.perceptualDistance(black, pureGreen)
        
        // Green should have higher perceptual distance due to higher weight (0.59 vs 0.30)
        #expect(greenDistance > redDistance)
    }
    
    @Test("Minimum separation calculation works")
    func testMinimumSeparation() {
        let colors = [
            Color(red: 0, green: 0, blue: 0),    // black
            Color(red: 1, green: 1, blue: 1),    // white
            Color(red: 0.5, green: 0.5, blue: 0.5)  // gray
        ]
        
        let minSep = ColorDistance.minimumSeparation(colors)
        // Gray is equidistant from black and white, both at distance ~0.433 (perceptual)
        #expect(minSep > 0)
        #expect(minSep < 1)
    }
}

// MARK: - Color Extension Tests

struct ColorExtensionTests {
    
    @Test("RGB components extraction works")
    func testRGBComponentsExtraction() {
        let red = Color(red: 1, green: 0, blue: 0)
        let components = red.rgbComponents
        #expect(abs(components.red - 1.0) < 0.01)
        #expect(abs(components.green - 0.0) < 0.01)
        #expect(abs(components.blue - 0.0) < 0.01)
    }
    
    @Test("Relative luminance of black is 0")
    func testBlackLuminance() {
        let black = Color(red: 0, green: 0, blue: 0)
        #expect(black.relativeLuminance < 0.01)
    }
    
    @Test("Relative luminance of white is 1")
    func testWhiteLuminance() {
        let white = Color(red: 1, green: 1, blue: 1)
        #expect(abs(white.relativeLuminance - 1.0) < 0.01)
    }
    
    @Test("Dark colors have white contrasting foreground")
    func testDarkColorsGetWhiteForeground() {
        let darkBlue = Color(red: 0.1, green: 0.1, blue: 0.3)
        #expect(darkBlue.contrastingForeground == .white)
    }
    
    @Test("Light colors have black contrasting foreground")
    func testLightColorsGetBlackForeground() {
        let lightYellow = Color(red: 1, green: 1, blue: 0.8)
        #expect(lightYellow.contrastingForeground == .black)
    }
    
    @Test("Hex color factory works for 6-digit hex")
    func testHexFactory() {
        let red = Color.hex("FF0000")
        let components = red.rgbComponents
        #expect(abs(components.red - 1.0) < 0.01)
        #expect(abs(components.green - 0.0) < 0.01)
        #expect(abs(components.blue - 0.0) < 0.01)
    }
    
    @Test("Hex color factory handles # prefix")
    func testHexFactoryWithHash() {
        let green = Color.hex("#00FF00")
        let components = green.rgbComponents
        #expect(abs(components.red - 0.0) < 0.01)
        #expect(abs(components.green - 1.0) < 0.01)
        #expect(abs(components.blue - 0.0) < 0.01)
    }
}

