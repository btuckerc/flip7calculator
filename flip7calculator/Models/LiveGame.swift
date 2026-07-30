//
//  LiveGame.swift
//  flip7calculator
//
//  Deterministic Classic dealer state and reducer.
//

import Foundation

enum GameEntryIntent: String, CaseIterable, Identifiable {
    case scoreCalculator
    case playWithDealer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scoreCalculator: return AppBrand.scoreCalculatorTitle
        case .playWithDealer: return AppBrand.dealerTitle
        }
    }

    var detail: String {
        switch self {
        case .scoreCalculator:
            return AppBrand.scoreCalculatorDescription
        case .playWithDealer:
            return AppBrand.dealerDescription
        }
    }

    var icon: String {
        switch self {
        case .scoreCalculator: return "plus.forwardslash.minus"
        case .playWithDealer: return "rectangle.stack.fill"
        }
    }

    var playStyle: PlayStyle {
        switch self {
        case .scoreCalculator: return .scorekeeper
        case .playWithDealer: return .digitalDealer
        }
    }
}

enum PlayStyle: String, Codable, Equatable {
    case scorekeeper
    case physicalDeckTracker
    case digitalDealer
}

enum DealerAvailability {
    static var isPreviewEnabled: Bool {
#if DEBUG
        true
#else
        false
#endif
    }
}

enum LiveAction: String, Codable, CaseIterable, Hashable {
    case hold
    case drawThree
    case shield

    var displayName: String {
        switch self {
        case .hold: return "Hold"
        case .drawThree: return "Draw 3"
        case .shield: return "Shield"
        }
    }

    var icon: String {
        switch self {
        case .hold: return "pause.fill"
        case .drawThree: return "square.stack.3d.up.fill"
        case .shield: return "shield.fill"
        }
    }

    init?(profileAction: DeckProfile.ActionCard) {
        switch profileAction {
        case .freeze: self = .hold
        case .flipThree: self = .drawThree
        case .secondChance: self = .shield
        default: return nil
        }
    }
}

enum LiveCardContent: Codable, Equatable, Hashable {
    case number(Int)
    case addModifier(Int)
    case multiplier
    case action(LiveAction)

    var shortLabel: String {
        switch self {
        case .number(let value): return "\(value)"
        case .addModifier(let value): return "+\(value)"
        case .multiplier: return "×2"
        case .action(let action): return action.displayName
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .number(let value): return "Number \(value)"
        case .addModifier(let value): return "Plus \(value) modifier"
        case .multiplier: return "Times two multiplier"
        case .action(let action): return "\(action.displayName) action"
        }
    }

    var isNumber: Bool {
        if case .number = self { return true }
        return false
    }
}

struct LiveCardInstance: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let content: LiveCardContent

    init(id: UUID = UUID(), content: LiveCardContent) {
        self.id = id
        self.content = content
    }
}

struct LiveActionPrompt: Codable, Equatable {
    let action: LiveAction
    let sourcePlayerID: UUID
    let cardID: UUID
}

struct LiveForcedSequence: Codable, Equatable {
    let id: UUID
    let recipientPlayerID: UUID
    var deferredPrompts: [LiveActionPrompt]
}

enum LiveRoundEndKind: String, Codable, Equatable {
    case allPlayersDone
    case sevenCards
    case noCardsAvailable
}

struct LiveRoundEndReason: Codable, Equatable {
    let kind: LiveRoundEndKind
    let playerID: UUID?
}

enum LiveTask: Codable, Equatable {
    case openingDraw(playerID: UUID)
    case awaitDecision(playerID: UUID)
    case forcedDraw(sequenceID: UUID, playerID: UUID, drawNumber: Int, total: Int)
    case completeForced(sequenceID: UUID, playerID: UUID)
    case chooseTarget(LiveActionPrompt)
    case beginTurns(startPlayerID: UUID)
    case advanceTurn(afterPlayerID: UUID)
    case roundComplete(LiveRoundEndReason)
}

enum LiveEventKind: String, Codable, Equatable {
    case shuffled
    case revealed
    case protected
    case busted
    case stayed
    case held
    case action
    case round
}

struct LiveEvent: Identifiable, Codable, Equatable {
    let id: Int
    let kind: LiveEventKind
    let message: String
    let playerID: UUID?
    let cardID: UUID?
}

struct LiveReveal: Codable, Equatable {
    let card: LiveCardInstance
    let playerID: UUID
}

