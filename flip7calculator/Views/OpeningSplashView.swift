//
//  OpeningSplashView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/26/25.
//

import SwiftUI

// MARK: - Splash Theme (Modular Design Tokens)

/// Centralized theme configuration for the opening splash animation.
/// Modify these values to change the visual style without touching animation logic.
struct SplashTheme {
    // MARK: - Card Back Colors (matching official Flip 7 card backs)
    /// Primary fill color for card backs - teal from actual game cards
    var cardBackFill: Color = Color(red: 0.28, green: 0.56, blue: 0.58)
    /// Secondary color for card back gradient (subtle variation)
    var cardBackGradientEnd: Color = Color(red: 0.25, green: 0.52, blue: 0.54)
    /// Card back border/outline color - yellow/gold from game cards
    var cardBackBorder: Color = Color(red: 0.95, green: 0.78, blue: 0.22)
    /// Card back border width
    var cardBackBorderWidth: CGFloat = 2.0
    /// Card back pattern color (subtle teal lines)
    var cardBackPatternColor: Color = Color(red: 0.22, green: 0.48, blue: 0.50)
    /// Card back pattern line width
    var cardBackPatternLineWidth: CGFloat = 0.8
    /// Card back pattern spacing
    var cardBackPatternSpacing: CGFloat = 5
    
    // MARK: - Card Front Colors (matching official Flip 7 number cards)
    /// Card front background color - cream/off-white from game cards
    var cardFrontFill: Color = Color(red: 0.98, green: 0.96, blue: 0.90)
    /// Card front border color - teal to match card backs
    var cardFrontBorder: Color = Color(red: 0.28, green: 0.56, blue: 0.58)
    /// Card front border width
    var cardFrontBorderWidth: CGFloat = 2.0
    /// Primary text color for card numbers - teal matching the game
    var cardNumberColor: Color = Color(red: 0.28, green: 0.56, blue: 0.58)
    
    // MARK: - Calculator Button Colors (on-brand with Flip 7 aesthetic)
    /// Standard button fill color - cream/off-white matching card fronts
    var buttonFillColor: Color = Color(red: 0.98, green: 0.96, blue: 0.90)
    /// Accent button fill color - red from game's banner accents
    var accentButtonFillColor: Color = Color(red: 0.85, green: 0.28, blue: 0.28)
    /// Button text color - teal matching game theme
    var buttonTextColor: Color = Color(red: 0.28, green: 0.56, blue: 0.58)
    /// Accent button text color
    var accentButtonTextColor: Color = .white
    
    // MARK: - Calculator Body (teal/yellow Art Deco style matching cards)
    /// Calculator body fill color - teal matching card backs
    var calculatorBodyFill: Color = Color(red: 0.28, green: 0.56, blue: 0.58)
    /// Calculator body border color - yellow/gold matching card borders
    var calculatorBodyBorder: Color = Color(red: 0.95, green: 0.78, blue: 0.22)
    /// Calculator body border width
    var calculatorBodyBorderWidth: CGFloat = 3.5
    /// Calculator body corner radius
    var calculatorCornerRadius: CGFloat = 18
    /// Display area background color - cream matching card fronts
    var calculatorDisplayAreaFill: Color = Color(red: 0.98, green: 0.96, blue: 0.90)
    
    // MARK: - Typography
    /// Font design for all text
    var fontDesign: Font.Design = .rounded
    /// Card number font size (before morph)
    var cardNumberFontSize: CGFloat = 26
    /// Card number font weight
    var cardNumberFontWeight: Font.Weight = .bold
    /// Display text font size - sized for readable FLIP 7 wordmark
    var displayFontSize: CGFloat = 28
    /// Display font weight
    var displayFontWeight: Font.Weight = .heavy
    /// Button label font size
    var buttonFontSize: CGFloat = 18
    /// Button font weight
    var buttonFontWeight: Font.Weight = .bold
    
