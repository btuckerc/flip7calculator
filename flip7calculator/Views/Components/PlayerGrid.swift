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
    
    private var roundScore: Int {
        ScoreEngine.calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
    }
    
    private var statusIcon: String {
        switch player.currentRound.state {
        case .inRound: return "circle.fill"
        case .banked: return "checkmark.circle.fill"
        case .busted: return "xmark.circle.fill"
        case .frozen: return "snowflake"
        }
    }
    
    private var statusColor: Color {
        switch player.currentRound.state {
        case .inRound: return .blue
        case .banked: return .green
        case .busted: return .red
        case .frozen: return .purple
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
            VStack(spacing: 8) {
                // Status icon
                Image(systemName: statusIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(statusColor)
                
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
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : color.opacity(0.3), lineWidth: isSelected ? 0 : 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

