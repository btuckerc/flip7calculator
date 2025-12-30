//
//  Flip7TitleView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/30/25.
//

import SwiftUI

// MARK: - Design Constants

private enum Flip7Style {
    // From box art - inside to out: yellow, blue, red, blue
    static let yellow = Color(red: 0.98, green: 0.82, blue: 0.18)
    static let blue = Color(red: 0.14, green: 0.24, blue: 0.52)
    static let red = Color(red: 0.88, green: 0.30, blue: 0.30)

    // Typography
    static let fontBlackName = "Nunito-Black"
    static let fontBoldName = "Nunito-Bold"
}

// MARK: - Main Title View

struct Flip7TitleView: View {
    @AppStorage("animateMainMenuTitle") private var animateMainMenuTitle: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    
    private var shouldAnimate: Bool {
        animateMainMenuTitle && !reduceAnimations && !accessibilityReduceMotion
    }
    
    var body: some View {
        Group {
            if shouldAnimate {
                Flip7LogoAnimated()
            } else {
                Flip7LogoStatic()
            }
        }
        .frame(height: 160)
    }
}

// MARK: - Animated Logo

private struct Flip7LogoAnimated: View {
    @State private var flipAngle: Double = 0
    @State private var flipScale: CGFloat = 1.0
    @State private var startTime: Date = Date()
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(startTime)
            
            // Iridescence: loops every 5 seconds
            let iridescentPhase = CGFloat((time / 5.0).truncatingRemainder(dividingBy: 1.0))
            
            // Wobble: ±5 degrees, ~2.5 second cycle (slower, more noticeable)
            let wobble = 5.0 * sin(time * 0.8 * .pi)
            
