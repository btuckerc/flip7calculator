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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerForChart: UUID?
    @State private var selectedPlayerForDetail: Player?
    
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }
    
    private var stats: GameStats {
        GameStats(game: game)
    }
    
    private var playerColors: [Color] {
        PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette)
    }
    
    private func colorForPlayer(_ playerId: UUID) -> Color {
        guard let index = game.players.firstIndex(where: { $0.id == playerId }) else {
            return .gray
        }
        return playerColors[safe: index] ?? .gray
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Highlights Section
                highlightsSection
                
                // Charts Section
                chartsSection
                
                // Player Stats Section
                playerStatsSection
                
                // Round History Section
                roundHistorySection
            }
            .navigationTitle("Game Stats")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                if selectedPlayerForChart == nil, let first = game.players.first {
                    selectedPlayerForChart = first.id
                }
            }
        }
    }
    
    // MARK: - Highlights Section
    
    @ViewBuilder
    private var highlightsSection: some View {
        Section {
            // Winner and margin
            if !stats.winners.isEmpty {
                HighlightRow(
                    icon: "crown.fill",
                    iconColor: .yellow,
                    title: stats.winners.count > 1 ? "Winners" : "Winner",
                    value: stats.winners.map { $0.name }.joined(separator: ", "),
                    detail: stats.winningMargin > 0 ? "Won by \(stats.winningMargin) pts" : nil
                )
            }
            
            // Lead changes
            if stats.leadChanges > 0 {
                HighlightRow(
                    icon: "arrow.left.arrow.right",
                    iconColor: .purple,
                    title: "Lead Changes",
                    value: "\(stats.leadChanges)",
                    detail: nil
                )
            }
            
            // Biggest comeback
            if let comeback = stats.biggestComeback, comeback.deficit > 10 {
                HighlightRow(
                    icon: "arrow.up.right",
                    iconColor: .green,
                    title: "Biggest Comeback",
                    value: comeback.player.name,
                    detail: "Overcame \(comeback.deficit) pt deficit"
                )
            }
            
            // Best single round
            if let best = stats.bestRoundScore {
                HighlightRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Best Round",
                    value: "\(best.score) pts",
                    detail: "\(best.playerName) in R\(best.round)"
                )
            }
            
            // Most consistent (if meaningful)
            if let consistent = stats.mostConsistent, stats.roundsPlayed >= 3 {
                HighlightRow(
                    icon: "target",
                    iconColor: .blue,
                    title: "Most Consistent",
                    value: consistent.player.name,
                    detail: "σ = \(String(format: "%.1f", consistent.stdDev))"
                )
            }
            
            // Aggregate fun facts
            if stats.totalFlip7s > 0 {
                HighlightRow(
                    icon: "7.circle.fill",
                    iconColor: .mint,
                    title: "Total Flip 7s",
                    value: "\(stats.totalFlip7s)",
                    detail: nil
                )
            }
            
            if stats.totalBusts > 0 {
                HighlightRow(
                    icon: "xmark.circle.fill",
                    iconColor: .red.opacity(0.8),
                    title: "Total Busts",
                    value: "\(stats.totalBusts)",
                    detail: nil
                )
            }
        } header: {
            Text("Highlights")
        }
    }
    
    // MARK: - Charts Section
    
    @ViewBuilder
    private var chartsSection: some View {
        Section {
            // Cumulative score line chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Score Progression")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                CumulativeScoreChart(
                    dataPoints: stats.cumulativeChartData(),
                    players: game.players,
                    playerColors: playerColors
                )
                .frame(height: 180)
            }
            .padding(.vertical, 4)
            
            // Per-player round scores bar chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Round Scores")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Player picker
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
                        HStack(spacing: 4) {
                            if let playerId = selectedPlayerForChart,
                               let player = game.players.first(where: { $0.id == playerId }) {
                                Circle()
                                    .fill(colorForPlayer(playerId))
                                    .frame(width: 8, height: 8)
                                Text(player.name)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                if let playerId = selectedPlayerForChart {
                    RoundScoreBarChart(
                        dataPoints: stats.roundScoreChartData(for: playerId),
                        playerColor: colorForPlayer(playerId)
                    )
                    .frame(height: 140)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Charts")
        }
    }
    
    // MARK: - Player Stats Section
    
    @ViewBuilder
    private var playerStatsSection: some View {
        Section {
            ForEach(Array(stats.rankedPlayers.enumerated()), id: \.element.id) { index, player in
                Button {
                    selectedPlayerForDetail = player
                } label: {
                    PlayerStatRow(
                        player: player,
                        rank: index + 1,
                        game: game,
                        playerColor: colorForPlayer(player.id)
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Player Stats")
        } footer: {
            Text("Tap a player for detailed breakdown")
                .font(.system(size: 12, design: .rounded))
        }
    }
    
    // MARK: - Round History Section
    
    @ViewBuilder
    private var roundHistorySection: some View {
        Section {
            ForEach(game.gameHistory.reversed(), id: \.roundNumber) { gameRound in
                RoundHistoryRow(gameRound: gameRound, playerColors: playerColors, players: game.players)
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
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    
                    if let detail = detail {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(detail)
                            .font(.system(size: 13, design: .rounded))
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
    let game: Game
    let playerColor: Color
    
    private var playerStats: PlayerGameStats {
        PlayerGameStats(playerId: player.id, game: game)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player header
            HStack {
                // Rank badge
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
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(rankColor)
                    }
                }
                
                Text(player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Text("\(player.totalScore) pts")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(rank == 1 ? .blue : .primary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            
            // Mini sparkline + stats
            HStack(spacing: 16) {
                // Sparkline
                if !playerStats.roundScores.isEmpty {
                    ScoreSparkline(
                        scores: playerStats.roundScores,
                        color: playerColor,
                        height: 28
                    )
                    .frame(width: 60)
                }
                
                // Quick stats
                MiniStat(label: "Best", value: "\(playerStats.bestRoundScore)")
                MiniStat(label: "Avg", value: String(format: "%.0f", playerStats.averageRoundScore))
                MiniStat(label: "Busts", value: "\(playerStats.bustCount)", isNegative: playerStats.bustCount > 0)
                
                if playerStats.flip7Count > 0 {
                    MiniStat(label: "Flip7", value: "\(playerStats.flip7Count)", isPositive: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
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
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isNegative ? .red.opacity(0.8) : (isPositive ? .green : .primary))
            Text(label)
                .font(.system(size: 11, design: .rounded))
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
    
    @State private var isExpanded = false
    
    private var sortedResults: [RoundResult] {
        gameRound.results.sorted { $0.roundScore > $1.roundScore }
    }
    
    private func colorForPlayer(_ playerId: UUID) -> Color {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else {
            return .gray
        }
        return playerColors[safe: index] ?? .gray
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Round header (tappable to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Round \(gameRound.roundNumber)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Quick summary
                    HStack(spacing: 8) {
                        if let winner = sortedResults.first, winner.roundScore > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colorForPlayer(winner.playerId))
                                    .frame(width: 8, height: 8)
                                Text("\(winner.roundScore)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                            }
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Expanded details
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(sortedResults, id: \.playerId) { result in
                        HStack {
                            Circle()
                                .fill(colorForPlayer(result.playerId))
                                .frame(width: 8, height: 8)
                            
                            Text(result.playerName)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(result.isBusted ? .secondary : .primary)
                                .lineLimit(1)
                            
                            // State badge
                            if let state = result.state {
                                StateBadge(state: state)
                            }
                            
                            // Flip7 indicator
                            if result.hasFlip7 {
                                Image(systemName: "7.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.mint)
                            }
                            
                            // x2 indicator
                            if result.x2Count > 0 {
                                Text("×\(Int(pow(2.0, Double(result.x2Count))))")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.purple)
                            }
                            
                            Spacer()
                            
                            if result.isBusted {
                                Text("Bust")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.red.opacity(0.8))
                            } else {
                                Text("+\(result.roundScore)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.green)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - State Badge

private struct StateBadge: View {
    let state: PlayerRoundState
    
    var body: some View {
        switch state {
        case .banked:
            EmptyView()
        case .frozen:
            Text("❄️")
                .font(.system(size: 10))
        case .busted:
            EmptyView() // Already shown with "Bust" text
        case .inRound:
            EmptyView()
        }
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    let player: Player
    let game: Game
    let playerColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private var stats: PlayerGameStats {
        PlayerGameStats(playerId: player.id, game: game)
    }
    
    private var gameStats: GameStats {
        GameStats(game: game)
    }
    
    private var rank: Int {
        let ranked = game.players.sorted { $0.totalScore > $1.totalScore }
        return (ranked.firstIndex(where: { $0.id == player.id }) ?? 0) + 1
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header with final score
                Section {
                    VStack(spacing: 12) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(playerColor.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            if rank == 1 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.yellow)
                            } else {
                                Text("#\(rank)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(playerColor)
                            }
                        }
                        
                        Text("\(player.totalScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        
                        Text("Total Points")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                // Round-by-round chart
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Round Performance")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        RoundScoreBarChart(
                            dataPoints: gameStats.roundScoreChartData(for: player.id),
                            playerColor: playerColor
                        )
                        .frame(height: 140)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Performance")
                }
                
                // Core stats
                Section {
                    DetailStatRow(label: "Best Round", value: "\(stats.bestRoundScore)")
                    DetailStatRow(label: "Average", value: String(format: "%.1f", stats.averageRoundScore))
                    DetailStatRow(label: "Median", value: "\(stats.medianRoundScore)")
                    
                    if let stdDev = stats.scoreStandardDeviation {
                        DetailStatRow(label: "Consistency (σ)", value: String(format: "%.1f", stdDev))
                    }
                    
                    if let worstNonBust = stats.worstNonBustScore {
                        DetailStatRow(label: "Worst (non-bust)", value: "\(worstNonBust)")
                    }
                } header: {
                    Text("Scoring")
                }
                
                // Outcomes
                Section {
                    DetailStatRow(
                        label: "Busts",
                        value: "\(stats.bustCount)",
                        detail: String(format: "%.0f%% of rounds", stats.bustRate * 100),
                        valueColor: stats.bustCount > 0 ? .red.opacity(0.8) : nil
                    )
                    
                    DetailStatRow(label: "Banked", value: "\(stats.bankedCount)")
                    
                    if stats.frozenCount > 0 {
                        DetailStatRow(label: "Frozen", value: "\(stats.frozenCount)")
                    }
                } header: {
                    Text("Outcomes")
                }
                
                // Bonuses & Multipliers
                Section {
                    DetailStatRow(
                        label: "Flip 7 Bonuses",
                        value: "\(stats.flip7Count)",
                        detail: stats.flip7Count > 0 ? "+\(stats.totalFlip7Bonus) pts" : nil,
                        valueColor: stats.flip7Count > 0 ? .mint : nil
                    )
                    
                    DetailStatRow(
                        label: "×2 Multipliers Used",
                        value: "\(stats.totalX2Used)",
                        detail: stats.totalMultiplierEffect > 0 ? "+\(stats.totalMultiplierEffect) pts" : nil,
                        valueColor: stats.totalX2Used > 0 ? .purple : nil
                    )
                    
                    DetailStatRow(
                        label: "Modifier Points",
                        value: "+\(stats.totalModifiersUsed)",
                        valueColor: stats.totalModifiersUsed > 0 ? .orange : nil
                    )
                } header: {
                    Text("Bonuses & Multipliers")
                }
                
                // Streaks
                if stats.longestNonBustStreak > 1 || stats.longestHighScoringStreak > 1 {
                    Section {
                        if stats.longestNonBustStreak > 1 {
                            DetailStatRow(label: "Longest Safe Streak", value: "\(stats.longestNonBustStreak) rounds")
                        }
                        
                        if stats.longestHighScoringStreak > 1 {
                            DetailStatRow(label: "Hot Streak", value: "\(stats.longestHighScoringStreak) rounds", detail: "Above median")
                        }
                    } header: {
                        Text("Streaks")
                    }
                }
            }
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Detail Stat Row

private struct DetailStatRow: View {
    let label: String
    let value: String
    var detail: String? = nil
    var valueColor: Color? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, design: .rounded))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(valueColor ?? .blue)
                    .monospacedDigit()
                
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    GameOverStatsView(game: {
        var game = Game(players: [
            Player(name: "Alice"),
            Player(name: "Bob"),
            Player(name: "Charlie")
        ], targetScore: 200)
        
        // Simulate some game history with snapshots
        game.gameHistory = [
            GameRound(roundNumber: 1, results: [
                RoundResult(
                    playerId: game.players[0].id,
                    playerName: "Alice",
                    roundScore: 45,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [2, 5, 8, 10, 12], x2Count: 0, addMods: [4: 1]),
                    autoScore: 45
                ),
                RoundResult(
                    playerId: game.players[1].id,
                    playerName: "Bob",
                    roundScore: 32,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [3, 7, 11, 9], x2Count: 0, addMods: [:]),
                    autoScore: 32
                ),
                RoundResult(
                    playerId: game.players[2].id,
                    playerName: "Charlie",
                    roundScore: 0,
                    state: .busted,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [1, 4, 6], x2Count: 0, addMods: [:]),
                    autoScore: 0
                )
            ]),
            GameRound(roundNumber: 2, results: [
                RoundResult(
                    playerId: game.players[0].id,
                    playerName: "Alice",
                    roundScore: 0,
                    state: .busted,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [1, 3], x2Count: 0, addMods: [:]),
                    autoScore: 0
                ),
                RoundResult(
                    playerId: game.players[1].id,
                    playerName: "Bob",
                    roundScore: 58,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [0, 2, 4, 6, 8, 10, 12], x2Count: 0, addMods: [:]),
                    autoScore: 58
                ),
                RoundResult(
                    playerId: game.players[2].id,
                    playerName: "Charlie",
                    roundScore: 41,
                    state: .frozen,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [5, 7, 9, 11], x2Count: 0, addMods: [6: 1]),
                    autoScore: 41
                )
            ]),
            GameRound(roundNumber: 3, results: [
                RoundResult(
                    playerId: game.players[0].id,
                    playerName: "Alice",
                    roundScore: 82,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [0, 1, 2, 3, 4, 5, 6], x2Count: 1, addMods: [:]),
                    autoScore: 82
                ),
                RoundResult(
                    playerId: game.players[1].id,
                    playerName: "Bob",
                    roundScore: 25,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [3, 7, 12], x2Count: 0, addMods: [:]),
                    autoScore: 25
                ),
                RoundResult(
                    playerId: game.players[2].id,
                    playerName: "Charlie",
                    roundScore: 38,
                    state: .banked,
                    manualScoreOverride: nil,
                    handSnapshot: RoundHand(selectedNumbers: [2, 8, 11], x2Count: 0, addMods: [8: 1, 4: 1]),
                    autoScore: 38
                )
            ])
        ]
        
        game.players[0].totalScore = 127
        game.players[1].totalScore = 115
        game.players[2].totalScore = 79
        
        return game
    }())
}
