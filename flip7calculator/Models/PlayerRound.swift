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
    
    init(state: PlayerRoundState = .inRound, hand: RoundHand = RoundHand()) {
        self.state = state
        self.hand = hand
    }
    
    /// Resets the round to initial state
    mutating func reset() {
        state = .inRound
        hand = RoundHand()
    }
}



