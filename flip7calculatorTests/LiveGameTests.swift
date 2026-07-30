import Foundation
import Testing
@testable import flip7calculator

@MainActor
struct LiveDeckTests {
    @Test func classicFactoryCreatesNinetyFourUniqueCards() throws {
        let players = [Player(name: "Maya"), Player(name: "Leo")]
        let session = try LiveSession.makeClassic(profile: .standard, players: players, seed: 42)

        #expect(session.drawPile.count == 94)
        #expect(session.initialCardCount == 94)
        #expect(session.hasUniqueCardIDs)
        #expect(session.drawPile.filter { $0.content == .number(12) }.count == 12)
        #expect(session.drawPile.filter { $0.content == .action(.hold) }.count == 3)
        #expect(session.drawPile.filter { $0.content == .action(.drawThree) }.count == 3)
        #expect(session.drawPile.filter { $0.content == .action(.shield) }.count == 3)
        #expect(session.drawPile.filter { $0.content == .multiplier }.count == 1)
        for modifier in stride(from: 2, through: 10, by: 2) {
            #expect(session.drawPile.filter { $0.content == .addModifier(modifier) }.count == 1)
        }
    }

    @Test func unsupportedRulesetAndUnknownActionsAreRejected() throws {
        let players = [Player(name: "Maya"), Player(name: "Leo")]
        #expect(throws: LiveGameError.unsupportedRuleset) {
            try LiveSession.makeClassic(profile: .vengeance, players: players, seed: 1)
        }

        var profile = DeckProfile.standard
        profile.actionCardCounts["Mystery"] = 1
        #expect(throws: LiveGameError.unsupportedCard("Mystery")) {
            try LiveSession.makeClassic(profile: profile, players: players, seed: 1)
        }
    }
}