    // MARK: - Shadows (subtle, complementing teal theme)
    /// Card shadow color - teal-tinted for cohesion
    var cardShadowColor: Color = Color(red: 0.1, green: 0.25, blue: 0.28).opacity(0.35)
    /// Card shadow radius
    var cardShadowRadius: CGFloat = 4
    /// Calculator shadow color - deeper teal shadow
    var calculatorShadowColor: Color = Color(red: 0.1, green: 0.25, blue: 0.28).opacity(0.3)
    /// Calculator shadow radius
    var calculatorShadowRadius: CGFloat = 14
    
    // MARK: - Background
    /// Splash background color (nil uses system background)
    var backgroundColor: Color? = nil
    
    // MARK: - Presets
    
    /// Default theme matching the app icon style
    static let appIcon = SplashTheme()
    
    /// Alternative blue theme (original style)
    static let blue: SplashTheme = {
        var theme = SplashTheme()
        theme.cardBackFill = .blue
        theme.cardBackGradientEnd = .blue.opacity(0.8)
        theme.cardBackBorder = .white.opacity(0.3)
        theme.cardBackBorderWidth = 1.0
        theme.cardBackPatternColor = .white.opacity(0.15)
        theme.cardFrontBorder = .gray.opacity(0.3)
        theme.cardFrontBorderWidth = 1.0
        theme.cardNumberColor = .blue
        theme.buttonFillColor = .white
        theme.accentButtonFillColor = .white
        theme.buttonTextColor = .blue
        theme.accentButtonTextColor = .blue
        return theme
    }()
}

// MARK: - Animation Phase

enum SplashPhase: Int, CaseIterable {
    case initial = 0
    case deal = 1
    case flip = 2
    case morph = 3
    case exit = 4
    case complete = 5
}

// MARK: - Opening Splash View

struct OpeningSplashView: View {
    @Binding var isPresented: Bool
    var theme: SplashTheme = .appIcon
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    
    @State private var phase: SplashPhase = .initial
    @State private var cardDealtStates: [Bool] = Array(repeating: false, count: 7)
    @State private var cardFlipAngles: [Double] = Array(repeating: 0, count: 7)
    @State private var showCalculatorOutline = false
    @State private var showFlipText = false // Controls when "FLIP " fades in beside the "7"
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    
    @Namespace private var morphNamespace
    
    private let cardSize: CGSize = CGSize(width: 60, height: 84)
    // Cards dealt left to right: 1, 2, 3, 4, 5, 6, 7 (7 is last, on top)
    private let cardNumbers = [1, 2, 3, 4, 5, 6, 7]
    private let sevenCardIndex = 6 // Index of the "7" card (rightmost, dealt last)
    
    // Timing constants - smooth and clean
    private let dealDuration: Double = 0.10
    private let dealStagger: Double = 0.08
    private let flipDuration: Double = 0.30
    private let flipStagger: Double = 0.09
    private let morphDuration: Double = 0.45
    private let exitDuration: Double = 0.35
    
