//
//  GameViewModel.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import Foundation
import SwiftUI

/// Precomputed per-round remaining deck capacities so keypad rendering and
/// mutation guards stay O(1) instead of rescanning every player's hand per chip.
struct RoundDeckAvailability: Equatable {
    var numbers: [Int: Int] = [:]
    var addModifiers: [Int: Int] = [:]
    var subtractModifiers: [Int: Int] = [:]
    var specialNumbers: [SpecialNumberCard: Int] = [:]
    var x2: Int = 0
    var divideByTwo: Int = 0

    static let empty = RoundDeckAvailability()

    static func compute(for game: Game?) -> RoundDeckAvailability {
        guard let game else { return .empty }

        var usedNumbers: [Int: Int] = [:]
        var usedAddMods: [Int: Int] = [:]
        var usedSubtractMods: [Int: Int] = [:]
        var usedSpecials: [SpecialNumberCard: Int] = [:]
        var usedX2 = 0
        var usedDiv2 = 0

        for player in game.players {
            let hand = player.currentRound.hand
            for number in hand.selectedNumbers {
                usedNumbers[number, default: 0] += 1
            }
            for (value, count) in hand.addMods {
                usedAddMods[value, default: 0] += count
            }
            for (value, count) in hand.subtractMods {
                usedSubtractMods[value, default: 0] += count
            }
            for special in hand.specialNumbers {
                usedSpecials[special, default: 0] += 1
            }
            usedX2 += hand.x2Count
            usedDiv2 += hand.divideByTwoCount
        }

        let profile = game.deckProfile
        var remaining = RoundDeckAvailability()
        remaining.numbers.reserveCapacity(profile.numberCardCounts.count)
        remaining.addModifiers.reserveCapacity(profile.addModifierCounts.count)
        remaining.subtractModifiers.reserveCapacity(profile.subtractModifierCounts.count)
        remaining.specialNumbers.reserveCapacity(SpecialNumberCard.allCases.count)

        for (number, deckCount) in profile.numberCardCounts {
            remaining.numbers[number] = max(0, deckCount - (usedNumbers[number] ?? 0))
        }
        for (value, deckCount) in profile.addModifierCounts {
            remaining.addModifiers[value] = max(0, deckCount - (usedAddMods[value] ?? 0))
        }
        for (value, deckCount) in profile.subtractModifierCounts {
            remaining.subtractModifiers[value] = max(0, deckCount - (usedSubtractMods[value] ?? 0))
        }
        for special in SpecialNumberCard.allCases {
            let deckCount = profile.specialNumberCount(special)
            remaining.specialNumbers[special] = max(0, deckCount - (usedSpecials[special] ?? 0))
        }
        remaining.x2 = max(0, profile.x2Count - usedX2)
        remaining.divideByTwo = max(0, profile.divideByTwoCount - usedDiv2)
        return remaining
    }

    func remainingNumberCount(_ number: Int) -> Int {
        numbers[number] ?? 0
    }

    func canAddNumber(_ number: Int, to hand: RoundHand) -> Bool {
        !hand.selectedNumbers.contains(number) && (numbers[number] ?? 0) > 0
    }

    func canAddSpecialNumber(_ card: SpecialNumberCard, to hand: RoundHand) -> Bool {
        !hand.specialNumbers.contains(card) && (specialNumbers[card] ?? 0) > 0
    }

    func canAddModifier(_ value: Int) -> Bool {
        (addModifiers[value] ?? 0) > 0
    }

    func canAddSubtractModifier(_ value: Int) -> Bool {
        (subtractModifiers[value] ?? 0) > 0
    }
}

@Observable
class GameViewModel {
    private static let persistenceKey = "currentGame"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    var game: Game? {
        didSet {
            roundAvailability = RoundDeckAvailability.compute(for: game)
            if !isLoading {
                saveGameIfNeeded()
            }
        }
    }

    private(set) var roundAvailability: RoundDeckAvailability = .empty

