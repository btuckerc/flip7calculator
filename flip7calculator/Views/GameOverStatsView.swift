//
//  GameOverStatsView.swift
//  flip7calculator
//
//  Shows game statistics and round-by-round history after game completion.
//

import SwiftUI
import Charts

struct GameOverStatsView: View {
    let game: Game
    private let stats: GameStats
    private let cumulativeData: [RoundDataPoint]
    private let rankedPlayers: [Player]
    private let playerStatsById: [UUID: PlayerGameStats]
    private let mostConsistentHighlight: (player: Player, stdDev: Double)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPlayerForChart: UUID?
    @State private var selectedPlayerForDetail: Player?

    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue

    init(game: Game) {
        self.game = game
        let computed = GameStats(game: game)
        self.stats = computed
        self.cumulativeData = computed.cumulativeChartData()
        self.rankedPlayers = computed.rankedPlayers
        var byId: [UUID: PlayerGameStats] = [:]
        var bestConsistent: (player: Player, stdDev: Double)?
        for player in game.players {
            let playerStat = PlayerGameStats(playerId: player.id, game: game)
            byId[player.id] = playerStat
            if let stdDev = playerStat.scoreStandardDeviation,
               playerStat.nonBustRoundScores.count >= 2,
               bestConsistent == nil || stdDev < bestConsistent!.stdDev {
                bestConsistent = (player, stdDev)
            }
        }
        self.playerStatsById = byId
        self.mostConsistentHighlight = bestConsistent
        self._selectedPlayerForChart = State(initialValue: game.players.first?.id)
    }

    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    private var playerColors: [Color] {
        PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette)
    }

    private func colorForPlayer(_ playerId: UUID) -> Color {
        guard let index = game.players.firstIndex(where: { $0.id == playerId }) else {
            return accentColor
        }
        return playerColors[safe: index] ?? accentColor
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var rowBackground: Color {
        DesignColor.listRowBackground(theme: visualTheme, colorScheme: colorScheme)
    }

    private var rowSeparator: Color {
        DesignColor.border(theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                highlightsSection
                chartsSection
                playerStatsSection
                roundHistorySection
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.insetGrouped)
            .navigationTitle("Game Stats")
            .navigationBarTitleDisplayMode(.inline)
            .appChromeBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedPlayerForDetail) { player in
                PlayerDetailView(
                    player: player,
                    game: game,
                    playerColor: colorForPlayer(player.id)
                )
            }
            .tint(accentColor)
        }
    }

    // MARK: - Highlights Section

    @ViewBuilder
    private var highlightsSection: some View {
        Section {
            if !stats.winners.isEmpty {
                HighlightRow(
                    icon: "crown.fill",
                    iconColor: AppBrandPalette.gold,
                    title: stats.winners.count > 1 ? "Winners" : "Winner",
                    value: stats.winners.map(\.name).joined(separator: ", "),
                    detail: stats.winningMargin > 0 ? "Won by \(stats.winningMargin) pts" : nil
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if stats.leadChanges > 0 {
                HighlightRow(
                    icon: "arrow.left.arrow.right",
                    iconColor: AppBrandPalette.brandBlueSky,
                    title: "Lead Changes",
                    value: "\(stats.leadChanges)",
                    detail: nil
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if let comeback = stats.biggestComeback, comeback.deficit > 10 {
                HighlightRow(
                    icon: "arrow.up.right",
                    iconColor: DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme),
                    title: "Biggest Comeback",
                    value: comeback.player.name,
                    detail: "Overcame \(comeback.deficit) pt deficit"
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if let best = stats.bestRoundScore {
                HighlightRow(
                    icon: "flame.fill",
                    iconColor: AppBrandPalette.copper,
                    title: "Best Round",
                    value: "\(best.score) pts",
                    detail: "\(best.playerName) in R\(best.round)"
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if let consistent = mostConsistentHighlight, stats.roundsPlayed >= 3 {
                HighlightRow(
                    icon: "target",
                    iconColor: accentColor,
                    title: "Most Consistent",
                    value: consistent.player.name,
                    detail: "σ = \(String(format: "%.1f", consistent.stdDev))"
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if stats.totalSevenCardBonuses > 0 {
                HighlightRow(
                    icon: "7.circle.fill",
                    iconColor: AppBrandPalette.gold,
                    title: "Total 7-Card Bonuses",
                    value: "\(stats.totalSevenCardBonuses)",
                    detail: nil
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if stats.totalBusts > 0 {
                HighlightRow(
                    icon: "xmark.circle.fill",
                    iconColor: DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme),
                    title: "Total Busts",
                    value: "\(stats.totalBusts)",
                    detail: nil
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if stats.totalNegativeModifierPoints > 0 {
                HighlightRow(
                    icon: "minus.circle.fill",
                    iconColor: DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme),
                    title: "Negative Modifiers",
                    value: "−\(stats.totalNegativeModifierPoints)",
                    detail: stats.totalDivideByTwoUsed > 0 ? "\(stats.totalDivideByTwoUsed) divide-by-2" : nil
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }

            if stats.totalRedirectedSevenCardBonuses > 0 {
                HighlightRow(
                    icon: "burst.fill",
                    iconColor: DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme),
                    title: "Redirected Bonuses",
                    value: "\(stats.totalRedirectedSevenCardBonuses)",
                    detail: "−\(stats.totalRedirectedSevenCardBonuses * ScoreEngine.sevenCardBonus) pts sent"
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }
        } header: {
            Text("Highlights")
        }
    }

    // MARK: - Charts Section

    @ViewBuilder
    private var chartsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Score Progression")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)

                CumulativeScoreChart(
                    dataPoints: cumulativeData,
                    players: game.players,
                    playerColors: playerColors
                )
                .frame(height: 190)
            }
            .padding(.vertical, 6)
            .statsRowStyle(background: rowBackground, separator: rowSeparator)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Round Scores")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Menu {
                        ForEach(game.players) { player in
                            Button {
                                selectedPlayerForChart = player.id
                            } label: {
                                HStack {
                                    Text(player.name)
                                    if selectedPlayerForChart == player.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if let playerId = selectedPlayerForChart,
                               let player = game.players.first(where: { $0.id == playerId }) {
                                Circle()
                                    .fill(colorForPlayer(playerId))
                                    .frame(width: 8, height: 8)
                                Text(player.name)
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme))
                        )
                    }
                    .accessibilityLabel("Select player for round scores chart")
                }

                if let playerId = selectedPlayerForChart {
                    RoundScoreBarChart(
                        dataPoints: stats.roundScoreChartData(for: playerId),
                        playerColor: colorForPlayer(playerId)
                    )
                    .frame(height: 145)
                }
            }
            .padding(.vertical, 6)
            .statsRowStyle(background: rowBackground, separator: rowSeparator)
        } header: {
            Text("Charts")
        }
    }

    // MARK: - Player Stats Section

    @ViewBuilder
    private var playerStatsSection: some View {
        Section {
            ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                Button {
                    selectedPlayerForDetail = player
                } label: {
                    PlayerStatRow(
                        player: player,
                        rank: index + 1,
                        playerStats: playerStatsById[player.id] ?? PlayerGameStats(playerId: player.id, game: game),
                        playerColor: colorForPlayer(player.id)
                    )
                }
                .buttonStyle(.plain)
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }
        } header: {
            Text("Player Stats")
        } footer: {
            Text("Tap a player for detailed breakdown")
                .font(DesignTypography.font(.caption))
        }
    }

    // MARK: - Round History Section

    @ViewBuilder
    private var roundHistorySection: some View {
        Section {
            ForEach(Array(game.gameHistory.enumerated().reversed()), id: \.offset) { _, gameRound in
                RoundHistoryRow(
                    gameRound: gameRound,
                    playerColors: playerColors,
                    players: game.players,
                    scoringRules: game.rules(for: gameRound)
                )
                .statsRowStyle(background: rowBackground, separator: rowSeparator)
            }
        } header: {
            Text("Round History")
        } footer: {
            if game.gameHistory.isEmpty {
                Text("No rounds have been completed yet.")
            }
        }
    }
}

private struct StatsRowChrome: ViewModifier {
    let background: Color
    let separator: Color

    func body(content: Content) -> some View {
        content
            .listRowBackground(background)
            .listRowSeparatorTint(separator.opacity(0.6))
    }
}

private extension View {
    func statsRowStyle(background: Color, separator: Color) -> some View {
        modifier(StatsRowChrome(background: background, separator: separator))
    }
}

// MARK: - Highlight Row

private struct HighlightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let detail: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.16))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTypography.font(.caption))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .monospacedDigit()

                    if let detail {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(detail)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Player Stat Row

private struct PlayerStatRow: View {
    let player: Player
    let rank: Int
    let playerColor: Color
    private let playerStats: PlayerGameStats
    private let bustCount: Int
    private let sevenCardBonusCount: Int

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    init(player: Player, rank: Int, playerStats: PlayerGameStats, playerColor: Color) {
        self.player = player
        self.rank = rank
        self.playerColor = playerColor
        self.playerStats = playerStats
        self.bustCount = playerStats.bustCount
        self.sevenCardBonusCount = playerStats.sevenCardBonusCount
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 26, height: 26)

                    if rank == 1 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(rankColor)
                    } else {
                        Text("\(rank)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(rankColor)
                    }
                }

                Text(player.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))

                Spacer()

                Text("\(player.totalScore) pts")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(rank == 1 ? accentColor : playerColor)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 16) {
                if !playerStats.roundScores.isEmpty {
                    ScoreSparkline(
                        scores: playerStats.roundScores,
                        color: playerColor,
                        height: 28
                    )
                    .frame(width: 60)
                }

                MiniStat(label: "Best", value: "\(playerStats.bestRoundScore)")
                MiniStat(label: "Avg", value: String(format: "%.0f", playerStats.averageRoundScore))
                MiniStat(label: "Busts", value: "\(bustCount)", isNegative: bustCount > 0)

                if sevenCardBonusCount > 0 {
                    MiniStat(label: "7-Card", value: "\(sevenCardBonusCount)", isPositive: true)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return AppBrandPalette.gold
        case 2: return AppBrandPalette.slate
        case 3: return AppBrandPalette.copper
        default: return .secondary
        }
    }
}

