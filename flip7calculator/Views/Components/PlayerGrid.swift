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
    let scoringRules: ScoringRules
    var isRegularPortrait: Bool = false
    let onSelect: (UUID) -> Void

    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var scaledMinimumTileHeight: CGFloat = 84

    private var minimumTileHeight: CGFloat {
        min(max(84, scaledMinimumTileHeight), 156)
    }

    private var columnCount: Int {
        if horizontalSizeClass == .regular {
            return isRegularPortrait && players.count >= 5 ? 3 : 2
        }
        return players.count <= 4 ? 2 : (players.count <= 6 ? 3 : 4)
    }

    private var rowCount: Int {
        max(1, (players.count + columnCount - 1) / columnCount)
    }

    private var gridSpacing: CGFloat {
        players.count >= 7 && horizontalSizeClass != .regular ? 8 : 10
    }

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            let totalVerticalSpacing = gridSpacing * CGFloat(max(0, rowCount - 1))
            let fittedTileHeight = (availableHeight - totalVerticalSpacing) / CGFloat(rowCount)
            let cappedMaxHeight: CGFloat = horizontalSizeClass == .regular
                ? (isRegularPortrait ? 340 : 210)
                : 220
            let tileHeight = min(cappedMaxHeight, max(minimumTileHeight, fittedTileHeight))
            let contentHeight = tileHeight * CGFloat(rowCount) + totalVerticalSpacing
            let totalHorizontalSpacing = gridSpacing * CGFloat(max(0, columnCount - 1))
            let tileWidth = max(
                0,
                (availableWidth - totalHorizontalSpacing) / CGFloat(columnCount)
            )

            if contentHeight > availableHeight {
                ScrollView(.vertical) {
                    playerRows(tileWidth: tileWidth, tileHeight: tileHeight)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            } else {
                playerRows(tileWidth: tileWidth, tileHeight: tileHeight)
            }
        }
    }

    private func playerRows(tileWidth: CGFloat, tileHeight: CGFloat) -> some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<columnCount, id: \.self) { column in
                        let index = row * columnCount + column
                        if index < players.count {
                            let player = players[index]
                            PlayerTile(
                                player: player,
                                color: playerColors[safe: index] ?? AppBrandPalette.brandBlue,
                                isSelected: selectedPlayerId == player.id,
                                showScorePreview: showRoundScorePreview,
                                scoringRules: scoringRules,
                                tileHeight: tileHeight,
                                onTap: { onSelect(player.id) }
                            )
                            .frame(width: tileWidth, height: tileHeight)
                        } else {
                            Color.clear
                                .frame(width: tileWidth, height: tileHeight)
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
    let scoringRules: ScoringRules
    var tileHeight: CGFloat = 120
    let onTap: () -> Void

    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 17

    private var dynamicTypeMultiplier: CGFloat {
        min(max(typeScale / 17.0, 0.9), 1.45)
    }

    private enum SizeTier {
        case compact, medium, large, extraLarge
    }

    private var sizeTier: SizeTier {
        if tileHeight < 92 {
            return .compact
        } else if tileHeight < 128 {
            return .medium
        } else if tileHeight < 210 {
            return .large
        } else {
            return .extraLarge
        }
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var verticalPadding: CGFloat {
        switch sizeTier {
        case .compact: return 6
        case .medium: return 9
        case .large: return 12
        case .extraLarge: return 18
        }
    }

    private var verticalSpacing: CGFloat {
        switch sizeTier {
        case .compact: return 2
        case .medium: return 4
        case .large: return 6
        case .extraLarge: return 10
        }
    }

    private var horizontalPadding: CGFloat {
        switch sizeTier {
        case .compact: return 6
        case .medium: return 8
        case .large: return 10
        case .extraLarge: return 16
        }
    }

    private var cornerRadius: CGFloat {
        switch sizeTier {
        case .compact: return 12
        case .medium: return 14
        case .large: return 16
        case .extraLarge: return 20
        }
    }

    private var nameFontSize: CGFloat {
        let base: CGFloat = switch sizeTier {
        case .compact: 12
        case .medium: 14
        case .large: 17
        case .extraLarge: 21
        }
        return base * dynamicTypeMultiplier
    }

    private var scoreFontSize: CGFloat {
        let base: CGFloat = switch sizeTier {
        case .compact: 21
        case .medium: 25
        case .large: 32
        case .extraLarge: 46
        }
        return base * min(dynamicTypeMultiplier, 1.3)
    }

    private var previewFontSize: CGFloat {
        let base: CGFloat = switch sizeTier {
        case .compact: 10
        case .medium: 12
        case .large: 14
        case .extraLarge: 17
        }
        return base * dynamicTypeMultiplier
    }

    private var stateLabelFontSize: CGFloat {
        let base: CGFloat = switch sizeTier {
        case .compact: 8
        case .medium: 9
        case .large: 11
        case .extraLarge: 12
        }
        return base * dynamicTypeMultiplier
    }

    private var roundScore: Int {
        ScoreEngine.calculateRoundScore(round: player.currentRound, rules: scoringRules)
    }

    private var potentialTotal: Int {
        ScoreEngine.previewTotalScore(player: player, rules: scoringRules)
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

    private var stateAccentColor: Color {
        switch playerState {
        case .inRound:
            return color
        case .banked:
            return DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
        case .busted:
            return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        case .frozen:
            return DesignColor.color(.stateFrozen, theme: visualTheme, colorScheme: colorScheme)
        }
    }

    private var stateLabel: String? {
        switch playerState {
        case .inRound: return nil
        case .banked: return scoringRules.mode == .vengeance ? "STAYED" : "BANKED"
        case .busted: return "BUSTED"
        case .frozen: return scoringRules.mode == .vengeance ? "FORCED" : "FROZEN"
        }
    }

    private var stateSymbol: String? {
        switch playerState {
        case .inRound: return nil
        case .banked: return "checkmark"
        case .busted: return "xmark"
        case .frozen: return "snowflake"
        }
    }

    private var shouldShowRoundScorePreview: Bool {
        guard showScorePreview else { return false }
        guard playerState != .busted || scoringRules.brutalMode else { return false }
        return roundScore != 0 || hasManualOverride
    }

    private var roundScorePreviewText: String {
        let delta = roundScore > 0 ? "+\(roundScore)" : "\(roundScore)"
        if hasManualOverride {
            return "\(delta) ✎ → \(potentialTotal)"
        }
        return "\(delta) → \(potentialTotal)"
    }

    private var tileFill: Color {
        DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
    }

    private var tintOverlayColor: Color {
        if hasStateFrame {
            return stateAccentColor.opacity(colorScheme == .dark ? 0.12 : 0.08)
        }
        if isSelected {
            return color.opacity(colorScheme == .dark ? 0.16 : 0.10)
        }
        return .clear
    }

    private var borderColor: Color {
        if isSelected {
            return color
        }
        if hasStateFrame {
            return stateAccentColor.opacity(colorScheme == .dark ? 0.78 : 0.70)
        }
        return visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.45)
    }

    private var borderWidth: CGFloat {
        if isSelected { return 2.5 }
        if hasStateFrame { return 1.75 }
        return 1
    }

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap()
        }) {
            VStack(spacing: verticalSpacing) {
                // Status badge or calm placeholder to keep row rhythm aligned
                if let label = stateLabel, let symbol = stateSymbol {
                    HStack(spacing: 3) {
                        Image(systemName: symbol)
                            .font(.system(size: stateLabelFontSize, weight: .bold))
                        Text(label)
                            .font(.system(size: stateLabelFontSize, weight: .bold, design: .rounded))
                            .tracking(0.4)
                    }
                    .foregroundStyle(stateAccentColor)
                    .padding(.horizontal, sizeTier == .compact ? 5 : 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(stateAccentColor.opacity(colorScheme == .dark ? 0.20 : 0.14)))
                } else {
                    Text(" ")
                        .font(.system(size: stateLabelFontSize, weight: .bold, design: .rounded))
                        .padding(.vertical, 2)
                        .opacity(0)
                }

                // Player identity dot + name
                HStack(spacing: 5) {
                    Circle()
                        .fill(color)
                        .frame(width: sizeTier == .compact ? 7 : 8, height: sizeTier == .compact ? 7 : 8)

                    Text(player.name)
                        .font(.system(size: nameFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                // Total score
                Text("\(player.totalScore)")
                    .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        playerState == .busted
                            ? DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                            : DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
                    )
                    .contentTransition(.numericText())

                // Round score preview (reserved space keeps layout stable)
                if showScorePreview {
                    Text(shouldShowRoundScorePreview ? roundScorePreviewText : " ")
                        .font(.system(size: previewFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            hasStateFrame
                                ? stateAccentColor
                                : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .opacity(shouldShowRoundScorePreview ? 1 : 0)
                        .accessibilityHidden(!shouldShowRoundScorePreview)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tileFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tintOverlayColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: colorScheme == .light ? AppBrandPalette.ink.opacity(isSelected ? 0.09 : 0.04) : .clear,
                radius: isSelected ? 8 : 4,
                y: isSelected ? 3 : 1
            )
            .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: playerState)
            .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: isSelected)
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.96))
        .accessibilityLabel(player.name)
        .accessibilityValue(accessibilityValueText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityValueText: String {
        var parts: [String] = ["\(player.totalScore) points"]
        if let state = stateLabel {
            parts.append(state.lowercased())
        }
        if shouldShowRoundScorePreview {
            let signed = roundScore >= 0 ? "plus \(roundScore)" : "minus \(abs(roundScore))"
            parts.append("\(signed) this round, projected \(potentialTotal) total")
        }
        return parts.joined(separator: ", ")
    }
}
