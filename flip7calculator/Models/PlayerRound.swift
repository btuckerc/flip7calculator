//
//  PlayerRound.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents a player's round state and hand
struct PlayerRound: Codable, Equatable {
    var state: PlayerRoundState
    var hand: RoundHand
    /// Optional manual score override; when set, this value is used instead of the computed hand score
    var manualScoreOverride: Int?
    /// Score changes applied outside this hand, such as a Brutal-mode 7-card penalty.
    var scoreAdjustment: Int
    /// The opponent receiving this player's 7-card bonus as a penalty, when applicable.
    var sevenCardBonusTargetId: UUID?
    
    init(
        state: PlayerRoundState = .inRound,
        hand: RoundHand = RoundHand(),
        manualScoreOverride: Int? = nil,
        scoreAdjustment: Int = 0,
        sevenCardBonusTargetId: UUID? = nil
    ) {
        self.state = state
        self.hand = hand
        self.manualScoreOverride = manualScoreOverride
        self.scoreAdjustment = scoreAdjustment
        self.sevenCardBonusTargetId = sevenCardBonusTargetId
    }
    
    /// Resets the round to initial state
    mutating func reset() {
        state = .inRound
        hand = RoundHand()
        manualScoreOverride = nil
        scoreAdjustment = 0
        sevenCardBonusTargetId = nil
    }

    private enum CodingKeys: String, CodingKey {
        case state
        case hand
        case manualScoreOverride
        case scoreAdjustment
        case sevenCardBonusTargetId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            state: try container.decodeIfPresent(PlayerRoundState.self, forKey: .state) ?? .inRound,
            hand: try container.decodeIfPresent(RoundHand.self, forKey: .hand) ?? RoundHand(),
            manualScoreOverride: try container.decodeIfPresent(Int.self, forKey: .manualScoreOverride),
            scoreAdjustment: try container.decodeIfPresent(Int.self, forKey: .scoreAdjustment) ?? 0,
            sevenCardBonusTargetId: try container.decodeIfPresent(UUID.self, forKey: .sevenCardBonusTargetId)
        )
    }
}



