//
//  VengeanceModeTests.swift
//  flip7calculatorTests
//

import Foundation
import Testing
import UIKit
@testable import flip7calculator

struct VengeanceDeckProfileTests {
    @Test func classicDefaultStillContainsNinetyFourCards() {
        let profile = DeckProfile.standard

        #expect(profile.mode == .classic)
        #expect(profile.totalCardCount == 94)
        #expect(profile.numberCardCounts[0] == 1)
        #expect(profile.numberCardCounts[12] == 12)
        #expect(profile.addModifierCounts.values.reduce(0, +) == 5)
        #expect(profile.x2Count == 1)
        #expect(profile.actionCardCounts.values.reduce(0, +) == 9)
        #expect(DeckProfile.ActionCard.classicCards == [.freeze, .flipThree, .secondChance])
        #expect(DeckProfile.ActionCard.classicCards.map(\.displayName) == ["Freeze", "Flip Three", "Second Chance"])
        #expect(profile.isDefaultProfile)
    }

    @Test func vengeanceDefaultMatchesVerifiedOneHundredEightCardDeck() {
        let profile = DeckProfile.vengeance

        #expect(profile.mode == .vengeance)
        #expect(profile.totalCardCount == 108)
        #expect(profile.numberCardCounts.values.reduce(0, +) == 89)
        #expect(profile.numberCardCounts[7] == 6)
        #expect(profile.numberCardCounts[13] == 12)
        #expect(profile.specialNumberCardCounts.values.reduce(0, +) == 3)
        #expect(SpecialNumberCard.allCases.allSatisfy { profile.specialNumberCount($0) == 1 })
        #expect(profile.subtractModifierCounts == [2: 1, 4: 1, 6: 1, 8: 1, 10: 1])
        #expect(profile.divideByTwoCount == 1)
        #expect(profile.actionCardCounts.values.reduce(0, +) == 10)
        #expect(DeckProfile.ActionCard.vengeanceCards.allSatisfy { profile.actionCardCounts[$0.rawValue] == 2 })
        #expect(profile.isDefaultProfile)
    }

    @MainActor @Test func legacyDeckProfileDecodesAsClassic() throws {
        let legacyJSON = """
        {
          "numberCardCounts": {"0": 1, "1": 1},
          "addModifierCounts": {"2": 1},
          "x2Count": 1,
          "actionCardCounts": {"Freeze": 3}
        }
        """

        let profile = try JSONDecoder().decode(
            DeckProfile.self,
            from: Data(legacyJSON.utf8)
        )

        #expect(profile.mode == .classic)
        #expect(profile.subtractModifierCounts.isEmpty)
        #expect(profile.specialNumberCardCounts.isEmpty)
        #expect(profile.divideByTwoCount == 0)
        #expect(profile.actionCardCounts[DeckProfile.ActionCard.freeze.rawValue] == 3)
    }

    @Test func temporaryGenericClassicActionNamesMigrateToOfficialNames() {
        let profile = DeckProfile(
            mode: .classic,
            actionCardCounts: ["Hold": 3, "DrawThree": 3, "Retry": 3]
        )

        #expect(profile.actionCardCounts == ["Freeze": 3, "FlipThree": 3, "SecondChance": 3])
    }

    @Test func freshScoringRulesDefaultToClassic() {
        #expect(GameMode.allCases.first == .classic)
        #expect(ScoringRules().mode == .classic)
        #expect(Game(players: [Player(name: "Alex")]).scoringRules.mode == .classic)
    }

    @Test func vengeanceDefaultsToStandardNonBrutalRules() {
        #expect(!ScoringRules.defaultBrutalMode)
        #expect(!ScoringRules(mode: .vengeance).brutalMode)
        #expect(!ScoringRules.vengeance.brutalMode)
    }

    @Test func modeIconsResolveToSystemSymbols() {
        #expect(UIImage(systemName: GameMode.classic.icon) != nil)
        #expect(UIImage(systemName: GameMode.vengeance.icon) != nil)
    }

