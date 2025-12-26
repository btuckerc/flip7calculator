//
//  PersistedDeckProfile.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import Foundation

/// Represents a persisted deck profile that can be saved and loaded
struct PersistedDeckProfile {
    var deckProfile: DeckProfile
    
    init(deckProfile: DeckProfile = .standard) {
        self.deckProfile = deckProfile
    }
    
    /// Loads the persisted deck profile from UserDefaults
    /// Returns the standard deck if none is saved
    static func load() -> PersistedDeckProfile {
        guard let data = UserDefaults.standard.data(forKey: "lastDeckProfile"),
              let deckProfile = try? JSONDecoder().decode(DeckProfile.self, from: data) else {
            return PersistedDeckProfile(deckProfile: .standard)
        }
        return PersistedDeckProfile(deckProfile: deckProfile)
    }
    
    /// Saves the deck profile to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(deckProfile) {
            UserDefaults.standard.set(encoded, forKey: "lastDeckProfile")
        }
    }
    
    /// Clears the persisted deck profile from UserDefaults (resets to standard)
    static func clear() {
        UserDefaults.standard.removeObject(forKey: "lastDeckProfile")
    }
    
    /// Resets to the standard deck profile and saves it
    mutating func resetToStandard() {
        deckProfile = .standard
        save()
    }
}




