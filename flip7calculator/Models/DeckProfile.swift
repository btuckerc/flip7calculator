//
//  DeckProfile.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents the composition of a score-profile deck.
/// This is stored for future use (e.g., suggestions, remaining card tracking).
struct DeckProfile: Codable, Equatable {
    /// Number of each number card (0-12) in the deck
    var numberCardCounts: [Int: Int]
    
    /// Number of each additive modifier card (+2, +4, +6, +8, +10) in the deck
    var addModifierCounts: [Int: Int]
    
    /// Number of x2 multiplier cards in the deck
    var x2Count: Int
    
    /// Number of action cards - for future use
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
        self.actionCardCounts = Self.normalizedActionCounts(actionCardCounts)
    }
    
    /// Default score-profile deck composition
    /// - Number cards: 0 has 1 copy, 1-12 have n copies each (1+2+...+12 = 78, plus 0 = 79)
    /// - Action cards: Hold, Draw 3, Retry (3 copies each = 9)
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
        actionCounts[ActionCard.hold.rawValue] = 3
        actionCounts[ActionCard.drawThree.rawValue] = 3
        actionCounts[ActionCard.retry.rawValue] = 3
        
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
    enum ActionCard: String, CaseIterable {
        case hold = "Hold"
        case drawThree = "DrawThree"
        case retry = "Retry"
        
        var displayName: String {
            switch self {
            case .hold:
                return "Hold"
            case .drawThree:
                return "Draw 3"
            case .retry:
                return "Retry"
            }
        }
        
        static func fromStoredKey(_ key: String) -> ActionCard? {
            if let action = ActionCard(rawValue: key) {
                return action
            }
            
            switch key {
            case "Freeze":
                return .hold
            case "FlipThree":
                return .drawThree
            case "SecondChance":
                return .retry
            default:
                return nil
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case numberCardCounts
        case addModifierCounts
        case x2Count
        case actionCardCounts
    }
    
    private static func normalizedActionCounts(_ counts: [String: Int]) -> [String: Int] {
        var normalized: [String: Int] = [:]
        
        for (key, count) in counts where count > 0 {
            if let action = ActionCard.fromStoredKey(key) {
                normalized[action.rawValue, default: 0] += count
            } else {
                normalized[key, default: 0] += count
            }
        }
        
        return normalized
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let numberCardCounts = try container.decodeIfPresent([Int: Int].self, forKey: .numberCardCounts) ?? [:]
        let addModifierCounts = try container.decodeIfPresent([Int: Int].self, forKey: .addModifierCounts) ?? [:]
        let x2Count = try container.decodeIfPresent(Int.self, forKey: .x2Count) ?? 0
        let actionCardCounts = try container.decodeIfPresent([String: Int].self, forKey: .actionCardCounts) ?? [:]
        
        self.init(
            numberCardCounts: numberCardCounts,
            addModifierCounts: addModifierCounts,
            x2Count: x2Count,
            actionCardCounts: actionCardCounts
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(numberCardCounts, forKey: .numberCardCounts)
        try container.encode(addModifierCounts, forKey: .addModifierCounts)
        try container.encode(x2Count, forKey: .x2Count)
        try container.encode(Self.normalizedActionCounts(actionCardCounts), forKey: .actionCardCounts)
    }
}