@MainActor
struct LiveGameReducerTests {
    @Test func ordinaryDrawProjectsIntoExistingRoundHand() throws {
        var game = try makeGame(drawOrder: [.number(4)])

        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[0].currentRound.hand.selectedNumbers == [4])
        #expect(game.liveSession?.lastReveal?.card.content == .number(4))
        #expect(game.liveSession?.allCards.count == 1)
        #expect(game.liveSession?.hasUniqueCardIDs == true)
    }

    @Test func duplicateBustsWithoutAddingASecondSemanticNumber() throws {
        var game = try makeGame(drawOrder: [.number(6), .number(6)])
        game.liveSession?.tasks = [.awaitDecision(playerID: game.players[0].id)]

        try LiveGameReducer.apply(.draw, to: &game)
        game.liveSession?.tasks = [.awaitDecision(playerID: game.players[0].id)]
        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[0].currentRound.state == .busted)
        #expect(game.players[0].currentRound.hand.selectedNumbers == [6])
        #expect(game.liveSession?.cards(for: game.players[0].id).count == 2)
    }

    @Test func shieldConsumesItselfAndDuplicateWithoutEndingTurnEarly() throws {
        var game = try makeGame(drawOrder: [.number(5)])
        let playerID = game.players[0].id
        game.players[0].currentRound.hand.selectedNumbers = [5]
        let shield = LiveCardInstance(content: .action(.shield))
        game.liveSession?.tableCards[playerID.uuidString] = [shield]
        game.liveSession?.tasks = [.awaitDecision(playerID: playerID)]

        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[0].currentRound.state == .inRound)
        #expect(game.players[0].currentRound.hand.selectedNumbers == [5])
        #expect(game.liveSession?.cards(for: playerID).isEmpty == true)
        #expect(game.liveSession?.discardPile.count == 2)
    }

    @Test func holdPromptsForTargetAndBanksTheChosenPlayer() throws {
        var game = try makeGame(drawOrder: [.action(.hold)])
        game.liveSession?.tasks = [.awaitDecision(playerID: game.players[0].id)]

        try LiveGameReducer.apply(.draw, to: &game)
        #expect(LiveGameReducer.eligibleTargets(in: game).map(\.id) == game.players.map(\.id))

        try LiveGameReducer.apply(.chooseTarget(game.players[1].id), to: &game)

        #expect(game.players[1].currentRound.state == .frozen)
        #expect(game.players[0].currentRound.state == .inRound)
    }

    @Test func stayedHeldAndBustedPlayersAreNotEligibleActionTargets() throws {
        var game = try makeGame(
            drawOrder: [],
            playerNames: ["Maya", "Leo", "Nia", "Owen"]
        )
        let sourceID = game.players[0].id
        game.players[1].currentRound.state = .banked
        game.players[2].currentRound.state = .frozen
        game.players[3].currentRound.state = .busted
        let prompt = LiveActionPrompt(
            action: .drawThree,
            sourcePlayerID: sourceID,
            cardID: UUID()
        )
        game.liveSession?.tasks = [.chooseTarget(prompt)]

        #expect(LiveGameReducer.eligibleTargets(in: game).map(\.id) == [sourceID])
        #expect(throws: LiveGameError.invalidTarget) {
            try LiveGameReducer.apply(.chooseTarget(game.players[1].id), to: &game)
        }
    }

    @Test func drawThreeRevealsThreeCardsAndThenResumesTurnOrder() throws {
        var game = try makeGame(drawOrder: [
            .action(.drawThree), .number(1), .addModifier(4), .number(2)
        ])
        let sourceID = game.players[0].id
        let targetID = game.players[1].id
        game.liveSession?.tasks = [.awaitDecision(playerID: sourceID)]

        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.chooseTarget(targetID), to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[1].currentRound.hand.selectedNumbers == [1, 2])
        #expect(game.players[1].currentRound.hand.addMods[4] == 1)
        #expect(game.liveSession?.currentTask == .awaitDecision(playerID: targetID))
    }

    @Test func actionDrawnDuringDrawThreeWaitsUntilAllThreeCardsResolve() throws {
        var game = try makeGame(drawOrder: [
            .action(.drawThree), .number(1), .action(.hold), .number(2)
        ])
        let sourceID = game.players[0].id
        let targetID = game.players[1].id
        game.liveSession?.tasks = [.awaitDecision(playerID: sourceID)]

        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.chooseTarget(targetID), to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)

        guard case .forcedDraw(_, let forcedPlayerID, 3, 3)? = game.liveSession?.currentTask else {
            Issue.record("The nested action interrupted the forced sequence")
            return
        }
        #expect(forcedPlayerID == targetID)

        try LiveGameReducer.apply(.draw, to: &game)

        guard case .chooseTarget(let prompt)? = game.liveSession?.currentTask else {
            Issue.record("The deferred Hold action was not presented after the sequence")
            return
        }
        #expect(prompt.action == .hold)
        #expect(prompt.sourcePlayerID == targetID)
    }

    @Test func nestedDrawThreeFinishesTheOriginalSequenceThenCanMoveToAnotherPlayer() throws {
        var game = try makeGame(
            drawOrder: [
                .action(.drawThree),
                .number(1), .action(.drawThree), .number(2),
                .number(3), .number(4), .number(5)
            ],
            playerNames: ["Maya", "Leo", "Nia"]
        )
        let originalSourceID = game.players[0].id
        let originalTargetID = game.players[1].id
        let nestedTargetID = game.players[2].id
        game.liveSession?.tasks = [.awaitDecision(playerID: originalSourceID)]

        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.chooseTarget(originalTargetID), to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)

        guard case .forcedDraw(_, let forcedPlayerID, 3, 3)? = game.liveSession?.currentTask else {
            Issue.record("The nested Draw 3 interrupted the original sequence")
            return
        }
        #expect(forcedPlayerID == originalTargetID)

        try LiveGameReducer.apply(.draw, to: &game)
        #expect(game.players[1].currentRound.hand.selectedNumbers == [1, 2])

        guard case .chooseTarget(let prompt)? = game.liveSession?.currentTask else {
            Issue.record("The nested Draw 3 was not presented after the original sequence")
            return
        }
        #expect(prompt.action == .drawThree)
        #expect(prompt.sourcePlayerID == originalTargetID)

        try LiveGameReducer.apply(.chooseTarget(nestedTargetID), to: &game)
        guard case .forcedDraw(_, let recipientID, 1, 3)? = game.liveSession?.currentTask else {
            Issue.record("The nested Draw 3 did not start for the selected player")
            return
        }
        #expect(recipientID == nestedTargetID)

        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[2].currentRound.hand.selectedNumbers == [3, 4, 5])
        #expect(game.liveSession?.currentTask == .awaitDecision(playerID: originalTargetID))
    }

    @Test func bustDuringDrawThreeCancelsRemainingCardsAndDeferredActions() throws {
        var game = try makeGame(drawOrder: [
            .action(.drawThree), .action(.hold), .number(6), .number(2)
        ])
        let sourceID = game.players[0].id
        let targetID = game.players[1].id
        game.players[1].currentRound.hand.selectedNumbers = [6]
        game.liveSession?.tasks = [.awaitDecision(playerID: sourceID)]

        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.chooseTarget(targetID), to: &game)
        try LiveGameReducer.apply(.draw, to: &game)
        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[1].currentRound.state == .busted)
        #expect(game.liveSession?.forcedSequences.isEmpty == true)
        #expect(game.liveSession?.drawPile.last?.content == .number(2))
        #expect(game.liveSession?.currentTask == .awaitDecision(playerID: sourceID))
    }

    @Test func secondShieldMustTransferToAnotherActivePlayer() throws {
        var game = try makeGame(drawOrder: [.action(.shield)])
        let sourceID = game.players[0].id
        let targetID = game.players[1].id
        game.liveSession?.tableCards[sourceID.uuidString] = [
            LiveCardInstance(content: .action(.shield))
        ]
        game.liveSession?.tasks = [.awaitDecision(playerID: sourceID)]

        try LiveGameReducer.apply(.draw, to: &game)
        #expect(LiveGameReducer.eligibleTargets(in: game).map(\.id) == [targetID])

        try LiveGameReducer.apply(.chooseTarget(targetID), to: &game)

        #expect(game.liveSession?.cards(for: sourceID).filter { $0.content == .action(.shield) }.count == 1)
        #expect(game.liveSession?.cards(for: targetID).filter { $0.content == .action(.shield) }.count == 1)
    }

    @Test func seventhUniqueNumberEndsTheRoundImmediately() throws {
        var game = try makeGame(drawOrder: [.number(7)])
        let playerID = game.players[0].id
        game.players[0].currentRound.hand.selectedNumbers = [0, 1, 2, 3, 4, 5]
        game.liveSession?.tasks = [.awaitDecision(playerID: playerID)]

        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.players[0].currentRound.hand.hasSevenCardBonus)
        #expect(game.players[0].currentRound.state == .banked)
        #expect(
            game.liveSession?.currentTask
                == .roundComplete(LiveRoundEndReason(kind: .sevenCards, playerID: playerID))
        )
    }

    @Test func reshuffleUsesOnlyDiscardAndKeepsTableCardsOut() throws {
        var game = try makeGame(drawOrder: [])
        let playerID = game.players[0].id
        let tableCard = LiveCardInstance(content: .number(3))
        let discardCard = LiveCardInstance(content: .number(8))
        game.liveSession?.tableCards[playerID.uuidString] = [tableCard]
        game.liveSession?.discardPile = [discardCard]
        game.liveSession?.tasks = [.awaitDecision(playerID: playerID)]

        try LiveGameReducer.apply(.draw, to: &game)

        #expect(game.liveSession?.lastReveal?.card.id == discardCard.id)
        #expect(game.liveSession?.cards(for: playerID).contains(where: { $0.id == tableCard.id }) == true)
        #expect(game.liveSession?.shuffleCount == 2)
    }

    @Test func completelyEmptyShoeEndsTheRoundInsteadOfDeadlocking() throws {
        var game = try makeGame(drawOrder: [])
        let playerID = game.players[0].id
        game.liveSession?.tasks = [.awaitDecision(playerID: playerID)]

        try LiveGameReducer.apply(.draw, to: &game)

        #expect(
            game.liveSession?.currentTask
                == .roundComplete(LiveRoundEndReason(kind: .noCardsAvailable, playerID: nil))
        )
        #expect(game.liveSession?.eventLog.last?.message == "No cards available · round ended")
    }

    @Test func undoThenRedrawAcrossReshuffleRevealsTheSameCard() throws {
        let suiteName = "LiveGameReducerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = GameViewModel(defaults: defaults)
        var game = try makeGame(drawOrder: [])
        let playerID = game.players[0].id
        game.liveSession?.discardPile = [
            LiveCardInstance(content: .number(2)),
            LiveCardInstance(content: .number(8)),
            LiveCardInstance(content: .addModifier(4))
        ]
        game.liveSession?.tasks = [.awaitDecision(playerID: playerID)]
        viewModel.game = game

        #expect(viewModel.drawLiveCard())
        let firstReveal = viewModel.game?.liveSession?.lastReveal
        viewModel.undo()
        #expect(viewModel.drawLiveCard())

        #expect(viewModel.game?.liveSession?.lastReveal == firstReveal)
    }

    @Test func nextRoundBanksScoresMovesTableToDiscardAndRotatesDealer() throws {
        var game = try makeGame(drawOrder: [.number(7)])
        let firstDealer = game.players[0].id
        let nextDealer = game.players[1].id
        game.liveSession?.tasks = [.awaitDecision(playerID: firstDealer)]
        try LiveGameReducer.apply(.draw, to: &game)
        game.players[0].currentRound.state = .banked
        game.players[1].currentRound.state = .banked
        game.liveSession?.tasks = [
            .roundComplete(LiveRoundEndReason(kind: .allPlayersDone, playerID: nil))
        ]

        try LiveGameReducer.apply(.startNextRound, to: &game)

        #expect(game.players[0].totalScore == 7)
        #expect(game.currentRoundNumber == 2)
        #expect(game.gameHistory.count == 1)
        #expect(game.liveSession?.dealerPlayerID == nextDealer)
        #expect(game.liveSession?.discardPile.contains(where: { $0.content == .number(7) }) == true)
        #expect(game.liveSession?.currentTask == .openingDraw(playerID: nextDealer))
    }

    private func makeGame(
        drawOrder: [LiveCardContent],
        playerNames: [String] = ["Maya", "Leo"]
    ) throws -> Game {
        let players = playerNames.map { Player(name: $0) }
        var game = Game(
            players: players,
            targetScore: 200,
            deckProfile: .standard,
            scoringRules: .classic,
            playStyle: .digitalDealer
        )
        var session = try LiveSession.makeClassic(profile: .standard, players: players, seed: 5)
        session.drawPile = drawOrder.reversed().map { LiveCardInstance(content: $0) }
        session.discardPile = []
        session.tableCards = Dictionary(uniqueKeysWithValues: players.map { ($0.id.uuidString, []) })
        session.tasks = [.openingDraw(playerID: players[0].id)]
        session.initialCardCount = session.drawPile.count
        session.eventLog = []
        game.liveSession = session
        return game
    }
}

