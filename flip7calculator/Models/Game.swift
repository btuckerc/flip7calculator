//
//  Game.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents a complete Flip 7 game
struct Game: Codable, Equatable {
    var players: [Player]
    var currentRoundIndex: Int
    var targetScore: Int
    var gameHistory: [GameRound]
    var deckProfile: DeckProfile
    
    init(players: [Player], targetScore: Int = 200, deckProfile: DeckProfile = .standard) {
        self.players = players
        self.currentRoundIndex = 0
        self.targetScore = targetScore
        self.gameHistory = []
        self.deckProfile = deckProfile
    }
    
    /// Current round number (1-indexed)
    var currentRoundNumber: Int {
        currentRoundIndex + 1
    }
    
    /// Checks if any player has reached the target score
    var hasWinner: Bool {
        players.contains { $0.totalScore >= targetScore }
    }
    
    /// Returns the winner(s) if any
    var winners: [Player] {
        players.filter { $0.totalScore >= targetScore }
    }
    
    /// Finalizes the current round and starts a new one
    /// - All players get their scores banked (busted = 0, others = their accumulated score)
    /// - Players still "in round" are treated as banking their current cards
    mutating func startNewRound() {
        // Save round to history
        let roundResults = players.map { player in
            RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: ScoreEngine.calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
            )
        }
        gameHistory.append(GameRound(roundNumber: currentRoundNumber, results: roundResults))
        
        // Bank all players (busted players get 0 via ScoreEngine)
        for index in players.indices {
            players[index].bankRound()
        }
        
        currentRoundIndex += 1
    }
    
    /// Ends the current round and banks all players (same as startNewRound but doesn't increment round)
    /// Use this when you want to finalize scores without moving to a new round (e.g., game end)
    mutating func endRound() {
        // Save round to history
        let roundResults = players.map { player in
            RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: ScoreEngine.calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
            )
        }
        gameHistory.append(GameRound(roundNumber: currentRoundNumber, results: roundResults))
        
        // Bank all players
        for index in players.indices {
            players[index].bankRound()
        }
    }
}

/// Represents a completed round for history
struct GameRound: Codable, Equatable {
    let roundNumber: Int
    let results: [RoundResult]
}

/// Result for a single player in a round
struct RoundResult: Codable, Equatable {
    let playerId: UUID
    let playerName: String
    let roundScore: Int
}