struct LiveSession: Codable, Equatable {
    static let currentSchemaVersion = 1
    static let classicRulesVersion = "classic-3.1"

    var schemaVersion: Int
    var rulesVersion: String
    var drawPile: [LiveCardInstance]
    var discardPile: [LiveCardInstance]
    var tableCards: [String: [LiveCardInstance]]
    var tasks: [LiveTask]
    var forcedSequences: [LiveForcedSequence]
    var dealerPlayerID: UUID
    var lastReveal: LiveReveal?
    var eventLog: [LiveEvent]
    var shuffleCount: Int
    var initialCardCount: Int
    var nextShuffleSeed: UInt64

    static func makeClassic(
        profile: DeckProfile,
        players: [Player],
        seed: UInt64? = nil
    ) throws -> LiveSession {
        guard profile.mode == .classic else {
            throw LiveGameError.unsupportedRuleset
        }
        guard let firstPlayerID = players.first?.id else {
            throw LiveGameError.noPlayers
        }

        var cards = try LiveDeckFactory.classicCards(from: profile)
        var systemGenerator = SystemRandomNumberGenerator()
        let initialSeed = seed ?? systemGenerator.next()
        var generator = LiveSeededGenerator(state: initialSeed)
        cards.shuffle(using: &generator)

        let playerIDs = players.map(\.id)
        let tableCards: [String: [LiveCardInstance]] = Dictionary(
            uniqueKeysWithValues: playerIDs.map { ($0.uuidString, []) }
        )
        let tasks = playerIDs.map { LiveTask.openingDraw(playerID: $0) }
            + [.beginTurns(startPlayerID: firstPlayerID)]
        let nextSeed = generator.next()

        return LiveSession(
            schemaVersion: currentSchemaVersion,
            rulesVersion: classicRulesVersion,
            drawPile: cards,
            discardPile: [],
            tableCards: tableCards,
            tasks: tasks,
            forcedSequences: [],
            dealerPlayerID: firstPlayerID,
            lastReveal: nil,
            eventLog: [
                LiveEvent(
                    id: 0,
                    kind: .shuffled,
                    message: "New shoe shuffled · \(cards.count) cards",
                    playerID: nil,
                    cardID: nil
                )
            ],
            shuffleCount: 1,
            initialCardCount: cards.count,
            nextShuffleSeed: nextSeed
        )
    }

    var currentTask: LiveTask? { tasks.first }

    var allCards: [LiveCardInstance] {
        drawPile + discardPile + tableCards.values.flatMap { $0 }
    }

    var hasUniqueCardIDs: Bool {
        let ids = allCards.map(\.id)
        return Set(ids).count == ids.count
    }

    func cards(for playerID: UUID) -> [LiveCardInstance] {
        tableCards[playerID.uuidString] ?? []
    }

    func hasShield(playerID: UUID) -> Bool {
        cards(for: playerID).contains { $0.content == .action(.shield) }
    }

    func forcedSequence(id: UUID) -> LiveForcedSequence? {
        forcedSequences.first { $0.id == id }
    }
}

enum LiveCommand: Equatable {
    case draw
    case stay
    case chooseTarget(UUID)
    case startNextRound
    case finishGame
}

enum LiveGameError: Error, Equatable, LocalizedError {
    case noPlayers
    case unsupportedRuleset
    case unsupportedCard(String)
    case noLiveSession
    case commandNotAllowed
    case invalidTarget
    case noCardsAvailable
    case playerMissing

    var errorDescription: String? {
        switch self {
        case .noPlayers: return "At least one player is required."
        case .unsupportedRuleset: return "Dealer currently supports the Classic score profile only."
        case .unsupportedCard(let name): return "Dealer does not yet support \(name)."
        case .noLiveSession: return "This game does not have an active dealer session."
        case .commandNotAllowed: return "That action is not available right now."
        case .invalidTarget: return "Choose an eligible active player."
        case .noCardsAvailable: return "No cards are available to draw."
        case .playerMissing: return "A player in the dealer session is no longer available."
        }
    }
}