    @MainActor @Test func legacyGameDecodesWithClassicRules() throws {
        let original = Game(players: [Player(name: "Alex")])
        let encoded = try JSONEncoder().encode(original)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "scoringRules")

        if var deck = object["deckProfile"] as? [String: Any] {
            deck.removeValue(forKey: "mode")
            deck.removeValue(forKey: "subtractModifierCounts")
            deck.removeValue(forKey: "divideByTwoCount")
            deck.removeValue(forKey: "specialNumberCardCounts")
            object["deckProfile"] = deck
        }

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(Game.self, from: legacyData)

        #expect(decoded.scoringRules == .classic)
        #expect(decoded.deckProfile.mode == .classic)
    }
}

struct VengeanceRoundHandTests {
    @Test func luckyThirteenCoexistsWithARegularThirteen() {
        var hand = RoundHand(selectedNumbers: [13])
        hand.addSpecialNumber(.luckyThirteen)

        #expect(hand.numberCardCount == 2)
        #expect(hand.numberSum == 26)
        #expect(hand.specialNumbers == [.luckyThirteen])
    }

    @Test func specialZeroCountsAsACardButForcesZeroBaseScore() {
        var hand = RoundHand(selectedNumbers: [1, 2, 3])
        hand.addSpecialNumber(.zero)

        #expect(hand.numberCardCount == 4)
        #expect(hand.numberSum == 6)
        #expect(hand.hasZeroEffect)
    }

    @Test func unluckySevenDiscardsAllOtherNumbersAndModifiers() {
        var hand = RoundHand(
            selectedNumbers: [2, 6, 13],
            x2Count: 1,
            addMods: [4: 1],
            subtractMods: [8: 1],
            divideByTwoCount: 1,
            specialNumbers: [.zero, .luckyThirteen]
        )

        hand.addSpecialNumber(.unluckySeven)

        #expect(hand.selectedNumbers.isEmpty)
        #expect(hand.addMods.isEmpty)
        #expect(hand.subtractMods.isEmpty)
        #expect(hand.x2Count == 0)
        #expect(hand.divideByTwoCount == 0)
        #expect(hand.specialNumbers == [.unluckySeven])
        #expect(hand.numberSum == 7)
    }

    @MainActor @Test func oldRoundHandDataGetsEmptyVengeanceFields() throws {
        let legacyJSON = """
        {
          "selectedNumbers": [2, 5],
          "x2Count": 1,
          "addMods": {"4": 1}
        }
        """

        let hand = try JSONDecoder().decode(RoundHand.self, from: Data(legacyJSON.utf8))

        #expect(hand.selectedNumbers == [2, 5])
        #expect(hand.subtractMods.isEmpty)
        #expect(hand.divideByTwoCount == 0)
        #expect(hand.specialNumbers.isEmpty)
    }
}

