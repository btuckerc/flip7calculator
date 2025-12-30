//
//  GameStats.swift
//  flip7calculator
//
//  Pure stat computation utilities for game-over analysis.
//

import Foundation

// MARK: - Game-Level Stats

/// Computed statistics for an entire game
struct GameStats {
    let game: Game
    
    // MARK: - Basic Info
    
    var roundsPlayed: Int {
        game.gameHistory.count
    }
    
    var totalPointsScored: Int {
        game.players.reduce(0) { $0 + $1.totalScore }
    }
    
    var averageScorePerPlayer: Double {
        guard !game.players.isEmpty else { return 0 }
        return Double(totalPointsScored) / Double(game.players.count)
    }
    
    // MARK: - Winners
    
    /// Players sorted by final score descending
    var rankedPlayers: [Player] {
        game.players.sorted { $0.totalScore > $1.totalScore }
    }
    
    /// The winner(s) - highest scoring player(s)
    var winners: [Player] {
        guard let maxScore = game.players.map({ $0.totalScore }).max() else { return [] }
        return game.players.filter { $0.totalScore == maxScore }
    }
    
    /// Points difference between 1st and 2nd place
    var winningMargin: Int {
        let scores = game.players.map { $0.totalScore }.sorted(by: >)
        guard scores.count >= 2 else { return scores.first ?? 0 }
        return scores[0] - scores[1]
    }
    
    // MARK: - Lead Changes
    
    /// Cumulative scores after each round for each player
    var cumulativeScoresByRound: [[UUID: Int]] {
        var cumulative: [UUID: Int] = Dictionary(uniqueKeysWithValues: game.players.map { ($0.id, 0) })
        var result: [[UUID: Int]] = []
        
        for round in game.gameHistory {
            for res in round.results {
                cumulative[res.playerId, default: 0] += res.roundScore
            }
            result.append(cumulative)
        }
        return result
    }
    
    /// Number of times the leader changed between rounds
    var leadChanges: Int {
        let cumScores = cumulativeScoresByRound
        guard cumScores.count > 1 else { return 0 }
        
        var changes = 0
        var previousLeaders: Set<UUID> = []
        
        for scores in cumScores {
            let maxScore = scores.values.max() ?? 0
            let currentLeaders = Set(scores.filter { $0.value == maxScore }.keys)
            
            if !previousLeaders.isEmpty && currentLeaders != previousLeaders {
                changes += 1
            }
            previousLeaders = currentLeaders
        }
        return changes
    }
    
    /// Player who spent the most rounds in the lead
    var mostTimeInLead: (player: Player, rounds: Int)? {
        let cumScores = cumulativeScoresByRound
        guard !cumScores.isEmpty else { return nil }
        
        var leadCounts: [UUID: Int] = [:]
        
        for scores in cumScores {
            let maxScore = scores.values.max() ?? 0
            let leaders = scores.filter { $0.value == maxScore }.keys
            for leaderId in leaders {
                leadCounts[leaderId, default: 0] += 1
            }
        }
        
        guard let (leaderId, count) = leadCounts.max(by: { $0.value < $1.value }),
              let player = game.players.first(where: { $0.id == leaderId }) else { return nil }
        
        return (player, count)
    }
    
    // MARK: - Comebacks
    
    /// Biggest deficit overcome: player who was furthest behind at some point but finished higher
    var biggestComeback: (player: Player, deficit: Int, fromRound: Int)? {
        let cumScores = cumulativeScoresByRound
        guard cumScores.count > 1 else { return nil }
        
        var biggestComeback: (player: Player, deficit: Int, fromRound: Int)?
        let finalScores = cumScores.last!
        
        for (roundIndex, scores) in cumScores.dropLast().enumerated() {
            let maxScore = scores.values.max() ?? 0
            
            for playerId in game.players.map({ $0.id }) {
                let playerScore = scores[playerId] ?? 0
                let deficit = maxScore - playerScore
                
                // Check if this player finished ahead of the leader at this point
                if deficit > 0 {
                    let finalPlayerScore = finalScores[playerId] ?? 0
                    let leadersAtTime = scores.filter { $0.value == maxScore }.keys
                    
                    for leaderId in leadersAtTime {
                        let leaderFinalScore = finalScores[leaderId] ?? 0
                        if finalPlayerScore > leaderFinalScore {
                            if biggestComeback == nil || deficit > biggestComeback!.deficit {
                                if let player = game.players.first(where: { $0.id == playerId }) {
                                    biggestComeback = (player, deficit, roundIndex + 1)
                                }
                            }
                        }
                    }
                }
            }
        }
        return biggestComeback
    }
    
    // MARK: - Round Extremes
    
    /// Best single-round score in the game
    var bestRoundScore: (playerName: String, score: Int, round: Int)? {
        var best: (playerName: String, score: Int, round: Int)?
        
        for gameRound in game.gameHistory {
            for result in gameRound.results {
                if best == nil || result.roundScore > best!.score {
                    best = (result.playerName, result.roundScore, gameRound.roundNumber)
                }
            }
        }
        return best
    }
    
