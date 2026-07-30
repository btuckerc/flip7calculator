//
//  Game.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

struct ModePlayerRoundSnapshot: Codable, Equatable {
    let playerId: UUID
    var round: PlayerRound
}

struct ModeRoundProgress: Codable, Equatable {
    let mode: GameMode
    var playerRounds: [ModePlayerRoundSnapshot]
    var deckProfile: DeckProfile
    var scoringRules: ScoringRules
}

/// Represents a complete score-tracking game session.
struct Game: Codable, Equatable {
    var players: [Player]
    var currentRoundIndex: Int
    var targetScore: Int
    var gameHistory: [GameRound]
    var deckProfile: DeckProfile
    var scoringRules: ScoringRules
    var modeRoundProgress: [ModeRoundProgress]
    
    init(
        players: [Player],
        targetScore: Int = 200,
        deckProfile: DeckProfile = .standard,
        scoringRules: ScoringRules = .classic
    ) {
        self.players = players
        self.currentRoundIndex = 0
        self.targetScore = targetScore
        self.gameHistory = []
        self.deckProfile = deckProfile
        self.scoringRules = scoringRules
        self.modeRoundProgress = []
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
            let roundScore = ScoreEngine.calculateRoundScore(round: player.currentRound, rules: scoringRules)
            let autoScore = ScoreEngine.calculateAutoScore(round: player.currentRound, rules: scoringRules)
            return RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: roundScore,
                state: player.currentRound.state,
                manualScoreOverride: player.currentRound.manualScoreOverride,
                handSnapshot: player.currentRound.hand,
                autoScore: autoScore,
                scoreAdjustment: player.currentRound.scoreAdjustment,
                sevenCardBonusTargetId: player.currentRound.sevenCardBonusTargetId
            )
        }
        gameHistory.append(
            GameRound(
                roundNumber: currentRoundNumber,
                results: roundResults,
                scoringRules: scoringRules
            )
        )
        
        // Bank all players (busted players get 0 via ScoreEngine)
        for index in players.indices {
            players[index].bankRound(rules: scoringRules)
        }

        modeRoundProgress.removeAll()
        currentRoundIndex += 1
    }
    
    /// Ends the current round and banks all players (same as startNewRound but doesn't increment round)
    /// Use this when you want to finalize scores without moving to a new round (e.g., game end)
    mutating func endRound() {
        // Save round to history with full snapshots
        let roundResults = players.map { player -> RoundResult in
            let roundScore = ScoreEngine.calculateRoundScore(round: player.currentRound, rules: scoringRules)
            let autoScore = ScoreEngine.calculateAutoScore(round: player.currentRound, rules: scoringRules)
            return RoundResult(
                playerId: player.id,
                playerName: player.name,
                roundScore: roundScore,
                state: player.currentRound.state,
                manualScoreOverride: player.currentRound.manualScoreOverride,
                handSnapshot: player.currentRound.hand,
                autoScore: autoScore,
                scoreAdjustment: player.currentRound.scoreAdjustment,
                sevenCardBonusTargetId: player.currentRound.sevenCardBonusTargetId
            )
        }
        gameHistory.append(
            GameRound(
                roundNumber: currentRoundNumber,
                results: roundResults,
                scoringRules: scoringRules
            )
        )
        
        // Bank all players
        for index in players.indices {
            players[index].bankRound(rules: scoringRules)
        }
        modeRoundProgress.removeAll()
    }

    func rules(for round: GameRound) -> ScoringRules {
        round.scoringRules ?? scoringRules
    }

    var modesUsed: Set<GameMode> {
        var modes = Set(gameHistory.map { rules(for: $0).mode })
        modes.insert(scoringRules.mode)
        return modes
    }

    private enum CodingKeys: String, CodingKey {
        case players
        case currentRoundIndex
        case targetScore
        case gameHistory
        case deckProfile
        case scoringRules
        case modeRoundProgress
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDeck = try container.decodeIfPresent(DeckProfile.self, forKey: .deckProfile) ?? .standard
        players = try container.decode([Player].self, forKey: .players)
        currentRoundIndex = try container.decodeIfPresent(Int.self, forKey: .currentRoundIndex) ?? 0
        targetScore = try container.decodeIfPresent(Int.self, forKey: .targetScore) ?? 200
        gameHistory = try container.decodeIfPresent([GameRound].self, forKey: .gameHistory) ?? []
        deckProfile = decodedDeck
        scoringRules = try container.decodeIfPresent(ScoringRules.self, forKey: .scoringRules)
            ?? ScoringRules(mode: decodedDeck.mode)
        modeRoundProgress = try container.decodeIfPresent([ModeRoundProgress].self, forKey: .modeRoundProgress) ?? []
    }
}