struct VengeanceScoreEngineTests {
    @Test func scoringOrderIsSumThenDivideThenSubtractThenBonus() {
        var hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7])
        hand.addDivideByTwo()
        hand.addSubtractModifier(4)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .banked,
            rules: .vengeance
        )

        #expect(score == 25) // floor(28 / 2) - 4 + 15
    }

    @Test func divideByTwoRoundsDown() {
        var hand = RoundHand(selectedNumbers: [10, 11, 12])
        hand.addDivideByTwo()
        hand.addSubtractModifier(2)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .banked,
            rules: .vengeance
        )

        #expect(score == 14) // floor(33 / 2) - 2
    }

    @Test func normalModeClampsBeforeAddingSevenCardBonus() {
        var hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7])
        hand.addSubtractModifier(100)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .banked,
            rules: .vengeance
        )

        #expect(score == 15)
    }

    @Test func brutalModeAllowsNegativeScores() {
        var hand = RoundHand(selectedNumbers: [1])
        hand.addSubtractModifier(10)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .banked,
            rules: ScoringRules(mode: .vengeance, brutalMode: true)
        )

        #expect(score == -9)
    }

    @Test func bustedPlayersScoreZeroInNormalMode() {
        var hand = RoundHand(selectedNumbers: [12])
        hand.addSubtractModifier(10)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .busted,
            rules: .vengeance
        )

        #expect(score == 0)
    }

    @Test func brutalModifiersCanMakeBustedPlayersNegative() {
        var hand = RoundHand(selectedNumbers: [12])
        hand.addSubtractModifier(10)

        let score = ScoreEngine.calculateRoundScore(
            hand: hand,
            state: .busted,
            rules: ScoringRules(mode: .vengeance, brutalMode: true)
        )

        #expect(score == -10)
    }

    @Test func zeroScoresOnlyTheSevenCardBonusWhenReached() {
        var shortHand = RoundHand(selectedNumbers: [1, 2, 3])
        shortHand.addSpecialNumber(.zero)

        var sevenCardHand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6])
        sevenCardHand.addSpecialNumber(.zero)

        #expect(ScoreEngine.calculateRoundScore(hand: shortHand, state: .banked, rules: .vengeance) == 0)
        #expect(ScoreEngine.calculateRoundScore(hand: sevenCardHand, state: .banked, rules: .vengeance) == 15)
    }

    @Test func redirectedSevenCardBonusIsRemovedFromSourceAndAppliedToTarget() {
        let targetId = UUID()
        let source = PlayerRound(
            state: .banked,
            hand: RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7]),
            sevenCardBonusTargetId: targetId
        )
        let target = PlayerRound(
            state: .banked,
            hand: RoundHand(selectedNumbers: [10]),
            scoreAdjustment: -ScoreEngine.sevenCardBonus
        )
        let brutal = ScoringRules(mode: .vengeance, brutalMode: true)

        #expect(ScoreEngine.calculateRoundScore(round: source, rules: brutal) == 28)
        #expect(ScoreEngine.calculateRoundScore(round: target, rules: brutal) == -5)
    }

    @Test func manualNegativeScoresRequireBrutalMode() {
        let round = PlayerRound(state: .banked, manualScoreOverride: -20)

        #expect(ScoreEngine.calculateRoundScore(round: round, rules: .vengeance) == 0)
        #expect(
            ScoreEngine.calculateRoundScore(
                round: round,
                rules: ScoringRules(mode: .vengeance, brutalMode: true)
            ) == -20
        )
    }
}

@MainActor
struct VengeanceViewModelTests {
    @Test func unluckySevenMutationSupportsUndoAndRedo() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
        let playerId = game.players[0].id
        game.players[0].currentRound.hand = RoundHand(
            selectedNumbers: [2, 6, 13],
            subtractMods: [8: 1],
            divideByTwoCount: 1
        )
        viewModel.game = game

        viewModel.addSpecialNumberToPlayer(playerId, card: .unluckySeven)
        var hand = try #require(viewModel.game?.players[0].currentRound.hand)
        #expect(hand.specialNumbers == [.unluckySeven])
        #expect(hand.selectedNumbers.isEmpty)
        #expect(hand.subtractMods.isEmpty)
        #expect(hand.divideByTwoCount == 0)

        viewModel.undo()
        hand = try #require(viewModel.game?.players[0].currentRound.hand)
        #expect(hand.selectedNumbers == [2, 6, 13])
        #expect(hand.subtractMods == [8: 1])
        #expect(hand.divideByTwoCount == 1)

