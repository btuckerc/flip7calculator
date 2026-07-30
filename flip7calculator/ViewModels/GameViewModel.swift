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
    private let defaults: UserDefaults
    var liveErrorMessage: String?
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadGame()
    }
    
    // MARK: - Game Management
    
    @discardableResult
    func startNewGame(
        players: [String],
        targetScore: Int = 200,
        scoringRules: ScoringRules = .classic,
        playStyle: PlayStyle = .scorekeeper
    ) -> Bool {
        let gamePlayers = players.map { Player(name: $0) }
        let deckProfile = PersistedDeckProfile.load(for: scoringRules.mode, defaults: defaults).deckProfile
        var newGame = Game(
            players: gamePlayers,
            targetScore: targetScore,
            deckProfile: deckProfile,
            scoringRules: scoringRules,
            playStyle: playStyle
        )

        if playStyle == .digitalDealer {
            do {
                newGame.liveSession = try LiveSession.makeClassic(
                    profile: deckProfile,
                    players: gamePlayers
                )
            } catch {
                liveErrorMessage = error.localizedDescription
                return false
            }
        }

        game = newGame
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        saveGame()
        return true
    }
    
    func endGame() {
        game = nil
        undoStack.removeAll()
        redoStack.removeAll()
        saveGame()
    }
    
    /// Restarts the game with the same players, target score, and deck profile
    func restartGameKeepingSettings() {
        guard let currentGame = game else { return }
        
        // Preserve current settings
        let playerNames = currentGame.players.map { $0.name }
        let targetScore = currentGame.targetScore
        let deckProfile = currentGame.deckProfile
        let scoringRules = currentGame.scoringRules
        let playStyle = currentGame.playStyle
        
        // Create fresh players with the same names
        let freshPlayers = playerNames.map { Player(name: $0) }
        
        // Start new game with preserved settings
        var restartedGame = Game(
            players: freshPlayers,
            targetScore: targetScore,
            deckProfile: deckProfile,
            scoringRules: scoringRules,
            playStyle: playStyle
        )
        if playStyle == .digitalDealer {
            do {
                restartedGame.liveSession = try LiveSession.makeClassic(
                    profile: deckProfile,
                    players: freshPlayers
                )
            } catch {
                liveErrorMessage = error.localizedDescription
                return
            }
        }
        game = restartedGame
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        saveGame()
    }

    func switchGameMode(
        to newMode: GameMode,
        brutalMode: Bool = ScoringRules.defaultBrutalMode
    ) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              currentGame.scoringRules.mode != newMode else {
            return
        }

        saveStateForUndo()

        let sourceMode = currentGame.scoringRules.mode
        let sourceProfile = currentGame.deckProfile
        let sourceProgress = ModeRoundProgress(
            mode: sourceMode,
            playerRounds: currentGame.players.map {
                ModePlayerRoundSnapshot(playerId: $0.id, round: $0.currentRound)
            },
            deckProfile: sourceProfile,
            scoringRules: currentGame.scoringRules
        )

        if let sourceIndex = currentGame.modeRoundProgress.firstIndex(where: { $0.mode == sourceMode }) {
            currentGame.modeRoundProgress[sourceIndex] = sourceProgress
        } else {
            currentGame.modeRoundProgress.append(sourceProgress)
        }

        let destinationProgress = currentGame.modeRoundProgress.first(where: { $0.mode == newMode })
        var destinationProfile = destinationProgress?.deckProfile
            ?? PersistedDeckProfile.load(for: newMode, defaults: defaults).deckProfile
        destinationProfile.mode = newMode

        let storedRounds = Dictionary(
            uniqueKeysWithValues: (destinationProgress?.playerRounds ?? []).map { ($0.playerId, $0.round) }
        )
        let sourceNumbers = availableNumberCards(in: sourceProfile)
        let destinationNumbers = availableNumberCards(in: destinationProfile)

        for playerIndex in currentGame.players.indices {
            let playerId = currentGame.players[playerIndex].id
            let sourceRound = currentGame.players[playerIndex].currentRound
            var destinationRound = storedRounds[playerId] ?? PlayerRound()

            let sharedNumbers = sourceRound.hand.selectedNumbers.filter {
                sourceNumbers.contains($0) && destinationNumbers.contains($0)
            }
            let restoredDestinationOnlyNumbers = destinationRound.hand.selectedNumbers.filter {
                destinationNumbers.contains($0) && !sourceNumbers.contains($0)
            }

            if newMode == .vengeance,
               destinationRound.hand.specialNumbers.contains(.unluckySeven) {
                destinationRound.hand.selectedNumbers.removeAll()
            } else {
                destinationRound.hand.selectedNumbers = Set(sharedNumbers).union(restoredDestinationOnlyNumbers)
            }
            destinationRound.state = sourceRound.state

            switch newMode {
            case .classic:
                destinationRound.hand.subtractMods.removeAll()
                destinationRound.hand.divideByTwoCount = 0
                destinationRound.hand.specialNumbers.removeAll()
                destinationRound.scoreAdjustment = 0
                destinationRound.sevenCardBonusTargetId = nil
            case .vengeance:
                destinationRound.hand.addMods.removeAll()
                destinationRound.hand.x2Count = 0
            }

            currentGame.players[playerIndex].currentRound = destinationRound
        }

        let destinationBrutalMode = destinationProgress?.scoringRules.brutalMode ?? brutalMode
        currentGame.deckProfile = destinationProfile
        currentGame.scoringRules = ScoringRules(mode: newMode, brutalMode: destinationBrutalMode)
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }

    func setBrutalMode(_ enabled: Bool) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              currentGame.scoringRules.mode == .vengeance,
              currentGame.scoringRules.brutalMode != enabled else {
            return
        }

        saveStateForUndo()
        currentGame.scoringRules = ScoringRules(mode: .vengeance, brutalMode: enabled)
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }
    
    // MARK: - Round Management
    
    func startNewRound() {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()
        currentGame.startNewRound()
        game = currentGame
    }
    
    func endRound() {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()
        currentGame.endRound()
        game = currentGame
    }
    
    // MARK: - Deck Management
    
    private struct RoundCardCounts {
        var numbers: [Int: Int] = [:]
        var addModifiers: [Int: Int] = [:]
        var subtractModifiers: [Int: Int] = [:]
        var specialNumbers: [SpecialNumberCard: Int] = [:]
        var x2 = 0
        var divideByTwo = 0
    }

    private func availableNumberCards(in profile: DeckProfile) -> Set<Int> {
        Set(profile.numberCardCounts.compactMap { number, count in count > 0 ? number : nil })
    }

    /// Computes score-relevant cards still in front of players this round.
    private func currentRoundUsedCounts() -> RoundCardCounts {
        guard let currentGame = game else {
            return RoundCardCounts()
        }
        
        var counts = RoundCardCounts()
        
        for player in currentGame.players {
            for number in player.currentRound.hand.selectedNumbers {
                counts.numbers[number, default: 0] += 1
            }

            for (value, count) in player.currentRound.hand.addMods {
                counts.addModifiers[value, default: 0] += count
            }

            for (value, count) in player.currentRound.hand.subtractMods {
                counts.subtractModifiers[value, default: 0] += count
            }

            for specialNumber in player.currentRound.hand.specialNumbers {
                counts.specialNumbers[specialNumber, default: 0] += 1
            }

            counts.x2 += player.currentRound.hand.x2Count
            counts.divideByTwo += player.currentRound.hand.divideByTwoCount
        }
        
        return counts
    }
    
    private func currentRoundRemainingCounts() -> RoundCardCounts {
        guard let currentGame = game else {
            return RoundCardCounts()
        }
        
        let used = currentRoundUsedCounts()
        let profile = currentGame.deckProfile
        var remaining = RoundCardCounts()
        
        for (number, deckCount) in profile.numberCardCounts {
            remaining.numbers[number] = max(0, deckCount - (used.numbers[number] ?? 0))
        }

        for (value, deckCount) in profile.addModifierCounts {
            remaining.addModifiers[value] = max(0, deckCount - (used.addModifiers[value] ?? 0))
        }

        for (value, deckCount) in profile.subtractModifierCounts {
            remaining.subtractModifiers[value] = max(0, deckCount - (used.subtractModifiers[value] ?? 0))
        }

        for specialNumber in SpecialNumberCard.allCases {
            let deckCount = profile.specialNumberCount(specialNumber)
            remaining.specialNumbers[specialNumber] = max(
                0,
                deckCount - (used.specialNumbers[specialNumber] ?? 0)
            )
        }

        remaining.x2 = max(0, profile.x2Count - used.x2)
        remaining.divideByTwo = max(0, profile.divideByTwoCount - used.divideByTwo)
        return remaining
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
        return (remaining.addModifiers[value] ?? 0) > 0
    }
    
    /// Checks if an x2 card can be added
    func canAddX2() -> Bool {
        let remaining = currentRoundRemainingCounts()
        return remaining.x2 > 0
    }

    func canAddSubtractModifier(_ value: Int) -> Bool {
        (currentRoundRemainingCounts().subtractModifiers[value] ?? 0) > 0
    }

    func canAddDivideByTwo() -> Bool {
        currentRoundRemainingCounts().divideByTwo > 0
    }

    func canAddSpecialNumber(_ card: SpecialNumberCard, toPlayer playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }),
              !player.currentRound.hand.specialNumbers.contains(card) else {
            return false
        }
        return (currentRoundRemainingCounts().specialNumbers[card] ?? 0) > 0
    }
    
    // MARK: - Player Actions
    
    func addCardToPlayer(_ playerId: UUID, number: Int) -> Bool {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
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
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeNumber(number)
        reconcileBrutalBonusRedirects(in: &currentGame)
        // Note: Busted state is sticky - removing cards does not auto-reset to inRound.
        // User must explicitly un-bust to continue editing.
        
        game = currentGame
    }

    func addSpecialNumberToPlayer(_ playerId: UUID, card: SpecialNumberCard) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              canAddSpecialNumber(card, toPlayer: playerId) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addSpecialNumber(card)
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }

    func removeSpecialNumberFromPlayer(_ playerId: UUID, card: SpecialNumberCard) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              currentGame.players[playerIndex].currentRound.hand.specialNumbers.contains(card) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeSpecialNumber(card)
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }
    
    func addModifierToPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
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
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeModifier(value)
        game = currentGame
    }

    func addSubtractModifierToPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              canAddSubtractModifier(value) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addSubtractModifier(value)
        game = currentGame
    }

    func removeSubtractModifierFromPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeSubtractModifier(value)
        game = currentGame
    }
    
    func addX2ToPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
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
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeX2()
        game = currentGame
    }

    func addDivideByTwoToPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              canAddDivideByTwo() else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addDivideByTwo()
        game = currentGame
    }

    func removeDivideByTwoFromPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeDivideByTwo()
        game = currentGame
    }
    
    func setPlayerState(_ playerId: UUID, state: PlayerRoundState) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
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
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        clearBrutalBonusRedirect(forPlayerAt: playerIndex, in: &currentGame)
        currentGame.players[playerIndex].clearRound()
        game = currentGame
    }
    
    /// Clears the player's current round hand and manual override, but preserves state
    /// This is used by the "Clear" button in the calculator
    func clearPlayerRoundEntry(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        let hand = currentGame.players[playerIndex].currentRound.hand
        let hasOverride = currentGame.players[playerIndex].currentRound.manualScoreOverride != nil
        
        // Only save undo state if there's something to clear
        guard !hand.isEmpty || hasOverride else {
            return
        }
        
        saveStateForUndo()
        
        // Clear hand (numbers, modifiers, x2) but preserve state
        currentGame.players[playerIndex].currentRound.hand = RoundHand()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = nil
        reconcileBrutalBonusRedirects(in: &currentGame)
        
        game = currentGame
    }
    
    // MARK: - Manual Score Override
    
    /// Sets a manual score override for the player's current round
    func setManualScoreOverride(_ playerId: UUID, score: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = currentGame.scoringRules.brutalMode
            ? score
            : max(0, score)
        game = currentGame
    }
    
    /// Clears the manual score override for the player's current round
    func clearManualScoreOverride(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }
        
        // Only save undo state if there's actually an override to clear
        guard currentGame.players[playerIndex].currentRound.manualScoreOverride != nil else {
            return
        }
        
        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = nil
        game = currentGame
    }
    
    /// Checks if a player has a manual score override set
    func hasManualScoreOverride(_ playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }) else {
            return false
        }
        return player.currentRound.manualScoreOverride != nil
    }
    
    // MARK: - Deck Profile Management
    
    /// Updates the deck profile for the active game
    func updateDeckProfile(_ newProfile: DeckProfile) {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()
        currentGame.deckProfile = newProfile
        game = currentGame
    }

    func setSevenCardBonusTarget(sourcePlayerId: UUID, targetPlayerId: UUID?) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              currentGame.scoringRules.brutalMode,
              let sourceIndex = currentGame.players.firstIndex(where: { $0.id == sourcePlayerId }),
              currentGame.players[sourceIndex].currentRound.hand.hasSevenCardBonus,
              targetPlayerId != sourcePlayerId else {
            return
        }

        if let targetPlayerId,
           !currentGame.players.contains(where: { $0.id == targetPlayerId }) {
            return
        }

        let currentTarget = currentGame.players[sourceIndex].currentRound.sevenCardBonusTargetId
        guard currentTarget != targetPlayerId else { return }

        saveStateForUndo()
        clearBrutalBonusRedirect(forPlayerAt: sourceIndex, in: &currentGame)

        if let targetPlayerId,
           let targetIndex = currentGame.players.firstIndex(where: { $0.id == targetPlayerId }) {
            currentGame.players[sourceIndex].currentRound.sevenCardBonusTargetId = targetPlayerId
            currentGame.players[targetIndex].currentRound.scoreAdjustment -= ScoreEngine.sevenCardBonus
        }

        game = currentGame
    }
    
    // MARK: - Target Score Management
    
    func updateTargetScore(_ newScore: Int) {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()
        currentGame.targetScore = max(50, min(5000, newScore))
        game = currentGame
    }
    
    // MARK: - Player Management
    
    /// Reorders players in the active game based on the provided order of player IDs
    func reorderPlayers(playerIds: [UUID]) {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
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
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
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
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
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
        let validPlayerIds = Set(newPlayers.map(\.id))
        for progressIndex in currentGame.modeRoundProgress.indices {
            currentGame.modeRoundProgress[progressIndex].playerRounds.removeAll {
                !validPlayerIds.contains($0.playerId)
            }
        }
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }

    private func clearBrutalBonusRedirect(forPlayerAt sourceIndex: Int, in game: inout Game) {
        guard game.players.indices.contains(sourceIndex) else { return }
        game.players[sourceIndex].currentRound.sevenCardBonusTargetId = nil
        rebuildBrutalBonusAdjustments(in: &game)
    }

    private func reconcileBrutalBonusRedirects(in game: inout Game) {
        let validPlayerIds = Set(game.players.map(\.id))
        for index in game.players.indices {
            let round = game.players[index].currentRound
            if !game.scoringRules.brutalMode
                || !round.hand.hasSevenCardBonus
                || round.sevenCardBonusTargetId.map({ !validPlayerIds.contains($0) }) == true {
                game.players[index].currentRound.sevenCardBonusTargetId = nil
            }
        }
        rebuildBrutalBonusAdjustments(in: &game)
    }

    private func rebuildBrutalBonusAdjustments(in game: inout Game) {
        for index in game.players.indices {
            game.players[index].currentRound.scoreAdjustment = 0
        }

        guard game.scoringRules.brutalMode else { return }
        let targetIds = game.players.compactMap { $0.currentRound.sevenCardBonusTargetId }
        for targetId in targetIds {
            if let targetIndex = game.players.firstIndex(where: { $0.id == targetId }) {
                game.players[targetIndex].currentRound.scoreAdjustment -= ScoreEngine.sevenCardBonus
            }
        }
    }

    // MARK: - Live Dealer

    @discardableResult
    func drawLiveCard() -> Bool {
        applyLiveCommand(.draw)
    }

    @discardableResult
    func stayLivePlayer() -> Bool {
        applyLiveCommand(.stay)
    }

    @discardableResult
    func chooseLiveTarget(_ playerID: UUID) -> Bool {
        applyLiveCommand(.chooseTarget(playerID))
    }

    @discardableResult
    func startNextLiveRound() -> Bool {
        applyLiveCommand(.startNextRound)
    }

    @discardableResult
    func finishLiveGameRound() -> Bool {
        applyLiveCommand(.finishGame)
    }

    var liveEligibleTargets: [Player] {
        guard let game else { return [] }
        return LiveGameReducer.eligibleTargets(in: game)
    }

    func continueDealerAsScorekeeper() {
        guard var currentGame = game, currentGame.playStyle == .digitalDealer else { return }
        currentGame.playStyle = .scorekeeper
        currentGame.liveSession = nil
        game = currentGame
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
    }

    @discardableResult
    private func applyLiveCommand(_ command: LiveCommand) -> Bool {
        guard var updatedGame = game, updatedGame.playStyle == .digitalDealer else {
            liveErrorMessage = LiveGameError.noLiveSession.localizedDescription
            return false
        }

        do {
            try LiveGameReducer.apply(command, to: &updatedGame)
            saveStateForUndo()
            game = updatedGame
            liveErrorMessage = nil
            return true
        } catch {
            liveErrorMessage = error.localizedDescription
            return false
        }
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
            defaults.removeObject(forKey: "currentGame")
            return
        }
        
        if let encoded = try? JSONEncoder().encode(game) {
            defaults.set(encoded, forKey: "currentGame")
        }
    }
    
    private func loadGame() {
        guard let data = defaults.data(forKey: "currentGame"),
              let decoded = try? JSONDecoder().decode(Game.self, from: data) else {
            return
        }
        game = decoded
    }
}