@MainActor
struct ProbabilityServiceTests {
    @Test func riskInsightsMakesTheDefaultExplicit() {
        #expect(RiskInsightsMode.off.displayName == "Off (Default)")
    }

    @Test func calculatorEstimateMatchesHandCalculatedExample() {
        let players = [
            Player(
                name: "Maya",
                currentRound: PlayerRound(hand: RoundHand(selectedNumbers: [2, 5, 9]))
            ),
            Player(name: "Leo")
        ]
        let game = Game(players: players, deckProfile: .standard, scoringRules: .classic)

        let insight = ProbabilityService.calculatorEstimate(for: players[0].id, in: game)

        #expect(insight?.unsafeCardCount == 13)
        #expect(insight?.totalCardCount == 91)
        #expect(insight?.percentage == 14)
        #expect(insight?.confidence == .estimateCurrentTable)
    }

    @Test func exactDealerRiskUsesDrawPileAndShieldProtection() throws {
        let players = [
            Player(
                name: "Maya",
                currentRound: PlayerRound(hand: RoundHand(selectedNumbers: [4]))
            ),
            Player(name: "Leo")
        ]
        var game = Game(
            players: players,
            deckProfile: .standard,
            scoringRules: .classic,
            playStyle: .digitalDealer
        )
        var session = try LiveSession.makeClassic(profile: .standard, players: players, seed: 8)
        session.drawPile = [
            LiveCardInstance(content: .number(4)),
            LiveCardInstance(content: .number(8)),
            LiveCardInstance(content: .action(.hold))
        ]
        game.liveSession = session

        #expect(ProbabilityService.exactDigitalRisk(for: players[0].id, in: game)?.unsafeCardCount == 1)

        let shield = LiveCardInstance(content: .action(.shield))
        game.liveSession?.tableCards[players[0].id.uuidString] = [shield]
        #expect(ProbabilityService.exactDigitalRisk(for: players[0].id, in: game)?.unsafeCardCount == 0)
    }
}

