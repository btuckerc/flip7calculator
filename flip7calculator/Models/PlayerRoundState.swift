//
//  PlayerRoundState.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// State of a player's participation in the current round
enum PlayerRoundState: String, Codable, CaseIterable {
    case inRound    // Player is still drawing cards
    case banked     // Player chose to stay/bank their points
    case busted     // Player drew a duplicate number
    case frozen     // Player was forced to bank (e.g., Freeze card)
    
    var displayName: String {
        switch self {
        case .inRound: return "In Round"
        case .banked: return "Banked"
        case .busted: return "Busted"
        case .frozen: return "Frozen"
        }
    }
}