private enum LiveDeckFactory {
    static func classicCards(from profile: DeckProfile) throws -> [LiveCardInstance] {
        guard profile.subtractModifierCounts.isEmpty,
              profile.divideByTwoCount == 0,
              profile.specialNumberCardCounts.isEmpty else {
            throw LiveGameError.unsupportedRuleset
        }

        var cards: [LiveCardInstance] = []
        for (number, count) in profile.numberCardCounts.sorted(by: { $0.key < $1.key }) {
            cards.append(contentsOf: (0..<count).map { _ in LiveCardInstance(content: .number(number)) })
        }
        for (value, count) in profile.addModifierCounts.sorted(by: { $0.key < $1.key }) {
            cards.append(contentsOf: (0..<count).map { _ in LiveCardInstance(content: .addModifier(value)) })
        }
        cards.append(contentsOf: (0..<profile.x2Count).map { _ in LiveCardInstance(content: .multiplier) })

        for (storedKey, count) in profile.actionCardCounts.sorted(by: { $0.key < $1.key }) {
            guard let profileAction = DeckProfile.ActionCard.fromStoredKey(storedKey),
                  let action = LiveAction(profileAction: profileAction) else {
                throw LiveGameError.unsupportedCard(storedKey)
            }
            cards.append(contentsOf: (0..<count).map { _ in LiveCardInstance(content: .action(action)) })
        }
        return cards
    }
}

private struct LiveSeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

struct LiveGameReducer {
    static func apply(_ command: LiveCommand, to game: inout Game) throws {
        guard var session = game.liveSession else {
            throw LiveGameError.noLiveSession
        }

        try normalize(game: &game, session: &session)

        switch command {
        case .draw:
            try draw(game: &game, session: &session)
        case .stay:
            try stay(game: &game, session: &session)
        case .chooseTarget(let playerID):
            try chooseTarget(playerID, game: &game, session: &session)
        case .startNextRound:
            try startNextRound(game: &game, session: &session)
        case .finishGame:
            try finishGame(game: &game, session: &session)
        }

        try normalize(game: &game, session: &session)
        game.liveSession = session
    }

    static func eligibleTargets(in game: Game) -> [Player] {
        guard let session = game.liveSession,
              case .chooseTarget(let prompt)? = session.currentTask else {
            return []
        }
        return eligibleTargets(for: prompt, game: game, session: session)
    }

    private static func draw(game: inout Game, session: inout LiveSession) throws {
        guard let task = session.tasks.first else {
            throw LiveGameError.commandNotAllowed
        }

        let playerID: UUID
        let forcedSequenceID: UUID?
        switch task {
        case .openingDraw(let id):
            playerID = id
            forcedSequenceID = nil
            session.tasks.removeFirst()
        case .awaitDecision(let id):
            playerID = id
            forcedSequenceID = nil
            session.tasks.removeFirst()
            session.tasks.insert(.advanceTurn(afterPlayerID: id), at: 0)
        case .forcedDraw(let sequenceID, let id, _, _):
            playerID = id
            forcedSequenceID = sequenceID
            session.tasks.removeFirst()
        default:
            throw LiveGameError.commandNotAllowed
        }

        guard game.players.contains(where: { $0.id == playerID }) else {
            throw LiveGameError.playerMissing
        }

        guard let card = takeTopCard(session: &session) else {
            return
        }
        session.tableCards[playerID.uuidString, default: []].append(card)
        session.lastReveal = LiveReveal(card: card, playerID: playerID)
        let playerName = game.players.first(where: { $0.id == playerID })?.name ?? "Player"
        appendEvent(
            .revealed,
            "\(playerName) drew \(card.content.shortLabel)",
            playerID: playerID,
            cardID: card.id,
            session: &session
        )

        try resolve(
            card,
            for: playerID,
            forcedSequenceID: forcedSequenceID,
            game: &game,
            session: &session
        )
    }

    private static func stay(game: inout Game, session: inout LiveSession) throws {
        guard case .awaitDecision(let playerID)? = session.currentTask,
              let playerIndex = game.players.firstIndex(where: { $0.id == playerID }),
              !session.cards(for: playerID).isEmpty else {
            throw LiveGameError.commandNotAllowed
        }

        session.tasks.removeFirst()
        game.players[playerIndex].currentRound.state = .banked
        session.tasks.insert(.advanceTurn(afterPlayerID: playerID), at: 0)
        appendEvent(
            .stayed,
            "\(game.players[playerIndex].name) stayed at \(ScoreEngine.calculateRoundScore(round: game.players[playerIndex].currentRound, rules: game.scoringRules))",
            playerID: playerID,
            session: &session
        )
    }

