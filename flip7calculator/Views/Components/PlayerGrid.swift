//
//  PlayerGrid.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct PlayerGrid: View {
    let players: [Player]
    let playerColors: [Color]
    let selectedPlayerId: UUID?
    let onSelect: (UUID) -> Void
    
    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    
    private var columns: [GridItem] {
        // 2 columns for 2-4 players, 3 for 5-6, 4 for 7-8
        let count = players.count <= 4 ? 2 : (players.count <= 6 ? 3 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                PlayerTile(
                    player: player,
                    color: playerColors[safe: index] ?? .blue,
                    isSelected: selectedPlayerId == player.id,
                    showScorePreview: showRoundScorePreview,
                    onTap: { onSelect(player.id) }
                )
            }
        }
    }
}

struct PlayerTile: View {
    let player: Player
    let color: Color
    let isSelected: Bool
    let showScorePreview: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    
    private var shouldAnimate: Bool {
        !reduceAnimations && !accessibilityReduceMotion
    }
    
    private var roundScore: Int {
        ScoreEngine.calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
    }
    
    private var playerState: PlayerRoundState {
        player.currentRound.state
    }
    
    private var hasStateFrame: Bool {
        playerState != .inRound
    }
    
    /// Frame color based on player state
    private var stateFrameColor: Color {
        switch playerState {
        case .inRound: return .clear
        case .banked: return Color(red: 0.2, green: 0.78, blue: 0.35) // Vibrant green
        case .busted: return Color(red: 0.95, green: 0.25, blue: 0.25) // Vivid red
        case .frozen: return Color(red: 0.55, green: 0.85, blue: 1.0) // Icy cyan-white
        }
    }
    
    /// Secondary frost color for frozen state
    private var frozenHighlightColor: Color {
        Color(red: 0.85, green: 0.95, blue: 1.0) // Frosty white-blue
    }
    
    /// State label text for non-inRound states
    private var stateLabel: String? {
        switch playerState {
        case .inRound: return nil
        case .banked: return "BANKED"
        case .busted: return "BUSTED"
        case .frozen: return "FROZEN"
        }
    }
    
    private var shouldShowRoundScorePreview: Bool {
        roundScore > 0 || player.currentRound.state == .busted
    }
    
    private var roundScorePreviewText: String {
        player.currentRound.state == .busted ? "BUST" : "+\(roundScore)"
    }
    
    private var roundScorePreviewColor: Color {
        isSelected ? .white.opacity(0.8) : (player.currentRound.state == .busted ? .red : .secondary)
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(spacing: 6) {
                // State label (replaces status icon for non-inRound states)
                if let label = stateLabel {
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : stateFrameColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? stateFrameColor.opacity(0.3) : stateFrameColor.opacity(0.15))
                        )
                } else {
                    // Reserve space when in round (no label)
                    Text(" ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .opacity(0)
                }
                
                // Player name
                Text(player.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Total score
                Text("\(player.totalScore)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                // Round score preview (always reserve space when enabled)
                if showScorePreview {
                    Text(roundScorePreviewText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(roundScorePreviewColor)
                        .opacity(shouldShowRoundScorePreview ? 1.0 : 0.0)
                        .accessibilityHidden(!shouldShowRoundScorePreview)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            // Base border (subtle when no state frame)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? color.opacity(0.0) : color.opacity(0.3),
                        lineWidth: 2
                    )
            )
            // Inner glow/tint that bleeds into the tile
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        RadialGradient(
                            colors: [
                                .clear,
                                (playerState == .frozen ? frozenHighlightColor : stateFrameColor).opacity(hasStateFrame ? 0.12 : 0)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .opacity(hasStateFrame ? 1 : 0)
            )
            // State frame overlay (soft outer glow layer)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        (playerState == .frozen ? frozenHighlightColor : stateFrameColor).opacity(hasStateFrame ? 0.5 : 0),
                        lineWidth: 10
                    )
                    .blur(radius: 6)
                    .padding(-3)
                    .opacity(hasStateFrame ? 1 : 0)
            )
            // State frame overlay (mid glow for depth)
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(
                        stateFrameColor.opacity(hasStateFrame ? 0.4 : 0),
                        lineWidth: 5
                    )
                    .blur(radius: 2)
                    .padding(-1)
                    .opacity(hasStateFrame ? 1 : 0)
            )
            // State frame overlay (crisp inner stroke)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        stateFrameColor.opacity(hasStateFrame ? (isSelected ? 0.75 : 0.9) : 0),
                        lineWidth: 2.5
                    )
                    .opacity(hasStateFrame ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(shouldAnimate ? .easeInOut(duration: 0.25) : .none, value: playerState)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityValueText)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabelText: String {
        player.name
    }
    
    private var accessibilityValueText: String {
        var parts: [String] = []
        parts.append("\(player.totalScore) points")
        if let state = stateLabel {
            parts.append(state.lowercased())
        }
        if shouldShowRoundScorePreview && playerState != .busted {
            parts.append("plus \(roundScore) this round")
        }
        return parts.joined(separator: ", ")
    }
}

