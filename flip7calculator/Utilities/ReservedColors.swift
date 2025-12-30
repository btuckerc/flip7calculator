//
//  ReservedColors.swift
//  flip7calculator
//
//  Reserved action colors that player colors must not collide with.
//

import SwiftUI
import UIKit

/// Reserved colors used for game actions that player colors must stay distinct from.
/// These are used for Bank (green), Bust (red), and Freeze (cyan) actions.
struct ReservedColors {
    
    // MARK: - Action Colors (from GameView action pills)
    
    /// Bank action - system green
    static let bankGreen = Color.green
    
    /// Bust action - system red
    static let bustRed = Color.red
    
    /// Freeze action - system cyan
    static let freezeCyan = Color.cyan
    
    // MARK: - State Frame Colors (from PlayerGrid)
    
    /// Banked state frame - vibrant green
    static let bankedFrameGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    
    /// Busted state frame - vivid red
    static let bustedFrameRed = Color(red: 0.95, green: 0.25, blue: 0.25)
    
    /// Frozen state frame - icy cyan-white
    static let frozenFrameCyan = Color(red: 0.55, green: 0.85, blue: 1.0)
    
    /// Secondary frost highlight color
    static let frozenHighlight = Color(red: 0.85, green: 0.95, blue: 1.0)
    
    // MARK: - All Reserved Colors for Collision Detection
    
    /// All reserved colors that player colors should stay distinct from
    static let all: [Color] = [
        bankGreen,
        bustRed,
        freezeCyan,
        bankedFrameGreen,
        bustedFrameRed,
        frozenFrameCyan,
        frozenHighlight
    ]
    
    /// Primary reserved colors (most important to avoid)
    static let primary: [Color] = [
        bankGreen,
        bustRed,
        freezeCyan
    ]
}

// MARK: - Color Distance Utilities

struct ColorDistance {
    
    /// Minimum acceptable distance from reserved colors (0-1 scale, where 1 is max distance)
    /// 0.15 means colors must be at least 15% different from reserved colors
    static let minimumReservedDistance: Double = 0.15
    
    /// Minimum acceptable distance between player colors for distinctness
    /// 0.10 means adjacent player colors must be at least 10% different
    static let minimumPlayerSeparation: Double = 0.10
    
    /// Computes Euclidean distance between two colors in sRGB space (0-1 range)
    /// Returns a value between 0 (identical) and ~1.73 (black to white diagonal)
    static func sRGBDistance(_ color1: Color, _ color2: Color) -> Double {
        let rgb1 = color1.rgbComponents
        let rgb2 = color2.rgbComponents
        
        let dr = rgb1.red - rgb2.red
        let dg = rgb1.green - rgb2.green
        let db = rgb1.blue - rgb2.blue
        
        return sqrt(dr * dr + dg * dg + db * db)
    }
    
    /// Computes perceptual distance using weighted RGB (approximates human perception)
    /// Weights: R=0.30, G=0.59, B=0.11 (luminance weights)
    static func perceptualDistance(_ color1: Color, _ color2: Color) -> Double {
        let rgb1 = color1.rgbComponents
        let rgb2 = color2.rgbComponents
        
        let dr = rgb1.red - rgb2.red
        let dg = rgb1.green - rgb2.green
        let db = rgb1.blue - rgb2.blue
        
        // Weighted distance that accounts for human color perception
        return sqrt(0.30 * dr * dr + 0.59 * dg * dg + 0.11 * db * db)
    }
    
    /// Checks if a color is too close to any reserved color
    /// Returns true if the color is safe (far enough from all reserved colors)
    static func isSafeFromReserved(_ color: Color, threshold: Double = minimumReservedDistance) -> Bool {
        for reserved in ReservedColors.primary {
            if perceptualDistance(color, reserved) < threshold {
                return false
            }
        }
        return true
    }
    
    /// Returns the minimum distance from a color to any reserved color
    static func distanceToNearestReserved(_ color: Color) -> Double {
        var minDistance = Double.infinity
        for reserved in ReservedColors.primary {
            let distance = perceptualDistance(color, reserved)
            minDistance = min(minDistance, distance)
        }
        return minDistance
    }
    
    /// Checks if all colors in an array are sufficiently distinct from each other
    static func areDistinct(_ colors: [Color], threshold: Double = minimumPlayerSeparation) -> Bool {
        for i in 0..<colors.count {
            for j in (i + 1)..<colors.count {
                if perceptualDistance(colors[i], colors[j]) < threshold {
                    return false
                }
            }
        }
        return true
    }
    
    /// Returns the minimum distance between any two colors in the array
    static func minimumSeparation(_ colors: [Color]) -> Double {
        var minDistance = Double.infinity
        for i in 0..<colors.count {
            for j in (i + 1)..<colors.count {
                let distance = perceptualDistance(colors[i], colors[j])
                minDistance = min(minDistance, distance)
            }
        }
        return minDistance
    }
}

// MARK: - Color Extension for RGB Components

extension Color {
    /// Extracts RGB components (0-1 range) from a SwiftUI Color
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue))
    }
    
    /// Computes relative luminance (WCAG formula)
    /// Returns a value between 0 (black) and 1 (white)
    var relativeLuminance: Double {
        let rgb = rgbComponents
        
        // Convert to linear RGB
        func linearize(_ c: Double) -> Double {
            if c <= 0.03928 {
                return c / 12.92
            } else {
                return pow((c + 0.055) / 1.055, 2.4)
            }
        }
        
        let r = linearize(rgb.red)
        let g = linearize(rgb.green)
        let b = linearize(rgb.blue)
        
        // WCAG luminance formula
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Returns true if the color is considered "light" (luminance > 0.5)
    var isLight: Bool {
        relativeLuminance > 0.5
    }
    
    /// Returns the best contrasting foreground color (black or white)
    var contrastingForeground: Color {
        // Use a threshold slightly below 0.5 to favor white text (better readability on medium colors)
        relativeLuminance > 0.45 ? .black : .white
    }
    
    /// Creates a Color from a hex string (e.g., "#FF5733" or "FF5733")
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 6: // RGB (24-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        case 8: // ARGB (32-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
        }
        
        return Color(red: r, green: g, blue: b)
    }
}