    private static func chooseTarget(
        _ targetPlayerID: UUID,
        game: inout Game,
        session: inout LiveSession
    ) throws {
        guard case .chooseTarget(let prompt)? = session.currentTask else {
            throw LiveGameError.commandNotAllowed
        }
        let eligibleIDs = Set(eligibleTargets(for: prompt, game: game, session: session).map(\.id))
        guard eligibleIDs.contains(targetPlayerID),
              let targetIndex = game.players.firstIndex(where: { $0.id == targetPlayerID }),
              let sourceIndex = game.players.firstIndex(where: { $0.id == prompt.sourcePlayerID }) else {
            throw LiveGameError.invalidTarget
        }

        session.tasks.removeFirst()
        let sourceName = game.players[sourceIndex].name
        let targetName = game.players[targetIndex].name

        switch prompt.action {
        case .hold:
            game.players[targetIndex].currentRound.state = .frozen
            appendEvent(
                .held,
                "\(sourceName) held \(targetName)",
                playerID: targetPlayerID,
                cardID: prompt.cardID,
                session: &session
            )
        case .drawThree:
            let sequenceID = UUID()
            session.forcedSequences.append(
                LiveForcedSequence(id: sequenceID, recipientPlayerID: targetPlayerID, deferredPrompts: [])
            )
            let draws = (1...3).map {
                LiveTask.forcedDraw(sequenceID: sequenceID, playerID: targetPlayerID, drawNumber: $0, total: 3)
            }
            session.tasks.insert(
                contentsOf: draws + [.completeForced(sequenceID: sequenceID, playerID: targetPlayerID)],
                at: 0
            )
            appendEvent(
                .action,
                "\(sourceName) sent Draw 3 to \(targetName)",
                playerID: targetPlayerID,
                cardID: prompt.cardID,
                session: &session
            )
        case .shield:
            guard let card = removeCard(prompt.cardID, from: prompt.sourcePlayerID, session: &session) else {
                throw LiveGameError.commandNotAllowed
            }
            session.tableCards[targetPlayerID.uuidString, default: []].append(card)
            appendEvent(
                .action,
                "\(sourceName) passed a Shield to \(targetName)",
                playerID: targetPlayerID,
                cardID: prompt.cardID,
                session: &session
            )
        }
    }

    private static func startNextRound(game: inout Game, session: inout LiveSession) throws {
        guard case .roundComplete? = session.currentTask else {
            throw LiveGameError.commandNotAllowed
        }
        moveTableToDiscard(session: &session)
        game.startNewRound()
        guard let nextDealer = nextPlayer(after: session.dealerPlayerID, players: game.players) else {
            throw LiveGameError.noPlayers
        }
        session.dealerPlayerID = nextDealer.id
        session.lastReveal = nil
        session.forcedSequences.removeAll()
        let order = orderedPlayerIDs(startingAt: nextDealer.id, players: game.players)
        session.tasks = order.map { .openingDraw(playerID: $0) }
            + [.beginTurns(startPlayerID: nextDealer.id)]
        appendEvent(
            .round,
            "Round \(game.currentRoundNumber) started · \(nextDealer.name) deals",
            playerID: nextDealer.id,
            session: &session
        )
    }

    private static func finishGame(game: inout Game, session: inout LiveSession) throws {
        guard case .roundComplete? = session.currentTask else {
            throw LiveGameError.commandNotAllowed
        }
        moveTableToDiscard(session: &session)
        game.endRound()
        session.lastReveal = nil
        session.forcedSequences.removeAll()
        appendEvent(.round, "Final round scored", session: &session)
    }

