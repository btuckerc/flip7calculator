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
        // Save round to history with full snapshots
        let roundResults = players.map { player -> RoundResult in
            let roundScore = ScoreEngine.calculateRoundScore(round: player.currentRound)
            let autoScore = ScoreEngine.calculateAutoScore(hand: player.currentRound.hand, state: player.currentRound.state)
            return RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: roundScore,
                state: player.currentRound.state,
                manualScoreOverride: player.currentRound.manualScoreOverride,
                handSnapshot: player.currentRound.hand,
                autoScore: autoScore
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
        // Save round to history with full snapshots
        let roundResults = players.map { player -> RoundResult in
            let roundScore = ScoreEngine.calculateRoundScore(round: player.currentRound)
            let autoScore = ScoreEngine.calculateAutoScore(hand: player.currentRound.hand, state: player.currentRound.state)
            return RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: roundScore,
                state: player.currentRound.state,
                manualScoreOverride: player.currentRound.manualScoreOverride,
                handSnapshot: player.currentRound.hand,
                autoScore: autoScore
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
struct RoundResult: Equatable {
    let playerId: UUID
    let playerName: String
    let roundScore: Int
    
    // Extended snapshot fields (optional for backward compatibility)
    let state: PlayerRoundState?
    let manualScoreOverride: Int?
    let handSnapshot: RoundHand?
    let autoScore: Int?
    
    /// Legacy initializer (for backward compatibility and previews)
    init(playerId: UUID, playerName: String, roundScore: Int) {
        self.playerId = playerId
        self.playerName = playerName
        self.roundScore = roundScore
        self.state = nil
        self.manualScoreOverride = nil
        self.handSnapshot = nil
        self.autoScore = nil
    }
    
    /// Full snapshot initializer
    init(playerId: UUID, playerName: String, roundScore: Int, state: PlayerRoundState, manualScoreOverride: Int?, handSnapshot: RoundHand, autoScore: Int) {
        self.playerId = playerId
        self.playerName = playerName
        self.roundScore = roundScore
        self.state = state
        self.manualScoreOverride = manualScoreOverride
        self.handSnapshot = handSnapshot
        self.autoScore = autoScore
    }
    
    // MARK: - Convenience accessors (use snapshot if available, fall back to derived)
    
    /// Whether this round was a bust (uses snapshot if available)
    var isBusted: Bool {
        if let state = state {
            return state == .busted
        }
        return roundScore == 0
    }
    
    /// Whether this round achieved Flip7 bonus
    var hasFlip7: Bool {
        handSnapshot?.hasFlip7Bonus ?? false
    }
    
    /// Number of x2 multipliers used
    var x2Count: Int {
        handSnapshot?.x2Count ?? 0
    }
    
    /// Total modifier value used
    var modifierTotal: Int {
        handSnapshot?.modifierSum ?? 0
    }
    
    /// Number of cards in hand
    var cardCount: Int {
        handSnapshot?.selectedNumbers.count ?? 0
    }
}

// MARK: - Codable with backward compatibility
extension RoundResult: Codable {
    enum CodingKeys: String, CodingKey {
        case playerId, playerName, roundScore
        case state, manualScoreOverride, handSnapshot, autoScore
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerId = try container.decode(UUID.self, forKey: .playerId)
        playerName = try container.decode(String.self, forKey: .playerName)
        roundScore = try container.decode(Int.self, forKey: .roundScore)
        
        // Optional fields for backward compatibility
        state = try container.decodeIfPresent(PlayerRoundState.self, forKey: .state)
        manualScoreOverride = try container.decodeIfPresent(Int.self, forKey: .manualScoreOverride)
        handSnapshot = try container.decodeIfPresent(RoundHand.self, forKey: .handSnapshot)
        autoScore = try container.decodeIfPresent(Int.self, forKey: .autoScore)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerId, forKey: .playerId)
        try container.encode(playerName, forKey: .playerName)
        try container.encode(roundScore, forKey: .roundScore)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(manualScoreOverride, forKey: .manualScoreOverride)
        try container.encodeIfPresent(handSnapshot, forKey: .handSnapshot)
        try container.encodeIfPresent(autoScore, forKey: .autoScore)
    }
}

