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
    
    init(state: PlayerRoundState = .inRound, hand: RoundHand = RoundHand(), manualScoreOverride: Int? = nil) {
        self.state = state
        self.hand = hand
        self.manualScoreOverride = manualScoreOverride
    }
    
    /// Resets the round to initial state
    mutating func reset() {
        state = .inRound
        hand = RoundHand()
        manualScoreOverride = nil
    }
}