    private static func resolve(
        _ card: LiveCardInstance,
        for playerID: UUID,
        forcedSequenceID: UUID?,
        game: inout Game,
        session: inout LiveSession
    ) throws {
        guard let playerIndex = game.players.firstIndex(where: { $0.id == playerID }) else {
            throw LiveGameError.playerMissing
        }

        switch card.content {
        case .number(let number):
            let hasDuplicate = game.players[playerIndex].currentRound.hand.selectedNumbers.contains(number)
            if hasDuplicate, let shield = session.cards(for: playerID).first(where: { $0.content == .action(.shield) }) {
                if let removedShield = removeCard(shield.id, from: playerID, session: &session) {
                    session.discardPile.append(removedShield)
                }
                if let removedDuplicate = removeCard(card.id, from: playerID, session: &session) {
                    session.discardPile.append(removedDuplicate)
                }
                appendEvent(
                    .protected,
                    "\(game.players[playerIndex].name)'s Shield stopped a duplicate \(number)",
                    playerID: playerID,
                    cardID: card.id,
                    session: &session
                )
            } else if hasDuplicate {
                game.players[playerIndex].currentRound.state = .busted
                appendEvent(
                    .busted,
                    "\(game.players[playerIndex].name) busted on \(number)",
                    playerID: playerID,
                    cardID: card.id,
                    session: &session
                )
                if let forcedSequenceID {
                    cancelForcedSequence(forcedSequenceID, session: &session)
                }
            } else {
                _ = game.players[playerIndex].currentRound.hand.addNumber(number)
                if game.players[playerIndex].currentRound.hand.hasSevenCardBonus {
                    game.players[playerIndex].currentRound.state = .banked
                    session.tasks = [
                        .roundComplete(
                            LiveRoundEndReason(kind: .sevenCards, playerID: playerID)
                        )
                    ]
                    session.forcedSequences.removeAll()
                    appendEvent(
                        .round,
                        "\(game.players[playerIndex].name) reached seven number cards",
                        playerID: playerID,
                        cardID: card.id,
                        session: &session
                    )
                }
            }

        case .addModifier(let value):
            game.players[playerIndex].currentRound.hand.addModifier(value)

        case .multiplier:
            game.players[playerIndex].currentRound.hand.addX2()

        case .action(let action):
            let prompt = LiveActionPrompt(action: action, sourcePlayerID: playerID, cardID: card.id)
            if let forcedSequenceID, action != .shield {
                // Classic 3.1 resolves nested Hold/Draw 3 actions only after the
                // current three-card sequence, and only if its recipient survives.
                guard let sequenceIndex = session.forcedSequences.firstIndex(where: { $0.id == forcedSequenceID }) else {
                    throw LiveGameError.commandNotAllowed
                }
                session.forcedSequences[sequenceIndex].deferredPrompts.append(prompt)
            } else if action == .shield, session.cards(for: playerID).filter({ $0.content == .action(.shield) }).count > 1 {
                let targets = eligibleTargets(for: prompt, game: game, session: session)
                if targets.isEmpty {
                    if let removed = removeCard(card.id, from: playerID, session: &session) {
                        session.discardPile.append(removed)
                    }
                    appendEvent(
                        .action,
                        "Extra Shield discarded · no eligible player",
                        playerID: playerID,
                        cardID: card.id,
                        session: &session
                    )
                } else {
                    session.tasks.insert(.chooseTarget(prompt), at: 0)
                }
            } else if action != .shield {
                session.tasks.insert(.chooseTarget(prompt), at: 0)
            }
        }
    }

    private static func normalize(game: inout Game, session: inout LiveSession) throws {
        var safetyCounter = 0
        while safetyCounter < 100 {
            safetyCounter += 1

            if game.players.allSatisfy({ $0.currentRound.state != .inRound }) {
                if case .roundComplete? = session.currentTask { return }
                session.tasks = [
                    .roundComplete(LiveRoundEndReason(kind: .allPlayersDone, playerID: nil))
                ]
                session.forcedSequences.removeAll()
                return
            }

            guard let task = session.currentTask else {
                session.tasks = [
                    .roundComplete(LiveRoundEndReason(kind: .allPlayersDone, playerID: nil))
                ]
                return
            }

            switch task {
            case .beginTurns(let startPlayerID):
                session.tasks.removeFirst()
                guard let player = activePlayer(startingAt: startPlayerID, players: game.players) else {
                    continue
                }
                session.tasks.insert(.awaitDecision(playerID: player.id), at: 0)

            case .advanceTurn(let playerID):
                session.tasks.removeFirst()
                guard let player = nextActivePlayer(after: playerID, players: game.players) else {
                    continue
                }
                session.tasks.insert(.awaitDecision(playerID: player.id), at: 0)

            case .completeForced(let sequenceID, let playerID):
                session.tasks.removeFirst()
                guard let sequenceIndex = session.forcedSequences.firstIndex(where: { $0.id == sequenceID }) else {
                    continue
                }
                let sequence = session.forcedSequences.remove(at: sequenceIndex)
                let playerState = game.players.first(where: { $0.id == playerID })?.currentRound.state
                if playerState != .busted {
                    session.tasks.insert(contentsOf: sequence.deferredPrompts.map(LiveTask.chooseTarget), at: 0)
                }

            case .chooseTarget(let prompt):
                if eligibleTargets(for: prompt, game: game, session: session).isEmpty {
                    session.tasks.removeFirst()
                    if prompt.action == .shield,
                       let removed = removeCard(prompt.cardID, from: prompt.sourcePlayerID, session: &session) {
                        session.discardPile.append(removed)
                    }
                    appendEvent(
                        .action,
                        "\(prompt.action.displayName) skipped · no eligible player",
                        playerID: prompt.sourcePlayerID,
                        cardID: prompt.cardID,
                        session: &session
                    )
                } else {
                    return
                }

            case .openingDraw, .awaitDecision, .forcedDraw, .roundComplete:
                return
            }
        }
        throw LiveGameError.commandNotAllowed
    }

