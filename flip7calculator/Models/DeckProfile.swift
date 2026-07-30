//
//  DeckProfile.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case classic
    case vengeance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .vengeance: return "Vengeance"
        }
    }

    var shortDescription: String {
        switch self {
        case .classic:
            return "Start here. Flip unique numbers and try to reach seven cards before a duplicate makes you bust."
        case .vengeance:
            return "More twists: special numbers, take-that actions, and negative modifiers."
        }
    }

    var expansionRequirement: String? {
        switch self {
        case .classic:
            return nil
        case .vengeance:
            return "NOTE: Requires additional cards. Please be sure to use the 'With a Vengeance' expansion pack for this mode."
        }
    }

    var icon: String {
        switch self {
        case .classic: return "7.circle.fill"
        case .vengeance: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

struct ScoringRules: Codable, Equatable {
    static let defaultBrutalMode = false
    static let brutalModeDescription = "Optional cutthroat variant: negative rounds and redirected 7-card bonuses."

    var mode: GameMode
    var brutalMode: Bool

    init(mode: GameMode = .classic, brutalMode: Bool = ScoringRules.defaultBrutalMode) {
        self.mode = mode
        self.brutalMode = mode == .vengeance && brutalMode
    }

    static let classic = ScoringRules()
    static let vengeance = ScoringRules(mode: .vengeance)
}

enum SpecialNumberCard: String, Codable, CaseIterable, Hashable, Identifiable {
    case zero
    case unluckySeven
    case luckyThirteen

    var id: String { rawValue }

    var numberValue: Int {
        switch self {
        case .zero: return 0
        case .unluckySeven: return 7
        case .luckyThirteen: return 13
        }
    }

    var displayName: String {
        switch self {
        case .zero: return "The Zero"
        case .unluckySeven: return "Unlucky 7"
        case .luckyThirteen: return "Lucky 13"
        }
    }

    var shortLabel: String {
        switch self {
        case .zero: return "0!"
        case .unluckySeven: return "7!"
        case .luckyThirteen: return "13+"
        }
    }

    var effectSummary: String {
        switch self {
        case .zero:
            return "Scores zero unless the 7-card bonus is reached"
        case .unluckySeven:
            return "Discards every other number and modifier"
        case .luckyThirteen:
            return "Allows one regular 13 without a bust"
        }
    }
}

/// Represents the composition and scoring family of a deck.
struct DeckProfile: Codable, Equatable {
    var mode: GameMode
    var numberCardCounts: [Int: Int]
    var addModifierCounts: [Int: Int]
    var x2Count: Int
    var subtractModifierCounts: [Int: Int]
    var divideByTwoCount: Int
    var specialNumberCardCounts: [String: Int]
    var actionCardCounts: [String: Int]

    init(
        mode: GameMode = .classic,
        numberCardCounts: [Int: Int] = [:],
        addModifierCounts: [Int: Int] = [:],
        x2Count: Int = 0,
        subtractModifierCounts: [Int: Int] = [:],
        divideByTwoCount: Int = 0,
        specialNumberCardCounts: [String: Int] = [:],
        actionCardCounts: [String: Int] = [:]
    ) {
        self.mode = mode
        self.numberCardCounts = numberCardCounts.filter { $0.value > 0 }
        self.addModifierCounts = addModifierCounts.filter { $0.value > 0 }
        self.x2Count = max(0, x2Count)
        self.subtractModifierCounts = subtractModifierCounts.filter { $0.value > 0 }
        self.divideByTwoCount = max(0, divideByTwoCount)
        self.specialNumberCardCounts = specialNumberCardCounts.filter { $0.value > 0 }
        self.actionCardCounts = Self.normalizedActionCounts(actionCardCounts)
    }

    static var standard: DeckProfile {
        var numberCounts = [0: 1]
        for number in 1...12 {
            numberCounts[number] = number
        }

        let modifierCounts = Dictionary(uniqueKeysWithValues: [2, 4, 6, 8, 10].map { ($0, 1) })
        let actionCounts = Dictionary(uniqueKeysWithValues: ActionCard.classicCards.map { ($0.rawValue, 3) })

        return DeckProfile(
            mode: .classic,
            numberCardCounts: numberCounts,
            addModifierCounts: modifierCounts,
            x2Count: 1,
            actionCardCounts: actionCounts
        )
    }

    static var vengeance: DeckProfile {
        var numberCounts: [Int: Int] = [:]
        for number in 1...13 {
            numberCounts[number] = number
        }
        // One of the seven 7s and one of the thirteen 13s are special cards.
        numberCounts[7] = 6
        numberCounts[13] = 12

        let negativeModifiers = Dictionary(uniqueKeysWithValues: [2, 4, 6, 8, 10].map { ($0, 1) })
        let specialNumbers = Dictionary(uniqueKeysWithValues: SpecialNumberCard.allCases.map { ($0.rawValue, 1) })
        let actionCounts = Dictionary(uniqueKeysWithValues: ActionCard.vengeanceCards.map { ($0.rawValue, 2) })

        return DeckProfile(
            mode: .vengeance,
            numberCardCounts: numberCounts,
            subtractModifierCounts: negativeModifiers,
            divideByTwoCount: 1,
            specialNumberCardCounts: specialNumbers,
            actionCardCounts: actionCounts
        )
    }

    static func defaultProfile(for mode: GameMode) -> DeckProfile {
        switch mode {
        case .classic: return .standard
        case .vengeance: return .vengeance
        }
    }

    var isDefaultProfile: Bool {
        self == Self.defaultProfile(for: mode)
    }

    var totalCardCount: Int {
        numberCardCounts.values.reduce(0, +)
            + addModifierCounts.values.reduce(0, +)
            + x2Count
            + subtractModifierCounts.values.reduce(0, +)
            + divideByTwoCount
            + specialNumberCardCounts.values.reduce(0, +)
            + actionCardCounts.values.reduce(0, +)
    }

    var isValid: Bool {
        numberCardCounts.keys.allSatisfy { (0...13).contains($0) }
            && numberCardCounts.values.allSatisfy { $0 >= 0 }
            && addModifierCounts.values.allSatisfy { $0 >= 0 }
            && subtractModifierCounts.values.allSatisfy { $0 >= 0 }
            && x2Count >= 0
            && divideByTwoCount >= 0
            && specialNumberCardCounts.values.allSatisfy { $0 >= 0 }
            && actionCardCounts.values.allSatisfy { $0 >= 0 }
    }

    func specialNumberCount(_ card: SpecialNumberCard) -> Int {
        specialNumberCardCounts[card.rawValue] ?? 0
    }

    enum ActionCard: String, CaseIterable {
        case freeze = "Freeze"
        case flipThree = "FlipThree"
        case secondChance = "SecondChance"
        case justOneMore = "JustOneMore"
        case flipFour = "FlipFour"
        case swap = "Swap"
        case steal = "Steal"
        case discard = "Discard"

        static let classicCards: [ActionCard] = [.freeze, .flipThree, .secondChance]
        static let vengeanceCards: [ActionCard] = [.justOneMore, .flipFour, .swap, .steal, .discard]

        var displayName: String {
            switch self {
            case .freeze: return "Freeze"
            case .flipThree: return "Flip Three"
            case .secondChance: return "Second Chance"
            case .justOneMore: return "Just One More"
            case .flipFour: return "Flip Four"
            case .swap: return "Swap"
            case .steal: return "Steal"
            case .discard: return "Discard"
            }
        }

        /// Original, app-native symbols that preserve each card's concept without
        /// reproducing the physical deck's artwork or trade dress.
        var icon: String {
            switch self {
            case .freeze: return "snowflake"
            case .flipThree: return "rectangle.stack.fill"
            case .secondChance: return "heart.circle.fill"
            case .justOneMore: return "plus.rectangle.on.rectangle"
            case .flipFour: return "square.stack.3d.up.fill"
            case .swap: return "arrow.left.arrow.right"
            case .steal: return "hand.raised.fill"
            case .discard: return "trash.fill"
            }
        }

        static func cards(for mode: GameMode) -> [ActionCard] {
            mode == .classic ? classicCards : vengeanceCards
        }

        static func fromStoredKey(_ key: String) -> ActionCard? {
            if let action = ActionCard(rawValue: key) {
                return action
            }

            switch key {
            case "Hold": return .freeze
            case "DrawThree", "Draw 3", "Flip Three": return .flipThree
            case "Retry", "Second Chance": return .secondChance
            default: return nil
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case numberCardCounts
        case addModifierCounts
        case x2Count
        case subtractModifierCounts
        case divideByTwoCount
        case specialNumberCardCounts
        case actionCardCounts
    }

    private static func normalizedActionCounts(_ counts: [String: Int]) -> [String: Int] {
        var normalized: [String: Int] = [:]
        for (key, count) in counts where count > 0 {
            let normalizedKey = ActionCard.fromStoredKey(key)?.rawValue ?? key
            normalized[normalizedKey, default: 0] += count
        }
        return normalized
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedMode = try container.decodeIfPresent(GameMode.self, forKey: .mode) ?? .classic

        self.init(
            mode: decodedMode,
            numberCardCounts: try container.decodeIfPresent([Int: Int].self, forKey: .numberCardCounts) ?? [:],
            addModifierCounts: try container.decodeIfPresent([Int: Int].self, forKey: .addModifierCounts) ?? [:],
            x2Count: try container.decodeIfPresent(Int.self, forKey: .x2Count) ?? 0,
            subtractModifierCounts: try container.decodeIfPresent([Int: Int].self, forKey: .subtractModifierCounts) ?? [:],
            divideByTwoCount: try container.decodeIfPresent(Int.self, forKey: .divideByTwoCount) ?? 0,
            specialNumberCardCounts: try container.decodeIfPresent([String: Int].self, forKey: .specialNumberCardCounts) ?? [:],
            actionCardCounts: try container.decodeIfPresent([String: Int].self, forKey: .actionCardCounts) ?? [:]
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(numberCardCounts, forKey: .numberCardCounts)
        try container.encode(addModifierCounts, forKey: .addModifierCounts)
        try container.encode(x2Count, forKey: .x2Count)
        try container.encode(subtractModifierCounts, forKey: .subtractModifierCounts)
        try container.encode(divideByTwoCount, forKey: .divideByTwoCount)
        try container.encode(specialNumberCardCounts, forKey: .specialNumberCardCounts)
        try container.encode(Self.normalizedActionCounts(actionCardCounts), forKey: .actionCardCounts)
    }
}