    /// Round with the smallest spread between highest and lowest non-bust score
    var closestRound: (roundNumber: Int, spread: Int)? {
        var closest: (roundNumber: Int, spread: Int)?
        
        for gameRound in game.gameHistory {
            let scores = gameRound.results.map { $0.roundScore }
            let nonBustScores = scores.filter { $0 > 0 }
            guard nonBustScores.count >= 2 else { continue }
            
            let spread = (nonBustScores.max() ?? 0) - (nonBustScores.min() ?? 0)
            if closest == nil || spread < closest!.spread {
                closest = (gameRound.roundNumber, spread)
            }
        }
        return closest
    }
    
    /// Round with the biggest spread (blowout)
    var biggestBlowoutRound: (roundNumber: Int, spread: Int)? {
        var biggest: (roundNumber: Int, spread: Int)?
        
        for gameRound in game.gameHistory {
            let scores = gameRound.results.map { $0.roundScore }
            guard scores.count >= 2 else { continue }
            
            let spread = (scores.max() ?? 0) - (scores.min() ?? 0)
            if biggest == nil || spread > biggest!.spread {
                biggest = (gameRound.roundNumber, spread)
            }
        }
        return biggest
    }
    
    // MARK: - Aggregate Totals
    
    /// Total number of busts across all players and rounds
    var totalBusts: Int {
        game.gameHistory.reduce(0) { total, round in
            total + round.results.filter { $0.isBusted }.count
        }
    }
    
    /// Total Flip7 bonuses achieved
    var totalFlip7s: Int {
        game.gameHistory.reduce(0) { total, round in
            total + round.results.filter { $0.hasFlip7 }.count
        }
    }
    
    /// Total x2 multipliers used
    var totalX2Used: Int {
        game.gameHistory.reduce(0) { total, round in
            total + round.results.reduce(0) { $0 + $1.x2Count }
        }
    }
    
    /// Total modifier points added
    var totalModifiersUsed: Int {
        game.gameHistory.reduce(0) { total, round in
            total + round.results.reduce(0) { $0 + $1.modifierTotal }
        }
    }
    
    // MARK: - Player Comparisons
    
    /// Player with the most busts
    var mostBusts: (player: Player, count: Int)? {
        let bustCounts = playerBustCounts
        guard let (playerId, count) = bustCounts.max(by: { $0.value < $1.value }),
              let player = game.players.first(where: { $0.id == playerId }),
              count > 0 else { return nil }
        return (player, count)
    }
    
    /// Player with the most Flip7 bonuses
    var mostFlip7s: (player: Player, count: Int)? {
        let flip7Counts = playerFlip7Counts
        guard let (playerId, count) = flip7Counts.max(by: { $0.value < $1.value }),
              let player = game.players.first(where: { $0.id == playerId }),
              count > 0 else { return nil }
        return (player, count)
    }
    
    /// Most consistent player (lowest standard deviation of non-bust rounds)
    var mostConsistent: (player: Player, stdDev: Double)? {
        var bestPlayer: Player?
        var lowestStdDev: Double = .infinity
        
        for player in game.players {
            let stats = PlayerGameStats(playerId: player.id, game: game)
            if let stdDev = stats.scoreStandardDeviation, stats.nonBustRoundScores.count >= 2 {
                if stdDev < lowestStdDev {
                    lowestStdDev = stdDev
                    bestPlayer = player
                }
            }
        }
        
        guard let player = bestPlayer else { return nil }
        return (player, lowestStdDev)
    }
    
    // MARK: - Helper Counts
    
    private var playerBustCounts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for round in game.gameHistory {
            for result in round.results where result.isBusted {
                counts[result.playerId, default: 0] += 1
            }
        }
        return counts
    }
    
    private var playerFlip7Counts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for round in game.gameHistory {
            for result in round.results where result.hasFlip7 {
                counts[result.playerId, default: 0] += 1
            }
        }
        return counts
    }
}

// MARK: - Player-Level Stats

/// Computed statistics for a single player within a game
struct PlayerGameStats {
    let playerId: UUID
    let game: Game
    
    /// All round results for this player
    var roundResults: [RoundResult] {
        game.gameHistory.compactMap { round in
            round.results.first(where: { $0.playerId == playerId })
        }
    }
    
    /// All round scores (including busts as 0)
    var roundScores: [Int] {
        roundResults.map { $0.roundScore }
    }
    
    /// Only non-bust round scores
    var nonBustRoundScores: [Int] {
        roundResults.filter { !$0.isBusted }.map { $0.roundScore }
    }
    
    // MARK: - Basic Stats
    
    var totalScore: Int {
        roundScores.reduce(0, +)
    }
    
    var averageRoundScore: Double {
        guard !roundScores.isEmpty else { return 0 }
        return Double(roundScores.reduce(0, +)) / Double(roundScores.count)
    }
    