            ZStack {
                // Iridescent background (kept same size)
                iridescenceBackground(phase: iridescentPhase)
                
                // Logo - tighter spacing between word and 7, more kerning in FLIP
                HStack(spacing: 12) {
                    outlinedText("FLIP", fontSize: 74, kerning: 5)
                    
                    // 7 with separate holographic overlay
                    ZStack {
                        // Base 7 that rotates
                        outlinedSevenBase(wobble: wobble)
                        
                        // Holographic band - mask rotates with 7, band stays in world space
                        holographicBand(phase: iridescentPhase)
                            .mask(
                                Text("7")
                                    .font(.custom(Flip7Style.fontBlackName, size: 92))
                                    // Match the 7's rotations so mask follows visible surface
                                    .rotation3DEffect(
                                        .degrees(wobble),
                                        axis: (x: 0, y: 1, z: 0),
                                        perspective: 0.5
                                    )
                                    .rotation3DEffect(
                                        .degrees(flipAngle),
                                        axis: (x: 0, y: 1, z: 0),
                                        perspective: 0.5
                                    )
                                    .scaleEffect(flipScale)
                            )
                    }
                }
            }
        }
        .onAppear {
            startTime = Date()
            startFlipLoop()
        }
    }
    
    private func startFlipLoop() {
        Task {
            try? await Task.sleep(for: .seconds(7))
            
            while !Task.isCancelled {
                await doFlip()
                try? await Task.sleep(for: .seconds(7))
            }
        }
    }
    
    @MainActor
    private func doFlip() async {
        // Slow, smooth flip - methodical and satisfying
        withAnimation(.easeInOut(duration: 0.9)) {
            flipAngle = 360
            flipScale = 1.02
        }
        
        try? await Task.sleep(for: .seconds(1.0))
        
        flipAngle = 0
        flipScale = 1.0
    }
    
    // MARK: - Iridescent Background
    
    private func iridescenceBackground(phase: CGFloat) -> some View {
        let colors: [Color] = (0..<12).map { i in
            let hue = (CGFloat(i) / 12.0 + phase).truncatingRemainder(dividingBy: 1.0)
            return Color(hue: hue, saturation: 0.45, brightness: 1.0)
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 320, height: 95)
        .blur(radius: 30)
        .opacity(0.5)
    }
    
    // MARK: - Outlined FLIP Text (crisp outlines like box art)
    // Layer order from back to front: blue outer → red → blue inner → yellow fill
    // Each layer covers the one behind it, leaving visible bands
    
    private func outlinedText(_ text: String, fontSize: CGFloat, kerning: CGFloat) -> some View {
        ZStack {
            // Layer 1 (BACK): Blue outer outline
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.blue, radius: 5.0, kerning: kerning)
            
            // Layer 2: Red outline (covers part of blue outer, leaving blue outer band visible)
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.red, radius: 3.2, kerning: kerning)
            
            // Layer 3: Blue inner outline (covers part of red, leaving red band visible)
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.blue, radius: 1.6, kerning: kerning)
            
            // Layer 4 (FRONT): Yellow fill (covers part of blue inner, leaving blue inner band visible)
            Text(text)
                .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                .foregroundStyle(Flip7Style.yellow)
                .kerning(kerning)
        }
        .compositingGroup()  // Flatten all copies into one layer BEFORE shadow
        .shadow(color: .black.opacity(0.5), radius: 1, x: 2, y: 3)
    }
    
    // Creates outline by placing 16 copies around a circle at given radius
    // 16 copies at 22.5° intervals ensures full coverage on all edges
    private func outlineLayer(text: String, fontSize: CGFloat, color: Color, radius: CGFloat, kerning: CGFloat) -> some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) * .pi * 2.0 / 16.0  // 16 directions
                Text(text)
                    .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                    .foregroundStyle(color)
                    .kerning(kerning)
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
    }
    
    // MARK: - Outlined 7 (base without holographic effect)
    
    private func outlinedSevenBase(wobble: Double) -> some View {
        ZStack {
            // Layer 1 (BACK): Blue outer outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.blue, radius: 5.5, kerning: 0)
            
            // Layer 2: Red outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.red, radius: 3.5, kerning: 0)
            
            // Layer 3: Blue inner outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.blue, radius: 1.8, kerning: 0)
            
            // Layer 4 (FRONT): Yellow fill
            Text("7")
                .font(.custom(Flip7Style.fontBlackName, size: 92))
                .foregroundStyle(Flip7Style.yellow)
        }
        .compositingGroup()  // Flatten all copies into one layer BEFORE shadow
        .shadow(color: .black.opacity(0.5), radius: 1, x: 2, y: 3)
        // 3D yaw wobble - the 7 tilts left and right
        .rotation3DEffect(
            .degrees(wobble),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        // Flip animation
        .rotation3DEffect(
            .degrees(flipAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .scaleEffect(flipScale)
    }
    
    // MARK: - Holographic Band (independent of flip)
    
    private func holographicBand(phase: CGFloat) -> some View {
        // Pearlescent gradient matching app icon - soft cream, mint, lavender
        let pearlGradient = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.95, blue: 0.88),   // Soft cream/peach
                Color(red: 0.92, green: 0.98, blue: 0.94), // Light mint
                Color(red: 0.88, green: 0.94, blue: 0.98), // Soft sky blue
                Color(red: 0.94, green: 0.90, blue: 0.98), // Soft lavender
                Color(red: 0.98, green: 0.92, blue: 0.96), // Light pink
                Color(red: 1.0, green: 0.95, blue: 0.88),  // Back to cream
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Moving band that reveals the pearlescent colors
        let revealBand = LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: max(0, phase - 0.18)),
                .init(color: .white.opacity(0.6), location: max(0, phase - 0.05)),
                .init(color: .white, location: phase),
                .init(color: .white.opacity(0.6), location: min(1, phase + 0.05)),
                .init(color: .clear, location: min(1, phase + 0.18)),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        return Rectangle()
            .fill(pearlGradient)
            .frame(width: 70, height: 110)
            .mask(Rectangle().fill(revealBand))
            .blendMode(.plusLighter)
            .opacity(0.7)
    }
    
}

// MARK: - Static Logo

