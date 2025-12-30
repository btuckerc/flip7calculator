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
    
    /// Number of columns based on player count
    private var columnCount: Int {
        // 2 columns for 2-4 players, 3 for 5-6, 4 for 7-8
        players.count <= 4 ? 2 : (players.count <= 6 ? 3 : 4)
    }
    
    /// Number of rows needed
    private var rowCount: Int {
        (players.count + columnCount - 1) / columnCount
    }
    
    /// Grid spacing - tighter for more players
    private var gridSpacing: CGFloat {
        players.count >= 7 ? 8 : 12
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            
            // Calculate tile dimensions to fill available space
            let totalVerticalSpacing = gridSpacing * CGFloat(rowCount - 1)
            let tileHeight = (availableHeight - totalVerticalSpacing) / CGFloat(rowCount)
            
            let totalHorizontalSpacing = gridSpacing * CGFloat(columnCount - 1)
            let tileWidth = (availableWidth - totalHorizontalSpacing) / CGFloat(columnCount)
            
            VStack(spacing: gridSpacing) {
                ForEach(0..<rowCount, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<columnCount, id: \.self) { col in
                            let index = row * columnCount + col
                            if index < players.count {
                                let player = players[index]
                                PlayerTile(
                                    player: player,
                                    color: playerColors[safe: index] ?? .blue,
                                    isSelected: selectedPlayerId == player.id,
                                    showScorePreview: showRoundScorePreview,
                                    tileHeight: tileHeight,
                                    onTap: { onSelect(player.id) }
                                )
                                .frame(width: tileWidth, height: tileHeight)
                            } else {
                                // Empty space for incomplete rows
                                Color.clear
                                    .frame(width: tileWidth, height: tileHeight)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PlayerTile: View {
    let player: Player
    let color: Color
    let isSelected: Bool
    let showScorePreview: Bool
    var tileHeight: CGFloat = 120 // Default height, will be overridden by grid
    let onTap: () -> Void
    
    @State private var isPressed = false
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    
    // MARK: - Adaptive sizing based on tile height
    
    /// Determines sizing tier based on available tile height
    private var sizeTier: SizeTier {
        if tileHeight < 90 {
            return .compact
        } else if tileHeight < 130 {
            return .medium
        } else {
            return .large
        }
    }
    
    private enum SizeTier {
        case compact, medium, large
    }
    
    private var verticalPadding: CGFloat {
        switch sizeTier {
        case .compact: return 6
        case .medium: return 10
        case .large: return 14
        }
    }
    
    private var verticalSpacing: CGFloat {
        switch sizeTier {
        case .compact: return 2
        case .medium: return 4
        case .large: return 6
        }
    }
    
    private var nameFontSize: CGFloat {
        switch sizeTier {
        case .compact: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
    
    private var scoreFontSize: CGFloat {
        switch sizeTier {
        case .compact: return 20
        case .medium: return 24
        case .large: return 28
        }
    }
    
    private var stateLabelFontSize: CGFloat {
        switch sizeTier {
        case .compact: return 8
        case .medium: return 9
        case .large: return 10
        }
    }
    
    private var previewFontSize: CGFloat {
        switch sizeTier {
        case .compact: return 10
        case .medium: return 11
        case .large: return 13
        }
    }
    
    private var cornerRadius: CGFloat {
        switch sizeTier {
        case .compact: return 10
        case .medium: return 12
        case .large: return 16
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch sizeTier {
        case .compact: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    private var stateLabelPaddingH: CGFloat {
        switch sizeTier {
        case .compact: return 4
        case .medium: return 5
        case .large: return 6
        }
    }
    
    private var stateLabelPaddingV: CGFloat {
        switch sizeTier {
        case .compact: return 1
        case .medium: return 1
        case .large: return 2
        }
    }
    
    private var shouldAnimate: Bool {
        !reduceAnimations && !accessibilityReduceMotion
    }
    
    private var roundScore: Int {
        ScoreEngine.calculateRoundScore(round: player.currentRound)
    }
    
    private var potentialTotal: Int {
        ScoreEngine.previewTotalScore(player: player)
    }
    
    private var hasManualOverride: Bool {
        player.currentRound.manualScoreOverride != nil
    }
    
    private var playerState: PlayerRoundState {
        player.currentRound.state
    }
    
    private var hasStateFrame: Bool {
        playerState != .inRound
    }
    
    /// The best contrasting foreground color for when this tile is selected.
    /// Uses the player color's luminance to determine black vs white.
    private var selectedForeground: Color {
        color.contrastingForeground
    }
    
    /// Frame color based on player state
    private var stateFrameColor: Color {
        switch playerState {
        case .inRound: return .clear
        case .banked: return ReservedColors.bankedFrameGreen
        case .busted: return ReservedColors.bustedFrameRed
        case .frozen: return ReservedColors.frozenFrameCyan
        }
    }
    
    /// Secondary frost color for frozen state
    private var frozenHighlightColor: Color {
        ReservedColors.frozenHighlight
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
    
    /// Whether to show the round score preview (respects toggle, requires meaningful input, excludes busted)
    private var shouldShowRoundScorePreview: Bool {
        guard showScorePreview else { return false }
        guard playerState != .busted else { return false }
        return roundScore > 0 || hasManualOverride
    }
    
    /// Preview text showing round delta and potential total
    private var roundScorePreviewText: String {
        if hasManualOverride {
            return "+\(roundScore) ✎ → \(potentialTotal)"
        }
        return "+\(roundScore) → \(potentialTotal)"
    }
    
    /// Preview text color (subtle, doesn't compete with selection)
    private var roundScorePreviewColor: Color {
        if isSelected {
            return selectedForeground.opacity(0.8)
        }
        // Use secondary for all cases to keep it subtle
        return .secondary
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(spacing: verticalSpacing) {
                // State label (replaces status icon for non-inRound states)
                if let label = stateLabel {
                    Text(label)
                        .font(.system(size: stateLabelFontSize, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(isSelected ? selectedForeground.opacity(0.9) : stateFrameColor)
                        .padding(.horizontal, stateLabelPaddingH)
                        .padding(.vertical, stateLabelPaddingV)
                        .background(
                            Capsule()
                                .fill(isSelected ? stateFrameColor.opacity(0.3) : stateFrameColor.opacity(0.15))
                        )
                } else {
                    // Reserve space when in round (no label)
                    Text(" ")
                        .font(.system(size: stateLabelFontSize, weight: .bold, design: .rounded))
                        .padding(.horizontal, stateLabelPaddingH)
                        .padding(.vertical, stateLabelPaddingV)
                        .opacity(0)
                }
                
                // Player name
                Text(player.name)
                    .font(.system(size: nameFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? selectedForeground : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Total score
                Text("\(player.totalScore)")
                    .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? selectedForeground : .primary)
                
                // Round score preview (always reserve space when enabled)
                if showScorePreview {
                    Text(roundScorePreviewText)
                        .font(.system(size: previewFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(roundScorePreviewColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .opacity(shouldShowRoundScorePreview ? 1.0 : 0.0)
                        .accessibilityHidden(!shouldShowRoundScorePreview)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            // Base border (subtle when no state frame)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? color.opacity(0.0) : color.opacity(0.3),
                        lineWidth: 2
                    )
            )
            // Inner glow/tint that bleeds into the tile
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
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
                RoundedRectangle(cornerRadius: cornerRadius + 2)
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
                RoundedRectangle(cornerRadius: cornerRadius + 1)
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
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        stateFrameColor.opacity(hasStateFrame ? (isSelected ? 0.75 : 0.9) : 0),
                        lineWidth: 2.5
                    )
                    .opacity(hasStateFrame ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
        if shouldShowRoundScorePreview {
            parts.append("plus \(roundScore) this round, would be \(potentialTotal) total")
        }
        return parts.joined(separator: ", ")
    }
}

