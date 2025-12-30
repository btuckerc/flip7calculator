//
//  RulesView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/30/25.
//

import SwiftUI

// MARK: - Rules View

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private let totalPages = 6
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Swipeable pages
                    TabView(selection: $currentPage) {
                        GoalPage().tag(0)
                        DrawCardsPage().tag(1)
                        BustPage().tag(2)
                        ScoringPage().tag(3)
                        SpecialCardsPage().tag(4)
                        CalculatorPage().tag(5)
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                    
                    // Custom page indicator + navigation
                    bottomNavigation
                }
            }
            .navigationTitle("How to Play")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Bottom Navigation
    
    private var bottomNavigation: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: {
                withAnimation { currentPage = max(0, currentPage - 1) }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(currentPage > 0 ? .blue : .gray.opacity(0.3))
            }
            .disabled(currentPage == 0)
            
            Spacer()
            
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            
            Spacer()
            
            // Forward button
            Button(action: {
                withAnimation { currentPage = min(totalPages - 1, currentPage + 1) }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(currentPage < totalPages - 1 ? .blue : .gray.opacity(0.3))
            }
            .disabled(currentPage == totalPages - 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Page 1: The Goal

struct GoalPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            
            Text("The Goal")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            // Simple goal statement
            VStack(spacing: 16) {
                GoalBubble(
                    icon: "target",
                    color: .green,
                    text: "First to **200 points** wins"
                )
                
                GoalBubble(
                    icon: "arrow.up.circle.fill",
                    color: .blue,
                    text: "Collect cards to **score higher**"
                )
                
                GoalBubble(
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    text: "But don't get **greedy**..."
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Swipe hint
            SwipeHint()
        }
        .padding()
    }
}

struct GoalBubble: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 40)
            
            Text(LocalizedStringKey(text))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Page 2: Draw Cards

struct DrawCardsPage: View {
    @State private var cardsShown = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Draw Cards")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Tap to add each card you draw")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            // Interactive card demo
            HStack(spacing: -20) {
                ForEach(0..<4, id: \.self) { index in
                    DemoCard(
                        number: [3, 7, 10, 12][index],
                        isShown: index < cardsShown
                    )
                    .zIndex(Double(index))
                }
            }
            .padding(.vertical, 24)
            
            // Tap to demo button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    cardsShown = cardsShown < 4 ? cardsShown + 1 : 0
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: cardsShown < 4 ? "plus.circle.fill" : "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 20))
                    Text(cardsShown < 4 ? "Draw Card" : "Reset")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }
            
            // Key points
            VStack(spacing: 12) {
                KeyPoint(icon: "hand.tap.fill", text: "Tap numbers in the calculator as cards are drawn")
                KeyPoint(icon: "checkmark.circle.fill", text: "Press **Bank** when you want to stop")
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Spacer()
            SwipeHint()
        }
        .padding()
    }
}

struct DemoCard: View {
    let number: Int
    let isShown: Bool
    
    var body: some View {
        ZStack {
            // Card back
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                )
                .opacity(isShown ? 0 : 1)
            
            // Card front
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .frame(width: 70, height: 100)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                )
                .opacity(isShown ? 1 : 0)
        }
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .rotation3DEffect(.degrees(isShown ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(isShown ? 1 : 0.9)
    }
}

struct KeyPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(LocalizedStringKey(text))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Page 3: Don't Bust!

struct BustPage: View {
    @State private var demoState: DemoPlayerState = .inRound
    
    enum DemoPlayerState {
        case inRound, banked, busted, frozen
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Player Actions")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Mark what happens to each player")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            // Demo card display
            VStack(spacing: 16) {
                // Cards row
                HStack(spacing: 12) {
                    DemoNumberCard(number: 3, isBusted: demoState == .busted)
                    DemoNumberCard(number: 7, isBusted: demoState == .busted)
                    
                    // Show duplicate on bust
                    if demoState == .busted {
                        DemoNumberCard(number: 7, isBusted: true)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.red)
                                    .background(Circle().fill(.white).padding(2))
                                    .offset(x: 6, y: -6)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: demoState)
                
                // Score display
                HStack(spacing: 8) {
                    Text("Score:")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Text(scoreText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText())
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 20)
            
            // Action buttons - matching GameView style
            VStack(spacing: 12) {
                Text("Tap to try:")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                
                HStack(spacing: 8) {
                    DemoActionButton(
                        title: "Bank",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        isActive: demoState == .banked
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            demoState = demoState == .banked ? .inRound : .banked
                        }
                    }
                    
                    DemoActionButton(
                        title: "Bust",
                        icon: "xmark.circle.fill",
                        color: .red,
                        isActive: demoState == .busted
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            demoState = demoState == .busted ? .inRound : .busted
                        }
                    }
                    
                    DemoActionButton(
                        title: "Freeze",
                        icon: "snowflake",
                        color: .cyan,
                        isActive: demoState == .frozen
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            demoState = demoState == .frozen ? .inRound : .frozen
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Status explanation
            Group {
                switch demoState {
                case .inRound:
                    StatusBubble(
                        icon: "hand.point.up.fill",
                        color: .blue,
                        text: "Player is still drawing cards"
                    )
                case .banked:
                    StatusBubble(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: "Player keeps their 10 points!"
                    )
                case .busted:
                    StatusBubble(
                        icon: "xmark.circle.fill",
                        color: .red,
                        text: "Duplicate 7 → scores 0 this round"
                    )
                case .frozen:
                    StatusBubble(
                        icon: "snowflake",
                        color: .cyan,
                        text: "Forced to bank by Freeze card"
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
            SwipeHint()
        }
        .padding()
    }
    
    private var scoreText: String {
        switch demoState {
        case .inRound: return "10"
        case .banked: return "+10"
        case .busted: return "0"
        case .frozen: return "+10"
        }
    }
    
    private var scoreColor: Color {
        switch demoState {
        case .inRound: return .primary
        case .banked: return .green
        case .busted: return .red
        case .frozen: return .cyan
        }
    }
}

struct DemoNumberCard: View {
    let number: Int
    let isBusted: Bool
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(isBusted ? .red : .blue)
            .frame(width: 56, height: 76)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
                    .shadow(color: isBusted ? .red.opacity(0.3) : .black.opacity(0.1), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isBusted ? Color.red : Color.blue.opacity(0.2), lineWidth: isBusted ? 2 : 1)
            )
    }
}

struct DemoActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? color : color.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(isActive ? 0.4 : 0), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct StatusBubble: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Page 4: Scoring

struct ScoringPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Scoring")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            // Visual formula
            VStack(spacing: 16) {
                // Basic scoring
                ScoringRow(
                    cards: [3, 7, 11],
                    modifiers: [],
                    hasFlip7: false,
                    total: 21
                )
                
                // With x2
                ScoringRow(
                    cards: [2, 5, 8],
                    modifiers: ["×2", "+4"],
                    hasFlip7: false,
                    total: 34
                )
                
                // Flip 7 bonus
                ScoringRow(
                    cards: [0, 1, 2, 3, 4, 5, 6],
                    modifiers: [],
                    hasFlip7: true,
                    total: 36
                )
            }
            .padding(.horizontal, 16)
            
