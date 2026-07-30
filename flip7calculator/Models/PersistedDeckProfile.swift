//
//  PersistedDeckProfile.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import Foundation

/// Stores a separate custom deck for each supported scoring family.
struct PersistedDeckProfile {
    var deckProfile: DeckProfile

    init(deckProfile: DeckProfile = .standard) {
        self.deckProfile = deckProfile
    }

    static func load(
        for mode: GameMode = .classic,
        defaults: UserDefaults = .standard
    ) -> PersistedDeckProfile {
        let data = defaults.data(forKey: storageKey(for: mode))
            ?? (mode == .classic ? defaults.data(forKey: legacyStorageKey) : nil)

        guard let data,
              var deckProfile = try? JSONDecoder().decode(DeckProfile.self, from: data) else {
            return PersistedDeckProfile(deckProfile: .defaultProfile(for: mode))
        }

        // Pre-ruleset profiles are Classic by definition.
        deckProfile.mode = mode
        return PersistedDeckProfile(deckProfile: deckProfile)
    }

    static func load() -> PersistedDeckProfile {
        load(for: .classic)
    }

    func save(defaults: UserDefaults = .standard) {
        guard let encoded = try? JSONEncoder().encode(deckProfile) else { return }
        defaults.set(encoded, forKey: Self.storageKey(for: deckProfile.mode))
    }

    static func clear(for mode: GameMode = .classic, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey(for: mode))
        if mode == .classic {
            defaults.removeObject(forKey: legacyStorageKey)
        }
    }

    mutating func resetToDefault(defaults: UserDefaults = .standard) {
        deckProfile = .defaultProfile(for: deckProfile.mode)
        save(defaults: defaults)
    }

    mutating func resetToStandard(defaults: UserDefaults = .standard) {
        deckProfile = .standard
        save(defaults: defaults)
    }

    private static let legacyStorageKey = "lastDeckProfile"

    private static func storageKey(for mode: GameMode) -> String {
        "deckProfile.\(mode.rawValue)"
    }
}