    private var shouldReduceMotion: Bool {
        reduceMotion || reduceAnimations
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                (theme.backgroundColor ?? Color(.systemBackground))
                    .ignoresSafeArea()
                
                if shouldReduceMotion {
                    // Simplified animation for reduce motion
                    reducedMotionContent
                } else {
                    // Full animation
                    fullAnimationContent(in: geometry)
                }
            }
        }
        .opacity(exitOpacity)
        .scaleEffect(exitScale)
        .onAppear {
            startAnimation()
        }
        .allowsHitTesting(phase != .complete)
    }
    
    // MARK: - Reduced Motion Content
    
    private var reducedMotionContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.cardBackFill)
            
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBackFill.opacity(0.2))
                        .frame(width: 24, height: 34)
                        .overlay(
                            Text("\(cardNumbers[index])")
                                .font(.system(size: 12, weight: theme.cardNumberFontWeight, design: theme.fontDesign))
                                .foregroundStyle(theme.cardNumberColor)
                        )
                }
            }
            
            Image(systemName: "calculator")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    exitOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    phase = .complete
                    isPresented = false
                }
            }
        }
    }
    
    // MARK: - Full Animation Content
    
    private func fullAnimationContent(in geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let isMorphed = phase.rawValue >= SplashPhase.morph.rawValue
        let sevenCardFlipped = cardFlipAngles[sevenCardIndex] >= 90
        
        return ZStack {
            // Calculator outline (fades in during morph)
            calculatorOutline
                .opacity(showCalculatorOutline ? 1 : 0)
                .position(center)
            
            // Cards (excluding 7 card content when flipped - that's handled by floating 7)
            ForEach(0..<7, id: \.self) { index in
                cardView(index: index, center: center, size: geometry.size)
            }
            
            // The floating "7" - this is THE 7 that moves from card to display
            // It appears once the 7 card is flipped, and animates to display position on morph
            if sevenCardFlipped {
                floatingSeven(center: center, isMorphed: isMorphed)
            }
        }
    }
    
    // MARK: - Floating Seven (the continuous "7" element)
    
    /// The "7" that moves from the card position to the calculator display.
    /// Same position math as the cards - just swapping in for the morphing 7.
    private func floatingSeven(center: CGPoint, isMorphed: Bool) -> some View {
        let cardPos = cardPosition(index: sevenCardIndex, center: center, size: .zero)
        let displayPosition = CGPoint(x: center.x, y: center.y + displayOffsetY)
        
        // Position: exactly at card position when not morphed, at display when morphed
        let position = isMorphed ? displayPosition : cardPos
        // Rotation: match fan angle when at card position, straight when in display
        let fanRotation = isMorphed ? 0.0 : (Double(sevenCardIndex) - 3.0) * 4.0
        
        return ZStack {
            // Plain card-style "7" - visible when on card, fades out when morphing
            Text("7")
                .font(.system(size: theme.cardNumberFontSize, weight: theme.cardNumberFontWeight, design: theme.fontDesign))
                .foregroundStyle(theme.cardNumberColor)
                .opacity(isMorphed ? 0 : 1)
            
            // Styled wordmark - fades in when morphing
            HStack(spacing: theme.displayFontSize * 0.08) {
                // "FLIP" fades in after morph settles
                if showFlipText {
                    Flip7StyledText(text: "FLIP", fontSize: theme.displayFontSize)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Styled "7"
                Flip7StyledText(text: "7", fontSize: theme.displayFontSize, kerning: 0)
            }
            .opacity(isMorphed ? 1 : 0)
        }
        .position(position)
        .rotationEffect(.degrees(fanRotation))
        .animation(.easeInOut(duration: 0.45), value: isMorphed)
        .animation(.easeOut(duration: 0.3), value: showFlipText)
        .zIndex(10) // Above cards
    }
    
    // MARK: - Card View
    
    private func cardView(index: Int, center: CGPoint, size: CGSize) -> some View {
        let position = cardPosition(index: index, center: center, size: size)
        let isDealt = cardDealtStates[index]
        let flipAngle = cardFlipAngles[index]
        let showFront = flipAngle >= 90
        let isSevenCard = index == sevenCardIndex
        // Rightmost column (index 2, 5) gets accent color when morphed into buttons
        let isAccentButton = (index == 2 || index == 5) && !isSevenCard
        
        // Z-index: cards dealt later (higher index) are on top, 7 is last/topmost
        let zIndex: Double = phase.rawValue >= SplashPhase.morph.rawValue 
            ? 0 
            : Double(index)
        
        return FlipCardView(
            number: cardNumbers[index],
            isSevenCard: isSevenCard,
            isAccentButton: isAccentButton,
            size: cardSize,
            showFront: showFront,
            flipAngle: flipAngle,
            isMorphed: phase.rawValue >= SplashPhase.morph.rawValue,
            morphedSize: morphedCardSize(index: index),
            theme: theme
        )
        .matchedGeometryEffect(
            id: "card-\(index)",
            in: morphNamespace,
            isSource: true
        )
        .zIndex(zIndex)
        .position(position)
        .opacity(isDealt ? 1 : 0)
        .offset(y: isDealt ? 0 : -size.height)
        .rotationEffect(dealRotation(index: index))
    }
    
    // MARK: - Card Positioning
    
    private func cardPosition(index: Int, center: CGPoint, size: CGSize) -> CGPoint {
        switch phase {
        case .initial, .deal, .flip:
            // Fan arrangement
            return fanPosition(index: index, center: center)
        case .morph, .exit, .complete:
            // Calculator grid arrangement
            return calculatorPosition(index: index, center: center)
        }
    }
    
    private func fanPosition(index: Int, center: CGPoint) -> CGPoint {
        // Fan spreads from left (index 0) to right (index 6)
        // Each card overlaps the previous one slightly
        let cardOverlap: CGFloat = 18 // How much each card overlaps the previous
        let totalWidth = cardOverlap * 6 // Total spread of the fan
        let arcHeight: CGFloat = 15 // How much the outer cards dip down
        
        // Position from left to right
        let xOffset = CGFloat(index) * cardOverlap - totalWidth / 2
        
        // Arc: cards in the middle are higher, edges dip down
        let centerIndex: CGFloat = 3.0
        let normalizedOffset = (CGFloat(index) - centerIndex) / centerIndex // -1 to +1
        let yOffset = arcHeight * abs(normalizedOffset)
        
        return CGPoint(
            x: center.x + xOffset,
            y: center.y - 10 + yOffset
        )
    }
    
    private func calculatorPosition(index: Int, center: CGPoint) -> CGPoint {
        if index == sevenCardIndex {
            // Card 7 goes to display area (handled by floating 7, this is just for positioning)
            return CGPoint(x: center.x, y: center.y + displayOffsetY)
        } else {
            // Cards 1-6 (indices 0-5) become buttons (2 rows x 3 cols)
            let row = index / 3
            let col = index % 3
            
            let gridWidth: CGFloat = 200
            let gridHeight: CGFloat = 115
            let cellWidth = gridWidth / 3
            let cellHeight = gridHeight / 2
            
            // Button area starts below display
            let buttonAreaTop: CGFloat = center.y - 30
            
            return CGPoint(
                x: center.x - gridWidth/2 + cellWidth/2 + CGFloat(col) * cellWidth,
                y: buttonAreaTop + CGFloat(row) * cellHeight + cellHeight/2
            )
        }
    }
    
    private func morphedCardSize(index: Int) -> CGSize {
        if index == sevenCardIndex {
            // 7 card shrinks away (floating 7 shows the content)
            return CGSize(width: 1, height: 1)
        } else {
            // Button cards
            return CGSize(width: 60, height: 50)
        }
    }
    
    private func dealRotation(index: Int) -> Angle {
        guard phase.rawValue <= SplashPhase.flip.rawValue else {
            return .zero
        }
        // Fan rotation: left cards tilt left, right cards tilt right
        let centerIndex = 3.0
        let offsetFromCenter = Double(index) - centerIndex // -3 to +3
        return .degrees(offsetFromCenter * 4)
    }
    
    // MARK: - Calculator Outline
    
    // Calculator dimensions - slightly larger than original for readability
    private let calcWidth: CGFloat = 240
    private let calcHeight: CGFloat = 300
    private let displayWidth: CGFloat = 210
    private let displayHeight: CGFloat = 65
    private let displayOffsetY: CGFloat = -105
    
    private var calculatorOutline: some View {
        ZStack {
            // Calculator body fill - teal base
            RoundedRectangle(cornerRadius: theme.calculatorCornerRadius)
                .fill(theme.calculatorBodyFill)
                .frame(width: calcWidth, height: calcHeight)
                .shadow(color: theme.calculatorShadowColor, radius: theme.calculatorShadowRadius, x: 0, y: 8)
            
            // Display area - recessed into the teal body for cohesion
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.calculatorDisplayAreaFill)
                .frame(width: displayWidth, height: displayHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(theme.calculatorBodyFill.opacity(0.3), lineWidth: 2)
                )
                .offset(y: displayOffsetY)
            
            // Calculator body border/outline - yellow/gold
            RoundedRectangle(cornerRadius: theme.calculatorCornerRadius)
                .strokeBorder(theme.calculatorBodyBorder, lineWidth: theme.calculatorBodyBorderWidth)
                .frame(width: calcWidth, height: calcHeight)
        }
    }
    
    // MARK: - Animation Timeline
    
    private func startAnimation() {
        if shouldReduceMotion {
            return // Reduced motion handles its own timing
        }
        
        // Phase 1: Deal cards - smooth cascade
        phase = .deal
        for i in 0..<7 {
            let delay = Double(i) * dealStagger
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.35)) {
                    cardDealtStates[i] = true
                }
            }
        }
        
        // Phase 2: Flip cards - brief pause then smooth flips
        let dealComplete = Double(7) * dealStagger + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + dealComplete) {
            phase = .flip
            for i in 0..<7 {
                let delay = Double(i) * flipStagger
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: flipDuration)) {
                        cardFlipAngles[i] = 180
                    }
                }
            }
        }
        
        // Phase 3: Morph to calculator - smooth transition
        let flipComplete = dealComplete + Double(7) * flipStagger + flipDuration + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + flipComplete) {
            withAnimation(.easeInOut(duration: morphDuration)) {
                phase = .morph
                showCalculatorOutline = true
            }
        }
        
        // Phase 3.5: Reveal "FLIP " beside the "7" - visual continuity
        let morphSettled = flipComplete + morphDuration + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + morphSettled) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFlipText = true
            }
        }
        
        // Phase 4: Exit - clean fade out
        let flipTextComplete = morphSettled + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + flipTextComplete) {
            phase = .exit
            withAnimation(.easeOut(duration: exitDuration)) {
                exitScale = 0.96
                exitOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
                phase = .complete
                isPresented = false
            }
        }
    }
}