            // Flip 7 callout
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flip 7 Bonus!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("7 unique numbers = **+15 bonus points**")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.yellow.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            
            Spacer()
            SwipeHint()
        }
        .padding()
    }
}

struct ScoringRow: View {
    let cards: [Int]
    let modifiers: [String]
    let hasFlip7: Bool
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Mini cards
            HStack(spacing: 4) {
                ForEach(cards.prefix(5), id: \.self) { num in
                    MiniCard(number: num)
                }
                if cards.count > 5 {
                    Text("+\(cards.count - 5)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Modifiers
            if !modifiers.isEmpty || hasFlip7 {
                HStack(spacing: 4) {
                    ForEach(modifiers, id: \.self) { mod in
                        Text(mod)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(mod.contains("×") ? .purple : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(mod.contains("×") ? Color.purple.opacity(0.15) : Color.orange.opacity(0.15))
                            )
                    }
                    
                    if hasFlip7 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("+15")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.yellow.opacity(0.2))
                        )
                    }
                }
            }
            
            Spacer()
            
            // Total
            Text("= \(total)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct MiniCard: View {
    let number: Int
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.blue)
            .frame(width: 24, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            )
    }
}

// MARK: - Page 5: Special Cards

struct SpecialCardsPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Special Cards")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Action cards mix things up!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                SpecialCardTile(
                    icon: "snowflake",
                    color: .cyan,
                    name: "Freeze",
                    effect: "Forces bank immediately"
                )
                
                SpecialCardTile(
                    icon: "square.stack.3d.up.fill",
                    color: .indigo,
                    name: "Flip Three",
                    effect: "Draw 3 cards in a row"
                )
                
                SpecialCardTile(
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .green,
                    name: "Second Chance",
                    effect: "Survive one bust"
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                SpecialCardTile(
                    icon: "plus.circle.fill",
                    color: .orange,
                    name: "+2 to +10",
                    effect: "Bonus points added"
                )
                
                SpecialCardTile(
                    icon: "xmark.circle.fill",
                    color: .purple,
                    name: "×2 Multiplier",
                    effect: "Doubles your number total"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            SwipeHint()
        }
        .padding()
    }
}

struct SpecialCardTile: View {
    let icon: String
    let color: Color
    let name: String
    let effect: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                )
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(effect)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Page 6: Using the Calculator

struct CalculatorPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Quick Tips")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Using this calculator")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                CalculatorTipTile(
                    number: "1",
                    icon: "hand.tap.fill",
                    color: .blue,
                    title: "Tap Numbers",
                    description: "Add cards as they're drawn"
                )
                
                CalculatorTipTile(
                    number: "2",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Bank / Bust / Freeze",
                    description: "Mark player status with buttons"
                )
                
                CalculatorTipTile(
                    number: "3",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .orange,
                    title: "Use Undo",
                    description: "Fix mistakes instantly"
                )
                
                CalculatorTipTile(
                    number: "4",
                    icon: "arrow.forward.circle.fill",
                    color: .purple,
                    title: "Continue",
                    description: "Move to next player in round"
                )
            }
            .padding(.horizontal, 24)
            
            // Footer note
            Text("Flip 7 © The Op Games")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.top, 16)
            
            Spacer()
            
            // "Got it" instead of swipe hint
            Text("Swipe left to start over")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding()
    }
}

struct CalculatorTipTile: View {
    let number: String
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Step number
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color))
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Swipe Hint

struct SwipeHint: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Swipe to continue")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .offset(x: isAnimating ? 4 : 0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        }
        .padding(.bottom, 8)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Preview

#Preview {
    RulesView()
}
