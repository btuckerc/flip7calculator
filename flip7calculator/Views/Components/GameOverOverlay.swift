//
//  GameOverOverlay.swift
//  flip7calculator
//
//  Blocking custom overlay for game over state.
//  Shows winner info and provides Play Again, Stats, and New Game actions.
//

import SwiftUI

struct GameOverOverlay: View {
    @Bindable var viewModel: GameViewModel
    let onPlayAgain: () -> Void
    let onNewGame: () -> Void
    let onUndo: () -> Void
    
    @State private var isPresented = false
    @State private var showingStats = false
    
    private var game: Game? {
        viewModel.game
    }
    
    /// Returns players sorted by totalScore descending
    private var rankedPlayers: [Player] {
        guard let game = game else { return [] }
        return game.players.sorted { $0.totalScore > $1.totalScore }
    }
    
    /// The winner(s) - highest scoring player(s) who reached target
    private var winners: [Player] {
        guard let game = game else { return [] }
        let maxScore = rankedPlayers.first?.totalScore ?? 0
        // Winners are those with the max score who also reached target
        return rankedPlayers.filter { $0.totalScore == maxScore && $0.totalScore >= game.targetScore }
    }
    
    /// Number of rounds played
    private var roundsPlayed: Int {
        game?.gameHistory.count ?? 0
    }
    
