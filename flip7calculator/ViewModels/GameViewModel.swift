//
//  GameViewModel.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation
import SwiftUI

@Observable
class GameViewModel {
    var game: Game? {
        didSet {
            saveGame()
        }
    }
    
    private var undoStack: [Game] = []
    private var redoStack: [Game] = []
    private let maxUndoStackSize = 50
    
    init() {
        loadGame()
    }
    
    // MARK: - Game Management
    
    func startNewGame(players: [String], targetScore: Int = 200) {
        let gamePlayers = players.map { Player(name: $0) }
        // Load persisted deck profile or use standard
        let deckProfile = PersistedDeckProfile.load().deckProfile
        game = Game(players: gamePlayers, targetScore: targetScore, deckProfile: deckProfile)
        undoStack.removeAll()
        redoStack.removeAll()
        saveGame()
    }
    
    func endGame() {
        game = nil
        undoStack.removeAll()
        redoStack.removeAll()
        saveGame()
    }
    
    // MARK: - Round Management
    
    func startNewRound() {
        guard var currentGame = game else { return }
        saveStateForUndo()
        currentGame.startNewRound()
        game = currentGame
    }
    
    func endRound() {
        guard var currentGame = game else { return }
        saveStateForUndo()
        currentGame.endRound()
        game = currentGame
    }
    
    // MARK: - Deck Management
    
    /// Computes how many of each card type have been used across all players in the current round
    private func currentRoundUsedCounts() -> (numbers: [Int: Int], modifiers: [Int: Int], x2: Int) {
        guard let currentGame = game else {
            return ([:], [:], 0)
        }
        
        var numberCounts: [Int: Int] = [:]
        var modifierCounts: [Int: Int] = [:]
        var x2Count = 0
        
        for player in currentGame.players {
            // Count number cards (each unique number counts as 1 card used)
            for number in player.currentRound.hand.selectedNumbers {
                numberCounts[number, default: 0] += 1
            }
            
            // Count modifiers
            for (value, count) in player.currentRound.hand.addMods {
                modifierCounts[value, default: 0] += count
            }
            
            // Count x2
            x2Count += player.currentRound.hand.x2Count
        }
        
        return (numberCounts, modifierCounts, x2Count)
    }
    
    /// Computes remaining counts for each card type in the current round
    private func currentRoundRemainingCounts() -> (numbers: [Int: Int], modifiers: [Int: Int], x2: Int) {
        guard let currentGame = game else {
            return ([:], [:], 0)
        }
        
        let used = currentRoundUsedCounts()
        let profile = currentGame.deckProfile
        
        // Calculate remaining number cards
        var remainingNumbers: [Int: Int] = [:]
        for (number, deckCount) in profile.numberCardCounts {
            let usedCount = used.numbers[number] ?? 0
            remainingNumbers[number] = max(0, deckCount - usedCount)
        }
        
        // Calculate remaining modifiers
        var remainingModifiers: [Int: Int] = [:]
        for (value, deckCount) in profile.addModifierCounts {
            let usedCount = used.modifiers[value] ?? 0
            remainingModifiers[value] = max(0, deckCount - usedCount)
        }
        
        // Calculate remaining x2
        let remainingX2 = max(0, profile.x2Count - used.x2)
        
        return (remainingNumbers, remainingModifiers, remainingX2)
    }
    