/// Represents a completed round for history
struct GameRound: Codable, Equatable {
    let roundNumber: Int
    let results: [RoundResult]
    let scoringRules: ScoringRules?

    init(roundNumber: Int, results: [RoundResult], scoringRules: ScoringRules? = nil) {
        self.roundNumber = roundNumber
        self.results = results
        self.scoringRules = scoringRules
    }
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
    let scoreAdjustment: Int?
    let sevenCardBonusTargetId: UUID?
    
    /// Legacy initializer (for backward compatibility and previews)
    init(playerId: UUID, playerName: String, roundScore: Int) {
        self.playerId = playerId
        self.playerName = playerName
        self.roundScore = roundScore
        self.state = nil
        self.manualScoreOverride = nil
        self.handSnapshot = nil
        self.autoScore = nil
        self.scoreAdjustment = nil
        self.sevenCardBonusTargetId = nil
    }
    
    /// Full snapshot initializer
    init(
        playerId: UUID,
        playerName: String,
        roundScore: Int,
        state: PlayerRoundState,
        manualScoreOverride: Int?,
        handSnapshot: RoundHand,
        autoScore: Int,
        scoreAdjustment: Int = 0,
        sevenCardBonusTargetId: UUID? = nil
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.roundScore = roundScore
        self.state = state
        self.manualScoreOverride = manualScoreOverride
        self.handSnapshot = handSnapshot
        self.autoScore = autoScore
        self.scoreAdjustment = scoreAdjustment
        self.sevenCardBonusTargetId = sevenCardBonusTargetId
    }
    
    // MARK: - Convenience accessors (use snapshot if available, fall back to derived)
    
    /// Whether this round was a bust (uses snapshot if available)
    var isBusted: Bool {
        if let state = state {
            return state == .busted
        }
        return roundScore == 0
    }
    
    /// Whether this round earned the seven-card bonus
    var hasSevenCardBonus: Bool {
        !isBusted && (handSnapshot?.hasSevenCardBonus ?? false)
    }
    
    /// Number of x2 multipliers used
    var x2Count: Int {
        handSnapshot?.x2Count ?? 0
    }
    
    /// Total modifier value used
    var modifierTotal: Int {
        handSnapshot?.modifierSum ?? 0
    }

    var subtractModifierTotal: Int {
        handSnapshot?.subtractModifierSum ?? 0
    }

    var divideByTwoCount: Int {
        handSnapshot?.divideByTwoCount ?? 0
    }

    var specialNumberCount: Int {
        handSnapshot?.specialNumbers.count ?? 0
    }

    var redirectedSevenCardBonus: Bool {
        sevenCardBonusTargetId != nil
    }
    
    /// Number of cards in hand
    var cardCount: Int {
        handSnapshot?.numberCardCount ?? 0
    }
}

// MARK: - Codable with backward compatibility
extension RoundResult: Codable {
    enum CodingKeys: String, CodingKey {
        case playerId, playerName, roundScore
        case state, manualScoreOverride, handSnapshot, autoScore
        case scoreAdjustment, sevenCardBonusTargetId
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
        scoreAdjustment = try container.decodeIfPresent(Int.self, forKey: .scoreAdjustment)
        sevenCardBonusTargetId = try container.decodeIfPresent(UUID.self, forKey: .sevenCardBonusTargetId)
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
        try container.encodeIfPresent(scoreAdjustment, forKey: .scoreAdjustment)
        try container.encodeIfPresent(sevenCardBonusTargetId, forKey: .sevenCardBonusTargetId)
    }
}
