//
//  Player.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation

/// Represents a player in the game
struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var totalScore: Int
    var currentRound: PlayerRound
    
    init(id: UUID = UUID(), name: String, totalScore: Int = 0, currentRound: PlayerRound = PlayerRound()) {
        self.id = id
        self.name = name
        self.totalScore = totalScore
        self.currentRound = currentRound
    }
    
    /// Banks the current round's points and adds to total score
    mutating func bankRound() {
        let roundPoints = ScoreEngine.calculateRoundScore(round: currentRound)
        totalScore += roundPoints
        currentRound.reset()
    }
    
    /// Clears the current round without banking
    mutating func clearRound() {
        currentRound.reset()
    }
}