    /// Player count for layout decisions
    private var playerCount: Int {
        rankedPlayers.count
    }
    
    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Main content - naturally respects safe areas
            VStack(spacing: 0) {
                // Top spacer - pushes card down from status bar
                Spacer()
                    .frame(minHeight: 8, maxHeight: 24)
                
                // Winner card - centered vertically in available space
                winnerCard
                    .padding(.horizontal, 20)
                
                // Flexible space between card and action bar
                Spacer()
                    .frame(minHeight: 16)
                
                // Action bar at bottom
                actionBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .scaleEffect(isPresented ? 1.0 : 0.95)
            .opacity(isPresented ? 1.0 : 0.0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isPresented = true
            }
        }
        .sheet(isPresented: $showingStats) {
            if let game = game {
                GameOverStatsView(game: game)
            }
        }
    }
    
    // MARK: - Winner Card
    
    /// Use compact layout when we have many players
    private var useCompactLayout: Bool {
        playerCount >= 7
    }
    
    @ViewBuilder
    private var winnerCard: some View {
        VStack(spacing: useCompactLayout ? 10 : 14) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: useCompactLayout ? 38 : 48))
                .foregroundStyle(.yellow)
                .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)
            
            // Game Over title
            Text("Game Over!")
                .font(.system(size: useCompactLayout ? 24 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Winner message
            if !winners.isEmpty {
                VStack(spacing: 3) {
                    if winners.count == 1 {
                        Text("\(winners[0].name) Wins!")
                            .font(.system(size: useCompactLayout ? 18 : 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                    } else {
                        Text("Tie: \(winners.map { $0.name }.joined(separator: " & "))")
                            .font(.system(size: useCompactLayout ? 18 : 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("\(winners[0].totalScore) points")
                        .font(.system(size: useCompactLayout ? 14 : 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Game stats summary
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(roundsPlayed)")
                        .font(.system(size: useCompactLayout ? 17 : 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Rounds")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                if let game = game {
                    VStack(spacing: 2) {
                        Text("\(game.targetScore)")
                            .font(.system(size: useCompactLayout ? 17 : 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Target")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 2)
            
            // Divider
            Divider()
                .padding(.vertical, useCompactLayout ? 6 : 8)
            
            // Final Scores section
            finalScoresSection
        }
        .padding(.vertical, useCompactLayout ? 16 : 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Final Scores Section
    
    @ViewBuilder
    private var finalScoresSection: some View {
        let rowSpacing: CGFloat = useCompactLayout ? 3 : 6
        let badgeSize: CGFloat = useCompactLayout ? 24 : 28
        let fontSize: CGFloat = useCompactLayout ? 14 : 16
        
        VStack(spacing: rowSpacing) {
            Text("FINAL SCORES")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.bottom, 2)
            
            // All players ranked by score
            ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 12) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(rankColor(for: index).opacity(0.2))
                            .frame(width: badgeSize, height: badgeSize)
                        
                        if index == 0 {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(rankColor(for: index))
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: useCompactLayout ? 12 : 14, weight: .bold, design: .rounded))
                                .foregroundStyle(rankColor(for: index))
                        }
                    }
                    
                    // Player name
                    Text(player.name)
                        .font(.system(size: fontSize, weight: index == 0 ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(index == 0 ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Score
                    Text("\(player.totalScore)")
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(index == 0 ? .blue : .secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Action Bar
    
    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 12) {
            // Undo button (dismisses overlay and undoes last action)
            Button(action: {
                HapticFeedback.light()
                viewModel.undo()
                onUndo()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Undo")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .foregroundColor(viewModel.canUndo ? .blue : .gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.canUndo ? Color.blue.opacity(0.1) : Color(.secondarySystemFill))
                .cornerRadius(10)
            }
            .disabled(!viewModel.canUndo)
            
            // Play Again - keeps same players and settings
            Button(action: {
                HapticFeedback.success()
                onPlayAgain()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Play Again")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue)
                .cornerRadius(12)
            }
            
            // Secondary actions row
            HStack(spacing: 12) {
                // Stats button
                Button(action: {
                    HapticFeedback.light()
                    showingStats = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.number")
                            .font(.system(size: 14, weight: .medium))
                        Text("Stats")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // New Game button - goes to setup
                Button(action: {
                    HapticFeedback.medium()
                    onNewGame()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("New Game")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(.systemGray)
        case 2: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Previews

#Preview("4 Players") {
    GameOverOverlay(
        viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(players: ["Alice", "Bob", "Charlie", "Diana"], targetScore: 200)
            if var game = vm.game {
                game.players[0].totalScore = 225
                game.players[1].totalScore = 180
                game.players[2].totalScore = 150
                game.players[3].totalScore = 120
                vm.game = game
            }
            return vm
        }(),
        onPlayAgain: {},
        onNewGame: {},
        onUndo: {}
    )
}

#Preview("6 Players") {
    GameOverOverlay(
        viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(players: ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"], targetScore: 200)
            if var game = vm.game {
                game.players[0].totalScore = 225
                game.players[1].totalScore = 180
                game.players[2].totalScore = 150
                game.players[3].totalScore = 120
                game.players[4].totalScore = 95
                game.players[5].totalScore = 60
                vm.game = game
            }
            return vm
        }(),
        onPlayAgain: {},
        onNewGame: {},
        onUndo: {}
    )
}

#Preview("8 Players - Worst Case") {
    GameOverOverlay(
        viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(players: [
                "Alexander",
                "Bartholomew", 
                "Christopher",
                "Dominique",
                "Elizabeth",
                "Francesco",
                "Gabriella",
                "Maximilian"
            ], targetScore: 200)
            if var game = vm.game {
                game.players[0].totalScore = 201
                game.players[1].totalScore = 185
                game.players[2].totalScore = 162
                game.players[3].totalScore = 148
                game.players[4].totalScore = 127
                game.players[5].totalScore = 98
                game.players[6].totalScore = 76
                game.players[7].totalScore = 45
                vm.game = game
            }
            return vm
        }(),
        onPlayAgain: {},
        onNewGame: {},
        onUndo: {}
    )
}

#Preview("8 Players - Long Names") {
    GameOverOverlay(
        viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(players: [
                "Sir Reginald Bartholomew III",
                "Princess Anastasia",
                "Captain Jack Sparrow",
                "Queen Elizabeth II",
                "Lord Voldemort",
                "Gandalf the Grey",
                "Hermione Granger",
                "Darth Vader"
            ], targetScore: 200)
            if var game = vm.game {
                game.players[0].totalScore = 250
                game.players[1].totalScore = 198
                game.players[2].totalScore = 175
                game.players[3].totalScore = 150
                game.players[4].totalScore = 125
                game.players[5].totalScore = 100
                game.players[6].totalScore = 75
                game.players[7].totalScore = 50
                vm.game = game
            }
            return vm
        }(),
        onPlayAgain: {},
        onNewGame: {},
        onUndo: {}
    )
}

#Preview("2 Players - Minimum") {
    GameOverOverlay(
        viewModel: {
            let vm = GameViewModel()
            vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
            if var game = vm.game {
                game.players[0].totalScore = 215
                game.players[1].totalScore = 180
                vm.game = game
            }
            return vm
        }(),
        onPlayAgain: {},
        onNewGame: {},
        onUndo: {}
    )
}



