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
    
    /// Calculates round score based on hand and state (without manual override)
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
    
    /// Calculates round score from a PlayerRound, respecting manual override
    /// Priority: busted → 0, manualScoreOverride → that value (clamped ≥0), otherwise computed
    static func calculateRoundScore(round: PlayerRound) -> Int {
        // Busted always scores 0, even if manual override is set
        if round.state == .busted {
            return 0
        }
        
        // If manual override is set, use it (clamped to non-negative)
        if let manualScore = round.manualScoreOverride {
            return max(0, manualScore)
        }
        
        // Otherwise compute from hand
        return calculateRoundScore(hand: round.hand, state: round.state)
    }
    
    /// Calculates the "auto" score from cards (ignoring manual override), for display purposes
    static func calculateAutoScore(hand: RoundHand, state: PlayerRoundState) -> Int {
        return calculateRoundScore(hand: hand, state: state)
    }
    
    /// Calculates what the round score would be with a given hand (for preview)
    static func previewRoundScore(hand: RoundHand, state: PlayerRoundState) -> Int {
        return calculateRoundScore(hand: hand, state: state)
    }
    
    /// Calculates total score (current total + round preview), respecting manual override
    static func previewTotalScore(player: Player) -> Int {
        let roundScore = calculateRoundScore(round: player.currentRound)
        return player.totalScore + roundScore
    }
}




