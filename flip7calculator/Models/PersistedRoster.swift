//
//  PersistedRoster.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import Foundation

/// Represents a persisted player roster that can be saved and loaded
struct PersistedRoster: Codable, Equatable {
    var names: [String]
    
    init(names: [String] = []) {
        self.names = names
    }
    
    /// Loads the persisted roster from UserDefaults
    static func load() -> PersistedRoster? {
        guard let data = UserDefaults.standard.data(forKey: "lastPlayerRoster"),
              let roster = try? JSONDecoder().decode(PersistedRoster.self, from: data) else {
            return nil
        }
        return roster
    }
    
    /// Saves the roster to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "lastPlayerRoster")
        }
    }
    
    /// Clears the persisted roster from UserDefaults
    static func clear() {
        UserDefaults.standard.removeObject(forKey: "lastPlayerRoster")
    }
}