    var medianRoundScore: Int {
        let sorted = roundScores.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }
    
    /// Standard deviation of round scores (nil if < 2 rounds)
    var scoreStandardDeviation: Double? {
        guard roundScores.count >= 2 else { return nil }
        let mean = averageRoundScore
        let squaredDiffs = roundScores.map { pow(Double($0) - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(roundScores.count)
        return sqrt(variance)
    }
    
    // MARK: - Best/Worst
    
    var bestRoundScore: Int {
        roundScores.max() ?? 0
    }
    
    var worstNonBustScore: Int? {
        nonBustRoundScores.min()
    }
    
    var bestRoundNumber: Int? {
        guard let maxScore = roundScores.max() else { return nil }
        for (index, score) in roundScores.enumerated() {
            if score == maxScore {
                return index + 1
            }
        }
        return nil
    }
    
    // MARK: - Bust/State Stats
    
    var bustCount: Int {
        roundResults.filter { $0.isBusted }.count
    }
    
    var bustRate: Double {
        guard !roundResults.isEmpty else { return 0 }
        return Double(bustCount) / Double(roundResults.count)
    }
    
    var bankedCount: Int {
        roundResults.filter { $0.state == .banked }.count
    }
    
    var frozenCount: Int {
        roundResults.filter { $0.state == .frozen }.count
    }
    
    // MARK: - Flip7 / Multipliers / Modifiers
    
    var flip7Count: Int {
        roundResults.filter { $0.hasFlip7 }.count
    }
    
    var totalX2Used: Int {
        roundResults.reduce(0) { $0 + $1.x2Count }
    }
    
    var totalModifiersUsed: Int {
        roundResults.reduce(0) { $0 + $1.modifierTotal }
    }
    
    // MARK: - Score Breakdown
    
    /// Total points from number cards (base sum before multipliers)
    var totalNumberPoints: Int {
        roundResults.compactMap { $0.handSnapshot?.numberSum }.reduce(0, +)
    }
    
    /// Estimated multiplier effect (difference between multiplied and base)
    var totalMultiplierEffect: Int {
        roundResults.reduce(0) { total, result in
            guard let hand = result.handSnapshot, !result.isBusted else { return total }
            let baseSum = hand.numberSum
            let multipliedSum = baseSum * Int(pow(2.0, Double(hand.x2Count)))
            return total + (multipliedSum - baseSum)
        }
    }
    
    /// Total Flip7 bonus points earned
    var totalFlip7Bonus: Int {
        flip7Count * ScoreEngine.flip7Bonus
    }
    
    // MARK: - Streaks
    
    /// Longest streak of consecutive non-bust rounds
    var longestNonBustStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        
        for result in roundResults {
            if !result.isBusted {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    /// Longest streak of consecutive "high scoring" rounds (above player's median)
    var longestHighScoringStreak: Int {
        let median = medianRoundScore
        var maxStreak = 0
        var currentStreak = 0
        
        for score in roundScores {
            if score > median {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    // MARK: - Cumulative Progress
    
    /// Cumulative score after each round
    var cumulativeScores: [Int] {
        var cumulative = 0
        return roundScores.map { score in
            cumulative += score
            return cumulative
        }
    }
}

// MARK: - Chart Data Helpers

/// Data point for charts
struct RoundDataPoint: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let score: Int
    let playerName: String
    let playerId: UUID
}

extension GameStats {
    /// Generate data points for cumulative score line chart
    func cumulativeChartData() -> [RoundDataPoint] {
        var dataPoints: [RoundDataPoint] = []
        var cumulative: [UUID: Int] = Dictionary(uniqueKeysWithValues: game.players.map { ($0.id, 0) })
        
        // Add starting point (round 0, score 0)
        for player in game.players {
            dataPoints.append(RoundDataPoint(roundNumber: 0, score: 0, playerName: player.name, playerId: player.id))
        }
        
        for round in game.gameHistory {
            for result in round.results {
                cumulative[result.playerId, default: 0] += result.roundScore
                dataPoints.append(RoundDataPoint(
                    roundNumber: round.roundNumber,
                    score: cumulative[result.playerId] ?? 0,
                    playerName: result.playerName,
                    playerId: result.playerId
                ))
            }
        }
        return dataPoints
    }
    
    /// Generate data points for round-by-round bar chart for a specific player
    func roundScoreChartData(for playerId: UUID) -> [RoundDataPoint] {
        let playerName = game.players.first(where: { $0.id == playerId })?.name ?? "Unknown"
        
        return game.gameHistory.compactMap { round -> RoundDataPoint? in
            guard let result = round.results.first(where: { $0.playerId == playerId }) else { return nil }
            return RoundDataPoint(
                roundNumber: round.roundNumber,
                score: result.roundScore,
                playerName: playerName,
                playerId: playerId
            )
        }
    }
}