    private static func takeTopCard(session: inout LiveSession) -> LiveCardInstance? {
        if session.drawPile.isEmpty {
            guard !session.discardPile.isEmpty else {
                session.tasks = [
                    .roundComplete(LiveRoundEndReason(kind: .noCardsAvailable, playerID: nil))
                ]
                appendEvent(
                    .round,
                    "No cards available · round ended",
                    session: &session
                )
                return nil
            }
            var generator = LiveSeededGenerator(state: session.nextShuffleSeed)
            session.drawPile = session.discardPile
            session.discardPile.removeAll()
            session.drawPile.shuffle(using: &generator)
            session.nextShuffleSeed = generator.next()
            session.shuffleCount += 1
            appendEvent(
                .shuffled,
                "Discard pile reshuffled · \(session.drawPile.count) cards",
                session: &session
            )
        }
        return session.drawPile.popLast()
    }

    private static func eligibleTargets(
        for prompt: LiveActionPrompt,
        game: Game,
        session: LiveSession
    ) -> [Player] {
        let activePlayers = game.players.filter { $0.currentRound.state == .inRound }
        switch prompt.action {
        case .hold, .drawThree:
            return activePlayers
        case .shield:
            return activePlayers.filter {
                $0.id != prompt.sourcePlayerID && !session.hasShield(playerID: $0.id)
            }
        }
    }

    private static func cancelForcedSequence(_ sequenceID: UUID, session: inout LiveSession) {
        session.tasks.removeAll { task in
            switch task {
            case .forcedDraw(let id, _, _, _), .completeForced(let id, _):
                return id == sequenceID
            default:
                return false
            }
        }
        session.forcedSequences.removeAll { $0.id == sequenceID }
    }

    private static func moveTableToDiscard(session: inout LiveSession) {
        for cards in session.tableCards.values {
            session.discardPile.append(contentsOf: cards)
        }
        session.tableCards = Dictionary(
            uniqueKeysWithValues: session.tableCards.keys.map { ($0, []) }
        )
    }

    private static func removeCard(
        _ cardID: UUID,
        from playerID: UUID,
        session: inout LiveSession
    ) -> LiveCardInstance? {
        let key = playerID.uuidString
        guard let index = session.tableCards[key]?.firstIndex(where: { $0.id == cardID }) else {
            return nil
        }
        return session.tableCards[key]?.remove(at: index)
    }

    private static func appendEvent(
        _ kind: LiveEventKind,
        _ message: String,
        playerID: UUID? = nil,
        cardID: UUID? = nil,
        session: inout LiveSession
    ) {
        let nextID = (session.eventLog.last?.id ?? -1) + 1
        session.eventLog.append(
            LiveEvent(id: nextID, kind: kind, message: message, playerID: playerID, cardID: cardID)
        )
        if session.eventLog.count > 500 {
            session.eventLog.removeFirst(session.eventLog.count - 500)
        }
    }

    private static func orderedPlayerIDs(startingAt playerID: UUID, players: [Player]) -> [UUID] {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else {
            return players.map(\.id)
        }
        return Array(players[index...] + players[..<index]).map(\.id)
    }

    private static func activePlayer(startingAt playerID: UUID, players: [Player]) -> Player? {
        orderedPlayerIDs(startingAt: playerID, players: players)
            .compactMap { id in players.first(where: { $0.id == id }) }
            .first { $0.currentRound.state == .inRound }
    }

    private static func nextActivePlayer(after playerID: UUID, players: [Player]) -> Player? {
        guard let next = nextPlayer(after: playerID, players: players) else { return nil }
        return activePlayer(startingAt: next.id, players: players)
    }

    private static func nextPlayer(after playerID: UUID, players: [Player]) -> Player? {
        guard !players.isEmpty,
              let index = players.firstIndex(where: { $0.id == playerID }) else {
            return players.first
        }
        return players[(index + 1) % players.count]
    }
}
