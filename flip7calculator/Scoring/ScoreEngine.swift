//
//  ScoreEngine.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Pure scoring engine for Flip 7 game
struct ScoreEngine {
    /// Standard bonus for achieving 7 unique number cards
    static let flip7Bonus = 15
    
    /// Calculates round score based on hand and state
    /// Formula: (NumberSum × 2^x2Count) + AddMods + (Flip7? 15 : 0), unless busted ⇒ 0
    static func calculateRoundScore(hand: RoundHand, state: PlayerRoundState) -> Int {
        // If busted, score is 0
        if state == .busted {
            return 0
        }
        
        // Calculate number sum
        let numberSum = hand.numberSum
        
        // Apply multipliers (x2 doubles the number sum only)
        let multipliedSum = numberSum * Int(pow(2.0, Double(hand.x2Count)))
        
        // Add modifier cards
        let modifierSum = hand.modifierSum
        
        // Add Flip 7 bonus if achieved
        let bonus = hand.hasFlip7Bonus ? flip7Bonus : 0
        
        return multipliedSum + modifierSum + bonus
    }
    
    /// Calculates what the round score would be with a given hand (for preview)
    static func previewRoundScore(hand: RoundHand, state: PlayerRoundState) -> Int {
        return calculateRoundScore(hand: hand, state: state)
    }
    
    /// Calculates total score (current total + round preview)
    static func previewTotalScore(player: Player) -> Int {
        let roundScore = calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
        return player.totalScore + roundScore
    }
}