private struct Flip7LogoStatic: View {
    var body: some View {
        ZStack {
            // Static iridescent background (same size)
            LinearGradient(
                colors: [
                    Color(hue: 0.0, saturation: 0.3, brightness: 1.0),
                    Color(hue: 0.2, saturation: 0.25, brightness: 1.0),
                    Color(hue: 0.4, saturation: 0.3, brightness: 1.0),
                    Color(hue: 0.6, saturation: 0.25, brightness: 1.0),
                    Color(hue: 0.8, saturation: 0.3, brightness: 1.0),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 320, height: 95)
            .blur(radius: 30)
            .opacity(0.4)
            
            HStack(spacing: 12) {
                outlinedText("FLIP", fontSize: 74, kerning: 5)
                outlinedSeven
            }
        }
    }
    
    private func outlinedText(_ text: String, fontSize: CGFloat, kerning: CGFloat) -> some View {
        ZStack {
            // Layer 1 (BACK): Blue outer outline
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.blue, radius: 5.0, kerning: kerning)
            
            // Layer 2: Red outline
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.red, radius: 3.2, kerning: kerning)
            
            // Layer 3: Blue inner outline
            outlineLayer(text: text, fontSize: fontSize, color: Flip7Style.blue, radius: 1.6, kerning: kerning)
            
            // Layer 4 (FRONT): Yellow fill
            Text(text)
                .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                .foregroundStyle(Flip7Style.yellow)
                .kerning(kerning)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 1, x: 2, y: 3)
    }
    
    private var outlinedSeven: some View {
        ZStack {
            // Layer 1 (BACK): Blue outer outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.blue, radius: 5.5, kerning: 0)
            
            // Layer 2: Red outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.red, radius: 3.5, kerning: 0)
            
            // Layer 3: Blue inner outline
            outlineLayer(text: "7", fontSize: 92, color: Flip7Style.blue, radius: 1.8, kerning: 0)
            
            // Layer 4 (FRONT): Yellow fill
            Text("7")
                .font(.custom(Flip7Style.fontBlackName, size: 92))
                .foregroundStyle(Flip7Style.yellow)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 1, x: 2, y: 3)
    }
    
    // Creates outline by placing 16 copies around a circle at given radius
    private func outlineLayer(text: String, fontSize: CGFloat, color: Color, radius: CGFloat, kerning: CGFloat) -> some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) * .pi * 2.0 / 16.0
                Text(text)
                    .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                    .foregroundStyle(color)
                    .kerning(kerning)
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
    }
}

// MARK: - Compact Wordmark (for splash screen)

/// Lightweight wordmark optimized for small display contexts like the splash screen.
/// Uses 8 outline copies instead of 16 and drawingGroup() for efficient rendering.
struct Flip7WordmarkCompact: View {
    var fontSize: CGFloat = 16
    
    // Scale outline radii proportionally to font size
    // Base ratios from main logo (fontSize 74): outer=5.0, red=3.2, inner=1.6
    // Slightly thicker than pure ratio to maintain visibility at small sizes
    private var outerRadius: CGFloat { fontSize * 0.08 }
    private var redRadius: CGFloat { fontSize * 0.052 }
    private var innerRadius: CGFloat { fontSize * 0.026 }
    
    // Kerning scaled from main logo (kerning 5 at fontSize 74)
    private var kerning: CGFloat { fontSize * 0.04 }
    
    // Padding needed to prevent outline/shadow clipping in drawingGroup bitmap
    private var contentPadding: CGFloat { outerRadius + 2 }
    
    var body: some View {
        HStack(spacing: fontSize * 0.06) {
            outlinedText("FLIP")
            outlinedText("7", kerning: 0)
        }
        .padding(contentPadding) // Expand layout bounds to include outline offsets + shadow
        .drawingGroup() // Rasterize for performance - clips to layout bounds
    }
    
    private func outlinedText(_ text: String, kerning: CGFloat? = nil) -> some View {
        let k = kerning ?? self.kerning
        
        return ZStack {
            // Layer 1 (BACK): Blue outer outline - 8 copies
            compactOutlineLayer(text: text, color: Flip7Style.blue, radius: outerRadius, kerning: k)
            
            // Layer 2: Red outline
            compactOutlineLayer(text: text, color: Flip7Style.red, radius: redRadius, kerning: k)
            
            // Layer 3: Blue inner outline
            compactOutlineLayer(text: text, color: Flip7Style.blue, radius: innerRadius, kerning: k)
            
            // Layer 4 (FRONT): Yellow fill
            Text(text)
                .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                .foregroundStyle(Flip7Style.yellow)
                .kerning(k)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.4), radius: 0.5, x: 1, y: 1)
    }
    
    // Efficient outline using 8 directions (cardinal + diagonal)
    private func compactOutlineLayer(text: String, color: Color, radius: CGFloat, kerning: CGFloat) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi * 2.0 / 8.0  // 8 directions (45° apart)
                Text(text)
                    .font(.custom(Flip7Style.fontBlackName, size: fontSize))
                    .foregroundStyle(color)
                    .kerning(kerning)
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("Animated") {
    VStack {
        Flip7TitleView()
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}

#Preview("Static") {
    VStack {
        Flip7LogoStatic()
            .frame(height: 140)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Wordmark") {
    VStack(spacing: 20) {
        // Simulated calculator display context
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.94, green: 0.94, blue: 0.95))
                .frame(width: 170, height: 48)
            
            Flip7WordmarkCompact(fontSize: 16)
        }
        
        // Larger size for comparison
        Flip7WordmarkCompact(fontSize: 24)
        
        Spacer()
    }
    .padding(.top, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
