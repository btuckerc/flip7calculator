//
//  RoundHand.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents the score-relevant cards in front of one player for a round.
struct RoundHand: Codable, Equatable {
    var selectedNumbers: Set<Int>
    var x2Count: Int
    var addMods: [Int: Int]
    var subtractMods: [Int: Int]
    var divideByTwoCount: Int
    var specialNumbers: Set<SpecialNumberCard>

    init(
        selectedNumbers: Set<Int> = [],
        x2Count: Int = 0,
        addMods: [Int: Int] = [:],
        subtractMods: [Int: Int] = [:],
        divideByTwoCount: Int = 0,
        specialNumbers: Set<SpecialNumberCard> = []
    ) {
        self.selectedNumbers = Set(selectedNumbers.filter { (0...13).contains($0) })
        self.x2Count = max(0, x2Count)
        self.addMods = addMods.filter { $0.key > 0 && $0.value > 0 }
        self.subtractMods = subtractMods.filter { $0.key > 0 && $0.value > 0 }
        self.divideByTwoCount = max(0, divideByTwoCount)
        self.specialNumbers = specialNumbers
    }

    mutating func addNumber(_ number: Int) -> Bool {
        guard (0...13).contains(number) else { return false }
        let isDuplicate = selectedNumbers.contains(number)
            || specialNumbers.contains(where: { $0.numberValue == number && $0 != .luckyThirteen })
        selectedNumbers.insert(number)
        return isDuplicate
    }

    mutating func removeNumber(_ number: Int) {
        selectedNumbers.remove(number)
    }

    /// Adds a special number and applies its immediate, irreversible card effect.
    mutating func addSpecialNumber(_ card: SpecialNumberCard) {
        switch card {
        case .unluckySeven:
            selectedNumbers.removeAll()
            addMods.removeAll()
            subtractMods.removeAll()
            x2Count = 0
            divideByTwoCount = 0
            specialNumbers = [.unluckySeven]
        case .zero, .luckyThirteen:
            specialNumbers.insert(card)
        }
    }

    mutating func removeSpecialNumber(_ card: SpecialNumberCard) {
        specialNumbers.remove(card)
    }

    mutating func addModifier(_ value: Int) {
        guard value > 0 else { return }
        addMods[value, default: 0] += 1
    }

    mutating func removeModifier(_ value: Int) {
        Self.removeOne(value, from: &addMods)
    }

    mutating func addSubtractModifier(_ value: Int) {
        guard value > 0 else { return }
        subtractMods[value, default: 0] += 1
    }

    mutating func removeSubtractModifier(_ value: Int) {
        Self.removeOne(value, from: &subtractMods)
    }

    mutating func addX2() {
        x2Count += 1
    }

    mutating func removeX2() {
        x2Count = max(0, x2Count - 1)
    }

    mutating func addDivideByTwo() {
        divideByTwoCount += 1
    }

    mutating func removeDivideByTwo() {
        divideByTwoCount = max(0, divideByTwoCount - 1)
    }

    var numberCardCount: Int {
        selectedNumbers.count + specialNumbers.count
    }

    var hasSevenCardBonus: Bool {
        numberCardCount >= 7
    }

    var hasZeroEffect: Bool {
        specialNumbers.contains(.zero)
    }

    var numberSum: Int {
        selectedNumbers.reduce(0, +) + specialNumbers.reduce(0) { $0 + $1.numberValue }
    }

    var modifierSum: Int {
        addMods.reduce(0) { $0 + ($1.key * $1.value) }
    }

    var subtractModifierSum: Int {
        subtractMods.reduce(0) { $0 + ($1.key * $1.value) }
    }

    var isEmpty: Bool {
        selectedNumbers.isEmpty
            && specialNumbers.isEmpty
            && addMods.isEmpty
            && subtractMods.isEmpty
            && x2Count == 0
            && divideByTwoCount == 0
    }

    private static func removeOne(_ value: Int, from counts: inout [Int: Int]) {
        guard let count = counts[value], count > 0 else { return }
        if count == 1 {
            counts.removeValue(forKey: value)
        } else {
            counts[value] = count - 1
        }
    }

    private enum CodingKeys: String, CodingKey {
        case selectedNumbers
        case x2Count
        case addMods
        case subtractMods
        case divideByTwoCount
        case specialNumbers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            selectedNumbers: try container.decodeIfPresent(Set<Int>.self, forKey: .selectedNumbers) ?? [],
            x2Count: try container.decodeIfPresent(Int.self, forKey: .x2Count) ?? 0,
            addMods: try container.decodeIfPresent([Int: Int].self, forKey: .addMods) ?? [:],
            subtractMods: try container.decodeIfPresent([Int: Int].self, forKey: .subtractMods) ?? [:],
            divideByTwoCount: try container.decodeIfPresent(Int.self, forKey: .divideByTwoCount) ?? 0,
            specialNumbers: try container.decodeIfPresent(Set<SpecialNumberCard>.self, forKey: .specialNumbers) ?? []
        )
    }
}