    private var undoStack: [Game] = []
    private var redoStack: [Game] = []
    @ObservationIgnored private let maxUndoStackSize = 50
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var isLoading = false
    @ObservationIgnored private var lastPersistedGame: Game?

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

        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        game = newGame
        return true
    }

    func endGame() {
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        game = nil
    }

    /// Restarts the game with the same players, target score, and deck profile.
    func restartGameKeepingSettings() {
        guard let currentGame = game else { return }

        let playerNames = currentGame.players.map(\.name)
        let targetScore = currentGame.targetScore
        let deckProfile = currentGame.deckProfile
        let scoringRules = currentGame.scoringRules
        let playStyle = currentGame.playStyle

        let freshPlayers = playerNames.map { Player(name: $0) }

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
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        game = restartedGame
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
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              !currentGame.isCurrentRoundFinalized else { return }
        saveStateForUndo()
        currentGame.endRound()
        game = currentGame
    }

    // MARK: - Deck Availability (O(1) via cached snapshot)

    private func availableNumberCards(in profile: DeckProfile) -> Set<Int> {
        Set(profile.numberCardCounts.compactMap { number, count in count > 0 ? number : nil })
    }

    func canAddNumber(_ number: Int, toPlayer playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }) else {
            return false
        }
        return roundAvailability.canAddNumber(number, to: player.currentRound.hand)
    }

    func canAddModifier(_ value: Int) -> Bool {
        roundAvailability.canAddModifier(value)
    }

    func canAddX2() -> Bool {
        roundAvailability.x2 > 0
    }

    func canAddSubtractModifier(_ value: Int) -> Bool {
        roundAvailability.canAddSubtractModifier(value)
    }

    func canAddDivideByTwo() -> Bool {
        roundAvailability.divideByTwo > 0
    }

    func canAddSpecialNumber(_ card: SpecialNumberCard, toPlayer playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }) else {
            return false
        }
        return roundAvailability.canAddSpecialNumber(card, to: player.currentRound.hand)
    }

    // MARK: - Player Actions

    func addCardToPlayer(_ playerId: UUID, number: Int) -> Bool {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return false
        }

        guard roundAvailability.canAddNumber(number, to: currentGame.players[playerIndex].currentRound.hand) else {
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
        game = currentGame
    }

    func addSpecialNumberToPlayer(_ playerId: UUID, card: SpecialNumberCard) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              roundAvailability.canAddSpecialNumber(card, to: currentGame.players[playerIndex].currentRound.hand) else {
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
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              canAddModifier(value) else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addModifier(value)
        game = currentGame
    }

    func removeModifierFromPlayer(_ playerId: UUID, value: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              (currentGame.players[playerIndex].currentRound.hand.addMods[value] ?? 0) > 0 else {
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
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              (currentGame.players[playerIndex].currentRound.hand.subtractMods[value] ?? 0) > 0 else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeSubtractModifier(value)
        game = currentGame
    }

    func addX2ToPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              canAddX2() else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.addX2()
        game = currentGame
    }

    func removeX2FromPlayer(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              currentGame.players[playerIndex].currentRound.hand.x2Count > 0 else {
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
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              currentGame.players[playerIndex].currentRound.hand.divideByTwoCount > 0 else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand.removeDivideByTwo()
        game = currentGame
    }

    func setPlayerState(_ playerId: UUID, state: PlayerRoundState) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              currentGame.players[playerIndex].currentRound.state != state else {
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

    /// Clears the player's current round hand and manual override, preserving state.
    func clearPlayerRoundEntry(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }

        let hand = currentGame.players[playerIndex].currentRound.hand
        let hasOverride = currentGame.players[playerIndex].currentRound.manualScoreOverride != nil

        guard !hand.isEmpty || hasOverride else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.hand = RoundHand()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = nil
        reconcileBrutalBonusRedirects(in: &currentGame)
        game = currentGame
    }

    // MARK: - Manual Score Override

    func setManualScoreOverride(_ playerId: UUID, score: Int) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }) else {
            return
        }

        let clampedScore = currentGame.scoringRules.brutalMode ? score : max(0, score)
        guard currentGame.players[playerIndex].currentRound.manualScoreOverride != clampedScore else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = clampedScore
        game = currentGame
    }

    func clearManualScoreOverride(_ playerId: UUID) {
        guard var currentGame = game,
              currentGame.playStyle == .scorekeeper,
              let playerIndex = currentGame.players.firstIndex(where: { $0.id == playerId }),
              currentGame.players[playerIndex].currentRound.manualScoreOverride != nil else {
            return
        }

        saveStateForUndo()
        currentGame.players[playerIndex].currentRound.manualScoreOverride = nil
        game = currentGame
    }

    func hasManualScoreOverride(_ playerId: UUID) -> Bool {
        guard let currentGame = game,
              let player = currentGame.players.first(where: { $0.id == playerId }) else {
            return false
        }
        return player.currentRound.manualScoreOverride != nil
    }

    // MARK: - Deck Profile Management

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
        let clamped = max(50, min(5000, newScore))
        guard currentGame.targetScore != clamped else { return }
        saveStateForUndo()
        currentGame.targetScore = clamped
        game = currentGame
    }

    // MARK: - Player Management

    func reorderPlayers(playerIds: [UUID]) {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()

        let playerMap = Dictionary(uniqueKeysWithValues: currentGame.players.map { ($0.id, $0) })
        var reorderedPlayers: [Player] = []
        reorderedPlayers.reserveCapacity(currentGame.players.count)

        let idSet = Set(playerIds)
        for id in playerIds {
            if let player = playerMap[id] {
                reorderedPlayers.append(player)
            }
        }
        for player in currentGame.players where !idSet.contains(player.id) {
            reorderedPlayers.append(player)
        }

        currentGame.players = reorderedPlayers
        game = currentGame
    }

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

    func updatePlayers(playerRows: [PlayerNameRow]) {
        guard var currentGame = game, currentGame.playStyle == .scorekeeper else { return }
        saveStateForUndo()

        let existingPlayerMap = Dictionary(uniqueKeysWithValues: currentGame.players.map { ($0.id, $0) })
        var newPlayers: [Player] = []
        newPlayers.reserveCapacity(playerRows.count)

        for row in playerRows {
            let trimmedName = row.name.trimmingCharacters(in: .whitespaces)
            let finalName = trimmedName.isEmpty ? "Player \(newPlayers.count + 1)" : trimmedName

            if var existingPlayer = existingPlayerMap[row.id] {
                existingPlayer.name = finalName
                newPlayers.append(existingPlayer)
            } else {
                newPlayers.append(Player(name: finalName))
            }
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
    func acknowledgeLiveReveal() -> Bool {
        applyLiveCommand(.acknowledgeReveal)
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
        guard let currentGame = game, !currentGame.isCurrentRoundFinalized else { return false }
        return applyLiveCommand(.finishGame)
    }

    var liveEligibleTargets: [Player] {
        guard let game else { return [] }
        return LiveGameReducer.eligibleTargets(in: game)
    }

    func continueDealerAsScorekeeper() {
        guard var currentGame = game, currentGame.playStyle == .digitalDealer else { return }
        currentGame.playStyle = .scorekeeper
        currentGame.liveSession = nil
        undoStack.removeAll()
        redoStack.removeAll()
        liveErrorMessage = nil
        game = currentGame
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
            liveErrorMessage = nil
            game = updatedGame
            return true
        } catch {
            liveErrorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Undo/Redo

    func undo() {
        guard !undoStack.isEmpty, let currentGame = game else { return }
        redoStack.append(currentGame)
        if redoStack.count > maxUndoStackSize {
            redoStack.removeFirst()
        }
        game = undoStack.removeLast()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        if let currentGame = game {
            undoStack.append(currentGame)
            if undoStack.count > maxUndoStackSize {
                undoStack.removeFirst()
            }
        }
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
        redoStack.removeAll()
    }

    // MARK: - Persistence

    private func saveGameIfNeeded() {
        if game == lastPersistedGame {
            return
        }
        lastPersistedGame = game

        guard let game else {
            defaults.removeObject(forKey: Self.persistenceKey)
            return
        }

        if let encoded = try? Self.encoder.encode(game) {
            defaults.set(encoded, forKey: Self.persistenceKey)
        }
    }

    private func loadGame() {
        guard let data = defaults.data(forKey: Self.persistenceKey),
              let decoded = try? Self.decoder.decode(Game.self, from: data) else {
            return
        }
        isLoading = true
        lastPersistedGame = decoded
        game = decoded
        isLoading = false
    }
}
