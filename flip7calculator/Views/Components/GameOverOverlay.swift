//
//  GameOverOverlay.swift
//  flip7calculator
//
//  Blocking modal overlay for game completion with standings and actions.
//

import SwiftUI

struct GameOverOverlay: View {
    @Bindable var viewModel: GameViewModel
    let onPlayAgain: () -> Void
    let onNewGame: () -> Void
    let onUndo: () -> Void

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    @State private var isPresented = false
    @State private var showingStats = false

    private var game: Game? {
        viewModel.game
    }

    private var rankedPlayers: [Player] {
        guard let game else { return [] }
        return game.players.sorted { $0.totalScore > $1.totalScore }
    }

    private var winners: [Player] {
        guard let game else { return [] }
        let maxScore = rankedPlayers.first?.totalScore ?? 0
        return rankedPlayers.filter { $0.totalScore == maxScore && $0.totalScore >= game.targetScore }
    }

    private var roundsPlayed: Int {
        game?.gameHistory.count ?? 0
    }

    private var playerCount: Int {
        rankedPlayers.count
    }

    private var useCompactLayout: Bool {
        playerCount >= 7
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var dangerColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.58 : 0)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 14) {
                        Spacer(minLength: 0)
                        winnerCard
                        actionBar
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: 440)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .scaleEffect(isPresented || isReducedMotion ? 1.0 : 0.96)
            .offset(y: isPresented || isReducedMotion ? 0 : 10)
            .opacity(isPresented ? 1.0 : 0.0)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            withAnimation(DesignMotion.animation(.normal, reduced: isReducedMotion)) {
                isPresented = true
            }
        }
        .sheet(isPresented: $showingStats) {
            if let game {
                GameOverStatsView(game: game)
            }
        }
    }

    // MARK: - Winner Card

    private var winnerCard: some View {
        VStack(spacing: useCompactLayout ? 10 : 14) {
            ZStack {
                Circle()
                    .fill(AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.16 : 0.20))
                    .frame(width: useCompactLayout ? 56 : 68, height: useCompactLayout ? 56 : 68)

                Image(systemName: "trophy.fill")
                    .font(.system(size: useCompactLayout ? 26 : 32))
                    .foregroundStyle(DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme))
            }
            .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("Game Over")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))

                if !winners.isEmpty {
                    if winners.count == 1 {
                        Text("\(winners[0].name) Wins")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(accentColor)
                    } else {
                        Text("Tie: \(winners.map(\.name).joined(separator: " & "))")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(accentColor)
                            .multilineTextAlignment(.center)
                    }

                    Text("\(winners[0].totalScore) points")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                }
            }

            HStack(spacing: 28) {
                summaryMetric(value: "\(roundsPlayed)", label: "Rounds")
                if let game {
                    summaryMetric(value: "\(game.targetScore)", label: "Target")
                }
            }
            .padding(.top, 2)

            Divider()
                .overlay(DesignColor.border(theme: visualTheme, colorScheme: colorScheme))
                .padding(.vertical, 2)

            finalScoresSection
        }
        .padding(.vertical, useCompactLayout ? 16 : 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: 24)
    }

    private func summaryMetric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
            Text(label)
                .font(DesignTypography.font(.caption))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
        }
    }

    // MARK: - Final Scores Section

    private var finalScoresSection: some View {
        let rowSpacing: CGFloat = useCompactLayout ? 5 : 8
        let badgeSize: CGFloat = useCompactLayout ? 24 : 28

        return VStack(spacing: rowSpacing) {
            Text("Final Standings")
                .font(DesignTypography.font(.label))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                .textCase(.uppercase)
                .padding(.bottom, 2)

            ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(rankColor(for: index).opacity(0.18))
                            .frame(width: badgeSize, height: badgeSize)

                        if index == 0 {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(rankColor(for: index))
                        } else {
                            Text("\(index + 1)")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(rankColor(for: index))
                        }
                    }

                    Text(player.name)
                        .font(.system(.body, design: .rounded, weight: index == 0 ? .bold : .medium))
                        .foregroundStyle(
                            index == 0
                                ? DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
                                : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                        )
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    Text("\(player.totalScore)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(
                            index == 0
                                ? accentColor
                                : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                        )
                        .monospacedDigit()
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button(action: {
                HapticFeedback.success()
                onPlayAgain()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                    Text("Play Again")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 10) {
                Button(action: {
                    HapticFeedback.light()
                    showingStats = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.subheadline.weight(.semibold))
                        Text("Stats")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: {
                    HapticFeedback.medium()
                    onNewGame()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                        Text("New Game")
                    }
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(dangerColor)
                    .padding(.vertical, DesignSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                            .fill(dangerColor.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignRadius.md, style: .continuous)
                            .stroke(dangerColor.opacity(0.28), lineWidth: 1)
                    )
                }
                .buttonStyle(KeycapButtonStyle(pressedScale: 0.97))
            }

            if viewModel.canUndo {
                Button(action: {
                    HapticFeedback.light()
                    viewModel.undo()
                    onUndo()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.footnote.weight(.semibold))
                        Text("Undo Final Round")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 22)
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return AppBrandPalette.gold
        case 1: return AppBrandPalette.slate
        case 2: return AppBrandPalette.copper
        default: return .secondary
        }
    }
}
