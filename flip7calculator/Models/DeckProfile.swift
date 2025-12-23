//
//  DeckProfile.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents the composition of a Flip 7 deck
/// This is stored for future use (e.g., suggestions, remaining card tracking)
struct DeckProfile: Codable, Equatable {
    /// Number of each number card (0-12) in the deck
    var numberCardCounts: [Int: Int]
    
    /// Number of each additive modifier card (+2, +4, +6, +8, +10) in the deck
    var addModifierCounts: [Int: Int]
    
    /// Number of x2 multiplier cards in the deck
    var x2Count: Int
    
    /// Number of action cards (Freeze, Flip Three, etc.) - for future use
    var actionCardCounts: [String: Int]
    
    init(
        numberCardCounts: [Int: Int] = [:],
        addModifierCounts: [Int: Int] = [:],
        x2Count: Int = 0,
        actionCardCounts: [String: Int] = [:]
    ) {
        self.numberCardCounts = numberCardCounts
        self.addModifierCounts = addModifierCounts
        self.x2Count = x2Count
        self.actionCardCounts = actionCardCounts
    }
    
    /// Standard Flip 7 deck composition (default)
    /// Based on official Flip 7 rules: 94 cards total
    /// - Number cards: 0 has 1 copy, 1-12 have n copies each (1+2+...+12 = 78, plus 0 = 79)
    /// - Action cards: Freeze, Flip Three, Second Chance (3 copies each = 9)
    /// - Modifiers: +2, +4, +6, +8, +10 (1 copy each = 5)
    /// - x2 multiplier: 1 copy
    /// Total: 79 + 9 + 5 + 1 = 94
    static var standard: DeckProfile {
        var numberCounts: [Int: Int] = [:]
        // 0 has 1 copy
        numberCounts[0] = 1
        // 1-12 have n copies each
        for i in 1...12 {
            numberCounts[i] = i
        }
        
        // Additive modifiers: 1 copy each
        var modifierCounts: [Int: Int] = [:]
        for value in [2, 4, 6, 8, 10] {
            modifierCounts[value] = 1
        }
        
        // Action cards: 3 copies each
        var actionCounts: [String: Int] = [:]
        actionCounts["Freeze"] = 3
        actionCounts["FlipThree"] = 3
        actionCounts["SecondChance"] = 3
        
        return DeckProfile(
            numberCardCounts: numberCounts,
            addModifierCounts: modifierCounts,
            x2Count: 1,
            actionCardCounts: actionCounts
        )
    }
    
    /// Total number of cards in the deck
    var totalCardCount: Int {
        let numberTotal = numberCardCounts.values.reduce(0, +)
        let modifierTotal = addModifierCounts.values.reduce(0, +)
        let actionTotal = actionCardCounts.values.reduce(0, +)
        return numberTotal + modifierTotal + x2Count + actionTotal
    }
    
    /// Validates that all counts are non-negative
    var isValid: Bool {
        return numberCardCounts.values.allSatisfy { $0 >= 0 } &&
               addModifierCounts.values.allSatisfy { $0 >= 0 } &&
               x2Count >= 0 &&
               actionCardCounts.values.allSatisfy { $0 >= 0 }
    }
    
    /// Action card name constants
    enum ActionCard: String {
        case freeze = "Freeze"
        case flipThree = "FlipThree"
        case secondChance = "SecondChance"
    }
}