@MainActor
struct LiveGamePersistenceTests {
    @Test func legacyGameDefaultsToScorekeeperWithoutALiveSession() throws {
        let original = Game(players: [Player(name: "Maya"), Player(name: "Leo")])
        let encoded = try JSONEncoder().encode(original)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "playStyle")
        object.removeValue(forKey: "liveSession")

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(Game.self, from: legacyData)

        #expect(decoded.playStyle == .scorekeeper)
        #expect(decoded.liveSession == nil)
    }

    @Test func dealerSessionPersistsAndDrawUndoRedoPreservesTheExactShoe() throws {
        let suiteName = "LiveGamePersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = GameViewModel(defaults: defaults)

        #expect(
            viewModel.startNewGame(
                players: ["Maya", "Leo"],
                targetScore: 200,
                scoringRules: .classic,
                playStyle: .digitalDealer
            )
        )
        let beforeDraw = try #require(viewModel.game?.liveSession)

        #expect(viewModel.drawLiveCard())
        let afterDraw = try #require(viewModel.game?.liveSession)
        #expect(afterDraw.drawPile.count == beforeDraw.drawPile.count - 1)

        viewModel.undo()
        #expect(viewModel.game?.liveSession == beforeDraw)
        viewModel.redo()
        #expect(viewModel.game?.liveSession == afterDraw)

        let reloaded = GameViewModel(defaults: defaults)
        #expect(reloaded.game?.playStyle == .digitalDealer)
        #expect(reloaded.game?.liveSession == afterDraw)
    }

    @Test func pendingActionAndForcedSequenceRoundTripExactly() throws {
        let players = [Player(name: "Maya"), Player(name: "Leo")]
        var game = Game(
            players: players,
            deckProfile: .standard,
            scoringRules: .classic,
            playStyle: .digitalDealer
        )
        var session = try LiveSession.makeClassic(profile: .standard, players: players, seed: 11)
        let actionCard = LiveCardInstance(content: .action(.hold))
        let prompt = LiveActionPrompt(
            action: .hold,
            sourcePlayerID: players[0].id,
            cardID: actionCard.id
        )
        let sequence = LiveForcedSequence(
            id: UUID(),
            recipientPlayerID: players[1].id,
            deferredPrompts: [prompt]
        )
        session.tableCards[players[0].id.uuidString] = [actionCard]
        session.tasks = [
            .chooseTarget(prompt),
            .forcedDraw(sequenceID: sequence.id, playerID: players[1].id, drawNumber: 2, total: 3)
        ]
        session.forcedSequences = [sequence]
        game.liveSession = session

        let data = try JSONEncoder().encode(game)
        let decoded = try JSONDecoder().decode(Game.self, from: data)

        #expect(decoded == game)
    }

    @Test func dealerRejectsVengeanceWithoutCreatingADeadGame() {
        let suiteName = "LiveGamePersistenceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated defaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = GameViewModel(defaults: defaults)

        #expect(
            !viewModel.startNewGame(
                players: ["Maya", "Leo"],
                scoringRules: .vengeance,
                playStyle: .digitalDealer
            )
        )
        #expect(viewModel.game == nil)
        #expect(viewModel.liveErrorMessage != nil)
    }

    @Test func confirmedDealerFallbackCannotUndoBackIntoAnExactShoe() throws {
        let suiteName = "LiveGamePersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let viewModel = GameViewModel(defaults: defaults)
        #expect(
            viewModel.startNewGame(
                players: ["Maya", "Leo"],
                scoringRules: .classic,
                playStyle: .digitalDealer
            )
        )
        #expect(viewModel.drawLiveCard())

        viewModel.continueDealerAsScorekeeper()

        #expect(viewModel.game?.playStyle == .scorekeeper)
        #expect(viewModel.game?.liveSession == nil)
        #expect(!viewModel.canUndo)
        viewModel.undo()
        #expect(viewModel.game?.playStyle == .scorekeeper)
    }
}

@MainActor
struct GameWinnerRuleTests {
    @Test func tiedLeadersAtTargetContinuePlaying() {
        let game = Game(
            players: [
                Player(name: "Maya", totalScore: 210),
                Player(name: "Leo", totalScore: 210),
                Player(name: "Nia", totalScore: 180)
            ],
            targetScore: 200
        )

        #expect(!game.hasWinner)
        #expect(game.winners.map(\.name) == ["Maya", "Leo"])
    }

    @Test func uniqueHighScoreWinsEvenWhenAnotherPlayerAlsoReachedTarget() {
        let game = Game(
            players: [
                Player(name: "Maya", totalScore: 220),
                Player(name: "Leo", totalScore: 205)
            ],
            targetScore: 200
        )

        #expect(game.hasWinner)
        #expect(game.winners.map(\.name) == ["Maya"])
    }
}