    /// Checks if a number card can be added (either not already selected by this player, or if already selected, there are remaining copies)
    func canAddNumber(_ number: Int, toPlayer playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }) else {
            return false
        }
        
        // If player already has this number, they can't add another (duplicate = bust)
        if player.currentRound.hand.selectedNumbers.contains(number) {
            return false
        }
        
        // Check if there are remaining copies in the deck
        let remaining = currentRoundRemainingCounts()
        return (remaining.numbers[number] ?? 0) > 0
    }
    
    /// Checks if a modifier card can be added
    func canAddModifier(_ value: Int) -> Bool {
        let remaining = currentRoundRemainingCounts()
        return (remaining.modifiers[value] ?? 0) > 0
    }
    
    /// Checks if an x2 card can be added
    func canAddX2() -> Bool {
        let remaining = currentRoundRemainingCounts()
        return remaining.x2 > 0
    }
    
    // MARK: - Player Actions
    
    func addCardToPlayer(_ playerId: UUID, number: Int) -> Bool {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return false
        }
        
        // Check if we can add this card (enforce deck limits)
        if !canAddNumber(number, toPlayer: playerId) {
            return false
        }
        
        saveStateForUndo()
        
        let isDuplicate = currentGame.players[playerIndex].currentRound.hand.addNumber(number)
        
        if isDuplicate {
            currentGame.players[playerIndex].currentRound.state = .busted
        }
        
        game = currentGame
        return isDuplicate
    }
    
    func removeCardFromPlayer(_ playerId: UUID, number: Int) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeNumber(number)
        
        // If player was busted and we remove the duplicate, reset to inRound
        if currentGame.players[playerIndex].currentRound.state == .busted {
            currentGame.players[playerIndex].currentRound.state = .inRound
        }
        
        game = currentGame
    }
    
    func addModifierToPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        // Check if we can add this modifier (enforce deck limits)
        if !canAddModifier(value) {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addModifier(value)
        game = currentGame
    }
    
    func removeModifierFromPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeModifier(value)
        game = currentGame
    }
    
    func addX2ToPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        // Check if we can add x2 (enforce deck limits)
        if !canAddX2() {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addX2()
        game = currentGame
    }
    
    func removeX2FromPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeX2()
        game = currentGame
    }
    
    func setPlayerState(_ playerId: UUID, state: PlayerRoundState) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.state = state
        game = currentGame
    }
    
    func bankPlayer(_ playerId: UUID) {
        setPlayerState(playerId, state: .banked)
    }
    
    func bustPlayer(_ playerId: UUID) {
        setPlayerState(playerId, state: .busted)
    }
    
    func freezePlayer(_ playerId: UUID) {
        setPlayerState(playerId, state: .frozen)
    }
    
    func clearPlayerRound(_ playerId: UUID) {
        guard var currentGame = game,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].clearRound()
        game = currentGame
    }
    
    // MARK: - Deck Profile Management
    
    /// Updates the deck profile for the active game
    func updateDeckProfile(_ newProfile: DeckProfile) {
        guard var currentGame = game else { return }
        saveStateForUndo()
        currentGame.deckProfile = newProfile
        game = currentGame
    }
    
    // MARK: - Target Score Management
    
    func updateTargetScore(_ newScore: Int) {
        guard var currentGame = game else { return }
        saveStateForUndo()
        currentGame.targetScore = max(50, min(5000, newScore))
        game = currentGame
    }
    
    // MARK: - Player Management
    
    /// Reorders players in the active game based on the provided order of player IDs
    func reorderPlayers(playerIds: [UUID]) {
        guard var currentGame = game else { return }
        saveStateForUndo()
        
        // Create a dictionary mapping player IDs to players
        var playerMap: [UUID: Player] = [:]
        for player in currentGame.players {
            playerMap[player.id] = player
        }
        
        // Reorder players based on the provided order
        var reorderedPlayers: [Player] = []
        for id in playerIds {
            if let player = playerMap[id] {
                reorderedPlayers.append(player)
            }
        }
        
        // Add any players not in the new order (shouldn't happen, but safety check)
        for player in currentGame.players {
            if !playerIds.contains(player.id) {
                reorderedPlayers.append(player)
            }
        }
        
        currentGame.players = reorderedPlayers
        game = currentGame
    }
    
    /// Updates player names in the active game based on the provided mapping
    func updatePlayerNames(nameMap: [UUID: String]) {
        guard var currentGame = game else { return }
        saveStateForUndo()
        
        for index in currentGame.players.indices {
            if let newName = nameMap[currentGame.players[index].id] {
                currentGame.players[index].name = newName
            }
        }
        
        game = currentGame
    }
    
    /// Updates players in the active game: reorders, updates names, adds new players, removes players
    func updatePlayers(playerRows: [PlayerNameRow]) {
        guard var currentGame = game else { return }
        saveStateForUndo()
        
        // Create maps for lookup
        var existingPlayerMap: [UUID: Player] = [:]
        for player in currentGame.players {
            existingPlayerMap[player.id] = player
        }
        
        // Build new players array in the order specified by playerRows
        var newPlayers: [Player] = []
        var nameMap: [UUID: String] = [:]
        
        for row in playerRows {
            let trimmedName = row.name.trimmingCharacters(in: .whitespaces)
            let finalName = trimmedName.isEmpty ? "Player \(newPlayers.count + 1)" : trimmedName
            
            if let existingPlayer = existingPlayerMap[row.id] {
                // Existing player - update name and add to new array
                var updatedPlayer = existingPlayer
                updatedPlayer.name = finalName
                newPlayers.append(updatedPlayer)
            } else {
                // New player - create new Player
                let newPlayer = Player(name: finalName)
                newPlayers.append(newPlayer)
            }
            nameMap[row.id] = finalName
        }
        
        currentGame.players = newPlayers
        game = currentGame
    }
    
    // MARK: - Undo/Redo
    
    func undo() {
        guard !undoStack.isEmpty, let currentGame = game else { return }
        // Save current state to redo stack
        redoStack.append(currentGame)
        if redoStack.count > maxUndoStackSize {
            redoStack.removeFirst()
        }
        // Restore previous state
        game = undoStack.removeLast()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        // Save current state to undo stack
        if let currentGame = game {
            undoStack.append(currentGame)
            if undoStack.count > maxUndoStackSize {
                undoStack.removeFirst()
            }
        }
        // Restore next state
        game = redoStack.removeLast()
    }
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    private func saveStateForUndo() {
        guard let currentGame = game else { return }
        undoStack.append(currentGame)
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
        // Clear redo stack when new action is taken
        redoStack.removeAll()
    }
    
    // MARK: - Persistence
    
    private func saveGame() {
        guard let game = game else {
            UserDefaults.standard.removeObject(forKey: "currentGame")
            return
        }
        
        if let encoded = try? JSONEncoder().encode(game) {
            UserDefaults.standard.set(encoded, forKey: "currentGame")
        }
    }
    
    private func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: "currentGame"),
              let decoded = try? JSONDecoder().decode(Game.self, from: data) else {
            return
        }
        game = decoded
    }
}

