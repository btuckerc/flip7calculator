//
//  ScoreEngine.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

struct ScoreEngine {
    static let sevenCardBonus = 15

    static func calculateRoundScore(
        hand: RoundHand,
        state: PlayerRoundState,
        rules: ScoringRules = .classic,
        includeSevenCardBonus: Bool = true,
        scoreAdjustment: Int = 0
    ) -> Int {
        switch rules.mode {
        case .classic:
            guard state != .busted else { return 0 }
            let multipliedSum = hand.numberSum * powerOfTwo(hand.x2Count)
            let bonus = includeSevenCardBonus && hand.hasSevenCardBonus ? sevenCardBonus : 0
            return max(0, multipliedSum + hand.modifierSum + bonus + scoreAdjustment)

        case .vengeance:
            return calculateVengeanceScore(
                hand: hand,
                state: state,
                rules: rules,
                includeSevenCardBonus: includeSevenCardBonus,
                scoreAdjustment: scoreAdjustment
            )
        }
    }

    static func calculateRoundScore(round: PlayerRound, rules: ScoringRules = .classic) -> Int {
        if round.state == .busted && !rules.brutalMode {
            return 0
        }

        if let manualScore = round.manualScoreOverride {
            return rules.brutalMode ? manualScore : max(0, manualScore)
        }

        return calculateRoundScore(
            hand: round.hand,
            state: round.state,
            rules: rules,
            includeSevenCardBonus: round.sevenCardBonusTargetId == nil,
            scoreAdjustment: round.scoreAdjustment
        )
    }

    static func calculateAutoScore(
        hand: RoundHand,
        state: PlayerRoundState,
        rules: ScoringRules = .classic
    ) -> Int {
        calculateRoundScore(hand: hand, state: state, rules: rules)
    }

    static func calculateAutoScore(round: PlayerRound, rules: ScoringRules = .classic) -> Int {
        calculateRoundScore(
            hand: round.hand,
            state: round.state,
            rules: rules,
            includeSevenCardBonus: round.sevenCardBonusTargetId == nil,
            scoreAdjustment: round.scoreAdjustment
        )
    }

    static func previewRoundScore(
        hand: RoundHand,
        state: PlayerRoundState,
        rules: ScoringRules = .classic
    ) -> Int {
        calculateRoundScore(hand: hand, state: state, rules: rules)
    }

    static func previewTotalScore(player: Player, rules: ScoringRules = .classic) -> Int {
        player.totalScore + calculateRoundScore(round: player.currentRound, rules: rules)
    }

    private static func calculateVengeanceScore(
        hand: RoundHand,
        state: PlayerRoundState,
        rules: ScoringRules,
        includeSevenCardBonus: Bool,
        scoreAdjustment: Int
    ) -> Int {
        if state == .busted && !rules.brutalMode {
            return 0
        }

        var score = state == .busted || hand.hasZeroEffect ? 0 : hand.numberSum
        for _ in 0..<hand.divideByTwoCount {
            score /= 2
        }
        score -= hand.subtractModifierSum

        if !rules.brutalMode {
            score = max(0, score)
        }

        if includeSevenCardBonus && hand.hasSevenCardBonus && state != .busted {
            score += sevenCardBonus
        }

        score += scoreAdjustment
        return rules.brutalMode ? score : max(0, score)
    }

    private static func powerOfTwo(_ exponent: Int) -> Int {
        guard exponent > 0 else { return 1 }
        return 1 << min(exponent, 30)
    }
}
