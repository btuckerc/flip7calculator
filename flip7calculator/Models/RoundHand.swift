//
//  RoundHand.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents a player's hand of cards for a round
struct RoundHand: Codable, Equatable {
    /// Set of unique number cards (0-12)
    var selectedNumbers: Set<Int>
    
    /// Count of x2 multiplier cards
    var x2Count: Int
    
    /// Dictionary mapping modifier value to count (e.g., [2: 1, 4: 2] means one +2 and two +4 cards)
    var addMods: [Int: Int]
    
    init(selectedNumbers: Set<Int> = [], x2Count: Int = 0, addMods: [Int: Int] = [:]) {
        self.selectedNumbers = selectedNumbers
        self.x2Count = max(0, x2Count)
        self.addMods = addMods.filter { $0.key > 0 && $0.value > 0 }
    }
    
    /// Adds a number card. Returns true if it's a duplicate (bust condition)
    mutating func addNumber(_ number: Int) -> Bool {
        guard (0...12).contains(number) else { return false }
        let isDuplicate = selectedNumbers.contains(number)
        selectedNumbers.insert(number)
        return isDuplicate
    }
    
    /// Removes a number card
    mutating func removeNumber(_ number: Int) {
        selectedNumbers.remove(number)
    }
    
    /// Adds an additive modifier card (+2, +4, +6, +8, +10)
    mutating func addModifier(_ value: Int) {
        guard value > 0 else { return }
        addMods[value, default: 0] += 1
    }
    
    /// Removes one instance of an additive modifier
    mutating func removeModifier(_ value: Int) {
        guard let count = addMods[value], count > 0 else { return }
        if count == 1 {
            addMods.removeValue(forKey: value)
        } else {
            addMods[value] = count - 1
        }
    }
    
    /// Adds an x2 multiplier card
    mutating func addX2() {
        x2Count += 1
    }
    
    /// Removes one x2 multiplier card
    mutating func removeX2() {
        x2Count = max(0, x2Count - 1)
    }
    
    /// Checks if player has achieved Flip 7 bonus (7 unique number cards)
    var hasFlip7Bonus: Bool {
        selectedNumbers.count >= 7
    }
    
    /// Sum of all number cards
    var numberSum: Int {
        selectedNumbers.reduce(0, +)
    }
    
    /// Sum of all additive modifiers
    var modifierSum: Int {
        addMods.reduce(0) { $0 + ($1.key * $1.value) }
    }
}