        viewModel.redo()
        hand = try #require(viewModel.game?.players[0].currentRound.hand)
        #expect(hand.specialNumbers == [.unluckySeven])
        #expect(hand.numberCardCount == 1)
    }

    @Test func singletonSpecialCardCannotBeAssignedTwice() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        let game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
        let firstId = game.players[0].id
        let secondId = game.players[1].id
        viewModel.game = game

        #expect(viewModel.canAddSpecialNumber(.luckyThirteen, toPlayer: firstId))
        viewModel.addSpecialNumberToPlayer(firstId, card: .luckyThirteen)
        #expect(!viewModel.canAddSpecialNumber(.luckyThirteen, toPlayer: secondId))

        viewModel.addSpecialNumberToPlayer(secondId, card: .luckyThirteen)
        let secondHand = try #require(viewModel.game?.players[1].currentRound.hand)
        #expect(!secondHand.specialNumbers.contains(.luckyThirteen))
    }

    @Test func brutalBonusRedirectPersistsAndSupportsUndoRedo() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: ScoringRules(mode: .vengeance, brutalMode: true)
        )
        let sourceId = game.players[0].id
        let targetId = game.players[1].id
        game.players[0].currentRound.hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7])
        viewModel.game = game

        viewModel.setSevenCardBonusTarget(sourcePlayerId: sourceId, targetPlayerId: targetId)
        var redirectedGame = try #require(viewModel.game)
        #expect(redirectedGame.players[0].currentRound.sevenCardBonusTargetId == targetId)
        #expect(redirectedGame.players[1].currentRound.scoreAdjustment == -15)
        #expect(ScoreEngine.calculateRoundScore(round: redirectedGame.players[0].currentRound, rules: redirectedGame.scoringRules) == 28)
        #expect(ScoreEngine.calculateRoundScore(round: redirectedGame.players[1].currentRound, rules: redirectedGame.scoringRules) == -15)

        viewModel.undo()
        var restoredGame = try #require(viewModel.game)
        #expect(restoredGame.players[0].currentRound.sevenCardBonusTargetId == nil)
        #expect(restoredGame.players[1].currentRound.scoreAdjustment == 0)

        viewModel.redo()
        restoredGame = try #require(viewModel.game)
        #expect(restoredGame.players[0].currentRound.sevenCardBonusTargetId == targetId)
        #expect(restoredGame.players[1].currentRound.scoreAdjustment == -15)

        let reloaded = GameViewModel(defaults: defaults)
        redirectedGame = try #require(reloaded.game)
        #expect(redirectedGame.scoringRules.brutalMode)
        #expect(redirectedGame.players[0].currentRound.sevenCardBonusTargetId == targetId)
        #expect(redirectedGame.players[1].currentRound.scoreAdjustment == -15)
    }

    @Test func switchingModesSharesNumbersAndRestoresModeSpecificEntries() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: ScoringRules(mode: .vengeance, brutalMode: true)
        )
        let playerId = game.players[0].id
        game.players[0].totalScore = 47
        game.players[0].currentRound = PlayerRound(
            state: .frozen,
            hand: RoundHand(
                selectedNumbers: [2, 5, 13],
                subtractMods: [4: 1],
                divideByTwoCount: 1,
                specialNumbers: [.luckyThirteen]
            ),
            manualScoreOverride: -12
        )
        game.gameHistory = [GameRound(roundNumber: 1, results: [], scoringRules: .vengeance)]
        viewModel.game = game

        viewModel.switchGameMode(to: .classic)
        var switchedGame = try #require(viewModel.game)
        var hand = switchedGame.players[0].currentRound.hand
        #expect(switchedGame.scoringRules == .classic)
        #expect(switchedGame.deckProfile.mode == .classic)
        #expect(switchedGame.players[0].totalScore == 47)
        #expect(switchedGame.gameHistory.count == 1)
        #expect(switchedGame.players[0].currentRound.state == .frozen)
        #expect(switchedGame.players[0].currentRound.manualScoreOverride == nil)
        #expect(hand.selectedNumbers == [2, 5])
        #expect(hand.subtractMods.isEmpty)
        #expect(hand.divideByTwoCount == 0)
        #expect(hand.specialNumbers.isEmpty)

        #expect(!viewModel.addCardToPlayer(playerId, number: 0))
        viewModel.addModifierToPlayer(playerId, value: 4)

        viewModel.switchGameMode(to: .vengeance)
        switchedGame = try #require(viewModel.game)
        hand = switchedGame.players[0].currentRound.hand
        #expect(switchedGame.scoringRules == ScoringRules(mode: .vengeance, brutalMode: true))
        #expect(hand.selectedNumbers == [2, 5, 13])
        #expect(hand.subtractMods == [4: 1])
        #expect(hand.divideByTwoCount == 1)
        #expect(hand.specialNumbers == [.luckyThirteen])
        #expect(hand.addMods.isEmpty)
        #expect(switchedGame.players[0].currentRound.manualScoreOverride == -12)

        viewModel.switchGameMode(to: .classic)
        switchedGame = try #require(viewModel.game)
        hand = switchedGame.players[0].currentRound.hand
        #expect(hand.selectedNumbers == [0, 2, 5])
        #expect(hand.addMods == [4: 1])
        #expect(hand.specialNumbers.isEmpty)
    }

    @Test func switchingPreservesExistingSharedCardsWhenDestinationDeckIsOverCapacity() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: (1...8).map { Player(name: "Player \($0)") },
            deckProfile: .standard,
            scoringRules: .classic
        )
        for index in 0..<7 {
            game.players[index].currentRound.hand = RoundHand(selectedNumbers: [7])
        }
        let eighthPlayerId = game.players[7].id
        viewModel.game = game

        viewModel.switchGameMode(to: .vengeance)
        let switchedGame = try #require(viewModel.game)

        #expect(switchedGame.players.prefix(7).allSatisfy { $0.currentRound.hand.selectedNumbers == [7] })
        #expect(!viewModel.canAddNumber(7, toPlayer: eighthPlayerId))
    }

    @Test func restoringUnluckySevenDoesNotMergeClassicNumbersIntoItsClearedHand() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
        let playerId = game.players[0].id
        game.players[0].currentRound.hand = RoundHand(specialNumbers: [.unluckySeven])
        viewModel.game = game

        viewModel.switchGameMode(to: .classic)
        #expect(!viewModel.addCardToPlayer(playerId, number: 4))
        #expect(!viewModel.addCardToPlayer(playerId, number: 9))
        viewModel.switchGameMode(to: .vengeance)

        let restoredHand = try #require(viewModel.game?.players[0].currentRound.hand)
        #expect(restoredHand.specialNumbers == [.unluckySeven])
        #expect(restoredHand.selectedNumbers.isEmpty)
    }

    @Test func modeProgressPersistsAndModeSwitchSupportsUndoRedo() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
        game.players[0].currentRound.hand = RoundHand(
            selectedNumbers: [3, 13],
            subtractMods: [6: 1],
            specialNumbers: [.zero]
        )
        viewModel.game = game
        viewModel.switchGameMode(to: .classic)

        let reloaded = GameViewModel(defaults: defaults)
        #expect(reloaded.game?.scoringRules.mode == .classic)
        #expect(reloaded.game?.modeRoundProgress.map(\.mode) == [.vengeance])

        reloaded.switchGameMode(to: .vengeance)
        var restoredGame = try #require(reloaded.game)
        #expect(restoredGame.players[0].currentRound.hand.selectedNumbers == [3, 13])
        #expect(restoredGame.players[0].currentRound.hand.subtractMods == [6: 1])
        #expect(restoredGame.players[0].currentRound.hand.specialNumbers == [.zero])

        reloaded.undo()
        restoredGame = try #require(reloaded.game)
        #expect(restoredGame.scoringRules.mode == .classic)
        #expect(restoredGame.players[0].currentRound.hand.selectedNumbers == [3])

        reloaded.redo()
        restoredGame = try #require(reloaded.game)
        #expect(restoredGame.scoringRules.mode == .vengeance)
        #expect(restoredGame.players[0].currentRound.hand.specialNumbers == [.zero])
    }

    @Test func startingANewRoundClearsSavedModeProgressAndRecordsRoundRules() throws {
        let (viewModel, defaults, suiteName) = makeViewModel()
        defer { clear(defaults, suiteName: suiteName) }

        var game = Game(
            players: [Player(name: "Alex"), Player(name: "Blair")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
        game.players[0].currentRound.hand = RoundHand(
            selectedNumbers: [2, 13],
            specialNumbers: [.luckyThirteen]
        )
        viewModel.game = game

        viewModel.switchGameMode(to: .classic)
        viewModel.startNewRound()
        var currentGame = try #require(viewModel.game)
        #expect(currentGame.modeRoundProgress.isEmpty)
        #expect(currentGame.gameHistory.first?.scoringRules == .classic)

        viewModel.switchGameMode(to: .vengeance)
        currentGame = try #require(viewModel.game)
        #expect(currentGame.players[0].currentRound.hand.isEmpty)

        viewModel.startNewRound()
        currentGame = try #require(viewModel.game)
        #expect(currentGame.gameHistory.last?.scoringRules == .vengeance)
        #expect(currentGame.modesUsed == [.classic, .vengeance])
    }

    private func makeViewModel() -> (GameViewModel, UserDefaults, String) {
        let suiteName = "VengeanceViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (GameViewModel(defaults: defaults), defaults, suiteName)
    }

    private func clear(_ defaults: UserDefaults, suiteName: String) {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

struct VengeanceStatsTests {
    @MainActor @Test func legacyRoundHistoryWithoutRulesUsesCurrentGameRules() throws {
        let legacyJSON = """
        {
          "roundNumber": 1,
          "results": []
        }
        """
        let round = try JSONDecoder().decode(GameRound.self, from: Data(legacyJSON.utf8))
        let game = Game(
            players: [Player(name: "Alex")],
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )

        #expect(round.scoringRules == nil)
        #expect(game.rules(for: round) == .vengeance)
    }

    @Test func historyCountsVengeanceCardsAndRedirectedBonuses() {
        var game = Game(
            players: [Player(name: "Alex")],
            deckProfile: .vengeance,
            scoringRules: ScoringRules(mode: .vengeance, brutalMode: true)
        )
        let playerId = game.players[0].id
        let targetId = UUID()
        let hand = RoundHand(
            selectedNumbers: [1, 2, 3, 4, 5, 6],
            subtractMods: [4: 1, 8: 1],
            divideByTwoCount: 1,
            specialNumbers: [.zero]
        )
        game.gameHistory = [
            GameRound(
                roundNumber: 1,
                results: [
                    RoundResult(
                        playerId: playerId,
                        playerName: "Alex",
                        roundScore: -12,
                        state: .banked,
                        manualScoreOverride: nil,
                        handSnapshot: hand,
                        autoScore: -12,
                        scoreAdjustment: 0,
                        sevenCardBonusTargetId: targetId
                    )
                ]
            )
        ]

        let gameStats = GameStats(game: game)
        let playerStats = PlayerGameStats(playerId: playerId, game: game)

        #expect(gameStats.totalNegativeModifierPoints == 12)
        #expect(gameStats.totalDivideByTwoUsed == 1)
        #expect(gameStats.totalSpecialNumbersUsed == 1)
        #expect(gameStats.totalRedirectedSevenCardBonuses == 1)
        #expect(playerStats.totalNegativeModifierPoints == 12)
        #expect(playerStats.redirectedSevenCardBonusCount == 1)
        #expect(playerStats.totalSevenCardBonusPoints == 0)
    }

    @Test func bustedSevenCardHandDoesNotCountAsABonus() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Alex",
            roundScore: 0,
            state: .busted,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7]),
            autoScore: 0
        )

        #expect(!result.hasSevenCardBonus)
    }
}