// MARK: - Flip Card View

struct FlipCardView: View {
    let number: Int
    let isSevenCard: Bool
    let isAccentButton: Bool
    let size: CGSize
    let showFront: Bool
    let flipAngle: Double
    let isMorphed: Bool
    let morphedSize: CGSize
    let theme: SplashTheme
    
    // Button labels for morphed state (on-brand Flip 7 modifiers)
    private let buttonLabels = ["+2", "+4", "×2", "+6", "∞", "★"]
    
    private var currentSize: CGSize {
        isMorphed ? morphedSize : size
    }
    
    private var isButtonCard: Bool {
        !isSevenCard && isMorphed
    }
    
    private var cornerRadius: CGFloat {
        isMorphed ? 10 : 6
    }
    
    var body: some View {
        ZStack {
            // Card back
            if !showFront {
                cardBack
                    .frame(width: currentSize.width, height: currentSize.height)
            }
            
            // Card front - all cards use same frame size
            if showFront {
                cardFront
                    .frame(width: currentSize.width, height: currentSize.height)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(
            .degrees(flipAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .animation(.easeInOut(duration: 0.45), value: isMorphed)
    }
    
    private var cardBack: some View {
        ZStack {
            // Card fill with subtle gradient (teal from actual game)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [theme.cardBackFill, theme.cardBackGradientEnd],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Art Deco-style inner frame (matching real Flip 7 cards)
            GeometryReader { _ in
                let innerInset: CGFloat = 10
                
                // Outer yellow border
                RoundedRectangle(cornerRadius: cornerRadius - 1)
                    .strokeBorder(theme.cardBackBorder, lineWidth: theme.cardBackBorderWidth)
                    .padding(1)
                
                // Inner frame rectangle (Art Deco style)
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(theme.cardBackBorder.opacity(0.85), lineWidth: 1.5)
                    .padding(innerInset)
            }
            
            // Subtle crosshatch pattern in center area only
            GeometryReader { geo in
                let spacing = theme.cardBackPatternSpacing
                let inset: CGFloat = 12
                
                Path { path in
                    // Diagonal lines (top-left to bottom-right)
                    var x: CGFloat = inset - geo.size.height
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: inset))
                        path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height - inset))
                        x += spacing
                    }
                    
                    // Diagonal lines (top-right to bottom-left)
                    x = inset
                    while x < geo.size.width + geo.size.height {
                        path.move(to: CGPoint(x: x, y: inset))
                        path.addLine(to: CGPoint(x: x - geo.size.height, y: geo.size.height - inset))
                        x += spacing
                    }
                }
                .stroke(theme.cardBackPatternColor.opacity(0.5), lineWidth: theme.cardBackPatternLineWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2).inset(by: 11))
        }
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, x: 0, y: 2)
    }
    
    // Whether the 7 card should be invisible (when morphed, calculator display takes over)
    private var sevenCardIsInvisible: Bool {
        isSevenCard && isMorphed
    }
    
    private var cardFront: some View {
        let buttonFill = isAccentButton ? theme.accentButtonFillColor : theme.buttonFillColor
        let buttonText = isAccentButton ? theme.accentButtonTextColor : theme.buttonTextColor
        
        return ZStack {
            // Card/button fill
            // 7 card: visible as card when not morphed, invisible when morphed (display area takes over)
            if !sevenCardIsInvisible {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isButtonCard ? buttonFill : theme.cardFrontFill)
                
                // Border (not for buttons)
                if !isButtonCard {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(theme.cardFrontBorder, lineWidth: theme.cardFrontBorderWidth)
                }
            }
            
            // Content
            // Note: The 7 card's content is handled by the floating 7 element for visual continuity
            Group {
                if isSevenCard {
                    // 7 card: content handled by floating 7 (empty here to avoid duplication)
                    EmptyView()
                } else if isButtonCard {
                    // Morphed buttons show Flip 7 modifier symbols
                    let labelIndex = min(number - 1, buttonLabels.count - 1)
                    Text(buttonLabels[max(0, labelIndex)])
                        .font(.system(size: theme.buttonFontSize, weight: theme.buttonFontWeight, design: theme.fontDesign))
                        .foregroundStyle(buttonText)
                } else {
                    // Other cards show plain numbers
                    Text("\(number)")
                        .font(.system(size: theme.cardNumberFontSize, weight: theme.cardNumberFontWeight, design: theme.fontDesign))
                        .foregroundStyle(theme.cardNumberColor)
                }
            }
        }
        .shadow(color: isSevenCard ? .clear : theme.cardShadowColor.opacity(0.5), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Styled Text Component (shared styling for FLIP 7 wordmark)

/// Renders text with the Flip 7 box art style (yellow fill, blue/red outlines)
struct Flip7StyledText: View {
    let text: String
    let fontSize: CGFloat
    var kerning: CGFloat? = nil
    
    // Outline radii scaled to font size
    private var outerRadius: CGFloat { fontSize * 0.08 }
    private var redRadius: CGFloat { fontSize * 0.052 }
    private var innerRadius: CGFloat { fontSize * 0.026 }
    private var defaultKerning: CGFloat { fontSize * 0.04 }
    
    private var effectiveKerning: CGFloat { kerning ?? defaultKerning }
    
    // Colors from box art
    private let yellow = Color(red: 0.98, green: 0.82, blue: 0.18)
    private let blue = Color(red: 0.14, green: 0.24, blue: 0.52)
    private let red = Color(red: 0.88, green: 0.30, blue: 0.30)
    
    var body: some View {
        ZStack {
            // Blue outer outline
            outlineLayer(color: blue, radius: outerRadius)
            // Red outline
            outlineLayer(color: red, radius: redRadius)
            // Blue inner outline
            outlineLayer(color: blue, radius: innerRadius)
            // Yellow fill
            Text(text)
                .font(.custom("Nunito-Black", size: fontSize))
                .foregroundStyle(yellow)
                .kerning(effectiveKerning)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.4), radius: 0.5, x: 1, y: 1)
        .padding(outerRadius + 2) // Prevent clipping
    }
    
    private func outlineLayer(color: Color, radius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi * 2.0 / 8.0
                Text(text)
                    .font(.custom("Nunito-Black", size: fontSize))
                    .foregroundStyle(color)
                    .kerning(effectiveKerning)
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("App Icon Theme") {
    OpeningSplashView(isPresented: .constant(true), theme: .appIcon)
}

#Preview("Blue Theme") {
    OpeningSplashView(isPresented: .constant(true), theme: .blue)
}