// MARK: - Mini Stat

private struct MiniStat: View {
    let label: String
    let value: String
    var isNegative: Bool = false
    var isPositive: Bool = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(
                    isNegative
                        ? DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
                        : (isPositive ? DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme) : .primary)
                )
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
    }
}

// MARK: - Round History Row

private struct RoundHistoryRow: View {
    let gameRound: GameRound
    let playerColors: [Color]
    let players: [Player]
    let scoringRules: ScoringRules

    @State private var isExpanded = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var sortedResults: [RoundResult] {
        gameRound.results.sorted { $0.roundScore > $1.roundScore }
    }

    private func colorForPlayer(_ playerId: UUID) -> Color {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else {
            return AppBrandPalette.brandBlue
        }
        return playerColors[safe: index] ?? AppBrandPalette.brandBlue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(DesignMotion.animation(.fast, reduced: isReducedMotion)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Round \(gameRound.roundNumber)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        if let winner = sortedResults.first {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colorForPlayer(winner.playerId))
                                    .frame(width: 8, height: 8)
                                Text("\(winner.roundScore)")
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                                    .monospacedDigit()
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(sortedResults, id: \.playerId) { result in
                        HStack {
                            Circle()
                                .fill(colorForPlayer(result.playerId))
                                .frame(width: 8, height: 8)

                            Text(result.playerName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(result.isBusted ? .secondary : .primary)
                                .lineLimit(1)

                            if let state = result.state {
                                StateBadge(state: state, mode: scoringRules.mode)
                            }

                            if result.hasSevenCardBonus {
                                Image(systemName: "7.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppBrandPalette.gold)
                            }

                            if result.x2Count > 0 {
                                Text("×\(1 << min(result.x2Count, 10))")
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppBrandPalette.brandBlueSky)
                            }

                            if result.divideByTwoCount > 0 {
                                Text("÷2")
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppBrandPalette.brandBlueSky)
                            }

                            if result.subtractModifierTotal > 0 {
                                Text("−\(result.subtractModifierTotal)")
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundStyle(DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme))
                            }

                            if result.specialNumberCount > 0 {
                                Label("\(result.specialNumberCount)", systemImage: "sparkles")
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppBrandPalette.gold)
                                    .labelStyle(.titleAndIcon)
                            }

                            Spacer()

                            if result.isBusted {
                                Text(scoringRules.brutalMode && result.roundScore < 0 ? "Bust \(result.roundScore)" : "Bust")
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                                    .foregroundStyle(DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme))
                            } else {
                                Text(result.roundScore > 0 ? "+\(result.roundScore)" : "\(result.roundScore)")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StateBadge: View {
    let state: PlayerRoundState
    let mode: GameMode
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch state {
        case .frozen:
            Text(mode == .vengeance ? "FORCED" : "FROZEN")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(DesignColor.color(.stateFrozen, theme: visualTheme, colorScheme: colorScheme))
        case .banked, .busted, .inRound:
            EmptyView()
        }
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    let player: Player
    let game: Game
    let playerColor: Color
    private let stats: PlayerGameStats
    private let chartPoints: [RoundDataPoint]
    private let rank: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    init(player: Player, game: Game, playerColor: Color) {
        self.player = player
        self.game = game
        self.playerColor = playerColor
        self.stats = PlayerGameStats(playerId: player.id, game: game)
        let gameStats = GameStats(game: game)
        self.chartPoints = gameStats.roundScoreChartData(for: player.id)
        let ranked = game.players.sorted { $0.totalScore > $1.totalScore }
        self.rank = (ranked.firstIndex(where: { $0.id == player.id }) ?? 0) + 1
    }

    private var usesMixedModes: Bool {
        game.modesUsed.count > 1
    }

    private var bankedOutcomeLabel: String {
        usesMixedModes ? "Banked / Stayed" : (game.scoringRules.mode == .vengeance ? "Stayed" : "Banked")
    }

    private var heldOutcomeLabel: String {
        usesMixedModes ? "Frozen / Forced" : (game.scoringRules.mode == .vengeance ? "Forced to Stay" : "Frozen")
    }

    private var cardStatsHeader: String {
        if usesMixedModes {
            return "Cards & Modifiers"
        }
        return game.scoringRules.mode == .classic ? "Bonuses & Multipliers" : "Special Cards & Modifiers"
    }

    private var rowBackground: Color {
        DesignColor.listRowBackground(theme: visualTheme, colorScheme: colorScheme)
    }

    private var rowSeparator: Color {
        DesignColor.border(theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(playerColor.opacity(0.2))
                                .frame(width: 58, height: 58)

                            if rank == 1 {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppBrandPalette.gold)
                            } else {
                                Text("#\(rank)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(playerColor)
                            }
                        }

                        Text("\(player.totalScore)")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .monospacedDigit()

                        Text("Total Points")
                            .font(DesignTypography.font(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .statsRowStyle(background: rowBackground, separator: rowSeparator)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Round Performance")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)

                        RoundScoreBarChart(
                            dataPoints: chartPoints,
                            playerColor: playerColor
                        )
                        .frame(height: 140)
                    }
                    .padding(.vertical, 4)
                    .statsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Performance")
                }

                Section {
                    DetailStatRow(label: "Best Round", value: "\(stats.bestRoundScore)")
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    DetailStatRow(label: "Average", value: String(format: "%.1f", stats.averageRoundScore))
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    DetailStatRow(label: "Median", value: "\(stats.medianRoundScore)")
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                    if let stdDev = stats.scoreStandardDeviation {
                        DetailStatRow(label: "Consistency (σ)", value: String(format: "%.1f", stdDev))
                            .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    }

                    if let worstNonBust = stats.worstNonBustScore {
                        DetailStatRow(label: "Worst (non-bust)", value: "\(worstNonBust)")
                            .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    }
                } header: {
                    Text("Scoring")
                }

                Section {
                    DetailStatRow(
                        label: "Busts",
                        value: "\(stats.bustCount)",
                        detail: String(format: "%.0f%% of rounds", stats.bustRate * 100),
                        valueColor: stats.bustCount > 0 ? DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme) : nil
                    )
                    .statsRowStyle(background: rowBackground, separator: rowSeparator)

                    DetailStatRow(label: bankedOutcomeLabel, value: "\(stats.bankedCount)")
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                    if stats.heldCount > 0 {
                        DetailStatRow(label: heldOutcomeLabel, value: "\(stats.heldCount)")
                            .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    }
                } header: {
                    Text("Outcomes")
                }

                Section {
                    DetailStatRow(
                        label: "7-Card Bonuses",
                        value: "\(stats.sevenCardBonusCount)",
                        detail: sevenCardBonusDetail,
                        valueColor: stats.sevenCardBonusCount > 0 ? AppBrandPalette.gold : nil
                    )
                    .statsRowStyle(background: rowBackground, separator: rowSeparator)

                    if game.modesUsed.contains(.classic) {
                        DetailStatRow(
                            label: "×2 Multipliers Used",
                            value: "\(stats.totalX2Used)",
                            detail: stats.totalMultiplierEffect > 0 ? "+\(stats.totalMultiplierEffect) pts" : nil,
                            valueColor: stats.totalX2Used > 0 ? AppBrandPalette.brandBlueSky : nil
                        )
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                        DetailStatRow(
                            label: "Modifier Points",
                            value: "+\(stats.totalModifiersUsed)",
                            valueColor: stats.totalModifiersUsed > 0 ? AppBrandPalette.copper : nil
                        )
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)
                    }

                    if game.modesUsed.contains(.vengeance) {
                        DetailStatRow(
                            label: "Divide-by-2 Cards",
                            value: "\(stats.totalDivideByTwoUsed)",
                            valueColor: stats.totalDivideByTwoUsed > 0 ? AppBrandPalette.brandBlueSky : nil
                        )
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                        DetailStatRow(
                            label: "Negative Modifier Points",
                            value: "−\(stats.totalNegativeModifierPoints)",
                            valueColor: stats.totalNegativeModifierPoints > 0 ? DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme) : nil
                        )
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                        DetailStatRow(
                            label: "Special Number Cards",
                            value: "\(stats.totalSpecialNumbersUsed)",
                            valueColor: stats.totalSpecialNumbersUsed > 0 ? AppBrandPalette.gold : nil
                        )
                        .statsRowStyle(background: rowBackground, separator: rowSeparator)

                        if stats.redirectedSevenCardBonusCount > 0 {
                            DetailStatRow(
                                label: "Bonuses Redirected",
                                value: "\(stats.redirectedSevenCardBonusCount)",
                                detail: "−\(stats.redirectedSevenCardBonusCount * ScoreEngine.sevenCardBonus) pts sent",
                                valueColor: DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
                            )
                            .statsRowStyle(background: rowBackground, separator: rowSeparator)
                        }
                    }
                } header: {
                    Text(cardStatsHeader)
                }

                if stats.longestNonBustStreak > 1 || stats.longestHighScoringStreak > 1 {
                    Section {
                        if stats.longestNonBustStreak > 1 {
                            DetailStatRow(label: "Longest Safe Streak", value: "\(stats.longestNonBustStreak) rounds")
                                .statsRowStyle(background: rowBackground, separator: rowSeparator)
                        }

                        if stats.longestHighScoringStreak > 1 {
                            DetailStatRow(label: "Hot Streak", value: "\(stats.longestHighScoringStreak) rounds", detail: "Above median")
                                .statsRowStyle(background: rowBackground, separator: rowSeparator)
                        }
                    } header: {
                        Text("Streaks")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .appChromeBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var sevenCardBonusDetail: String? {
        guard stats.sevenCardBonusCount > 0 else { return nil }
        if stats.redirectedSevenCardBonusCount > 0 {
            let kept = stats.sevenCardBonusCount - stats.redirectedSevenCardBonusCount
            return "\(kept) kept, \(stats.redirectedSevenCardBonusCount) redirected"
        }
        return "+\(stats.totalSevenCardBonusPoints) pts"
    }
}

private struct DetailStatRow: View {
    let label: String
    let value: String
    var detail: String? = nil
    var valueColor: Color? = nil
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))

            Spacer()

            HStack(spacing: 6) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(valueColor ?? accentColor)
                    .monospacedDigit()

                if let detail {
                    Text(detail)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
