#if DEBUG
import SwiftUI

enum AppStoreCaptureFixture: String {
    case setup
    case live
    case dealer
    case gameOver = "game-over"
    case stats
    case layoutAudit = "layout-audit"

    static let requested: AppStoreCaptureFixture? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-appStoreCapture"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return AppStoreCaptureFixture(rawValue: arguments[flagIndex + 1])
    }()

    static let playerNames = ["Peter", "Ned", "Mary", "Gwen"]

    static let layoutAuditPlayerNames = [
        "Peter", "Ned", "Mary", "Gwen", "Miles", "May", "Ben", "Felicia"
    ]

    private static let playerIDs = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    ]

    private static var layoutAuditPlayerCount: Int {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-capturePlayerCount"),
              arguments.indices.contains(flagIndex + 1),
              let requestedCount = Int(arguments[flagIndex + 1]) else {
            return 4
        }
        return min(max(requestedCount, 4), layoutAuditPlayerNames.count)
    }

    static func prepareDefaults() {
        UserDefaults.standard.set("dark", forKey: "appTheme")
        UserDefaults.standard.set(VisualTheme.v2.rawValue, forKey: "visualThemeVersion")
        UserDefaults.standard.set(false, forKey: "showOpeningAnimation")
        UserDefaults.standard.set(GameMode.classic.rawValue, forKey: "defaultGameMode")
        UserDefaults.standard.set(ScoringRules.defaultBrutalMode, forKey: "defaultBrutalMode")
        UserDefaults.standard.set(GameEntryIntent.scoreCalculator.rawValue, forKey: "lastGameEntryIntent")
        UserDefaults.standard.set(
            requested == .dealer ? RiskInsightsMode.percentage.rawValue : RiskInsightsMode.off.rawValue,
            forKey: "riskInsightsMode"
        )
        let names = requested == .layoutAudit
            ? Array(layoutAuditPlayerNames.prefix(layoutAuditPlayerCount))
            : playerNames
        PersistedRoster(names: names).save()
    }

    static func game(for fixture: AppStoreCaptureFixture) -> Game? {
        switch fixture {
        case .setup:
            return nil
        case .live:
            return liveGame()
        case .dealer:
            return dealerGame()
        case .gameOver, .stats:
            return completedGame()
        case .layoutAudit:
            return layoutAuditGame()
        }
    }

    private static func layoutAuditGame() -> Game {
        let players = zip(playerIDs, layoutAuditPlayerNames)
            .prefix(layoutAuditPlayerCount)
            .map { id, name in Player(id: id, name: name) }
        return Game(
            players: players,
            targetScore: 200,
            deckProfile: .vengeance,
            scoringRules: .vengeance
        )
    }

    private static func liveGame() -> Game {
        var game = baseGame()
        game.gameHistory = Array(completedRounds.prefix(4))
        game.currentRoundIndex = game.gameHistory.count
        applyHistoryTotals(to: &game)

        game.players[0].currentRound = PlayerRound(
            state: .banked,
            hand: hand([2, 5, 6, 8, 9, 10, 12], modifiers: [10: 1])
        )
        game.players[1].currentRound = PlayerRound(
            state: .inRound,
            hand: hand([5, 7, 8, 10])
        )
        game.players[2].currentRound = PlayerRound(
            state: .frozen,
            hand: hand([5, 7, 8, 12], x2Count: 1)
        )
        game.players[3].currentRound = PlayerRound(
            state: .busted,
            hand: hand([4, 7, 8, 10, 12], modifiers: [4: 1, 8: 1])
        )
        return game
    }

    private static func dealerGame() -> Game? {
        let players = zip(playerIDs, playerNames).map { id, name in
            Player(id: id, name: name)
        }
        var game = Game(
            players: players,
            targetScore: 200,
            deckProfile: .standard,
            scoringRules: .classic,
            playStyle: .digitalDealer
        )
        guard var session = try? LiveSession.makeClassic(
            profile: .standard,
            players: players,
            seed: 7
        ) else {
            return nil
        }

        let fixtureContents: [[LiveCardContent]] = [
            [.number(2), .number(9)],
            [.number(5)],
            [.number(7), .addModifier(4)],
            [.number(3)]
        ]
        for (playerIndex, contents) in fixtureContents.enumerated() {
            for content in contents {
                guard let cardIndex = session.drawPile.firstIndex(where: { $0.content == content }) else {
                    continue
                }
                let card = session.drawPile.remove(at: cardIndex)
                let playerID = players[playerIndex].id
                session.tableCards[playerID.uuidString, default: []].append(card)
                switch content {
                case .number(let value):
                    _ = game.players[playerIndex].currentRound.hand.addNumber(value)
                case .addModifier(let value):
                    game.players[playerIndex].currentRound.hand.addModifier(value)
                case .multiplier:
                    game.players[playerIndex].currentRound.hand.addX2()
                case .action:
                    break
                }
            }
        }
        let focusPlayerID = players[0].id
        session.tasks = [.awaitDecision(playerID: focusPlayerID)]
        session.lastReveal = session.cards(for: focusPlayerID).last.map {
            LiveReveal(card: $0, playerID: focusPlayerID)
        }
        session.eventLog.append(
            LiveEvent(
                id: 1,
                kind: .round,
                message: "Opening deal complete",
                playerID: focusPlayerID,
                cardID: nil
            )
        )
        game.liveSession = session
        return game
    }

    private static func completedGame() -> Game {
        var game = baseGame()
        game.gameHistory = completedRounds
        game.currentRoundIndex = game.gameHistory.count - 1
        applyHistoryTotals(to: &game)
        return game
    }

    private static func baseGame() -> Game {
        let players = zip(playerIDs, playerNames).map { id, name in
            Player(id: id, name: name)
        }
        return Game(players: players, targetScore: 200, deckProfile: .standard)
    }

    private static var completedRounds: [GameRound] {
        [
            round(1, [
                result(0, hand: hand([3, 5, 8, 12])),
                result(1, hand: hand([9, 10, 11, 12], modifiers: [2: 1])),
                result(2, hand: hand([4, 8, 10, 12], modifiers: [2: 1])),
                result(3, state: .busted, hand: hand([6, 8]))
            ]),
            round(2, [
                result(0, state: .busted, hand: hand([7, 11])),
                result(1, hand: hand([5, 7, 8, 10])),
                result(2, hand: hand([4, 6, 9, 10, 12])),
                result(3, state: .frozen, hand: hand([4, 5, 7, 10], x2Count: 1))
            ]),
            round(3, [
                result(0, hand: hand([5, 7, 9, 12], modifiers: [4: 1, 8: 1, 10: 1])),
                result(1, state: .busted, hand: hand([8, 10])),
                result(2, hand: hand([4, 6, 8, 10])),
                result(3, hand: hand([6, 8, 10, 12], modifiers: [2: 1]))
            ]),
            round(4, [
                result(0, hand: hand([5, 8, 10, 12], modifiers: [4: 1, 8: 1])),
                result(1, state: .frozen, hand: hand([6, 8, 10, 12], modifiers: [2: 1])),
                result(2, state: .busted, hand: hand([7, 9])),
                result(3, hand: hand([8, 10, 12], modifiers: [6: 1, 8: 1]))
            ]),
            round(5, [
                result(0, hand: hand([2, 5, 6, 8, 9, 10, 12], modifiers: [10: 1])),
                result(1, hand: hand([5, 7, 8, 10])),
                result(2, state: .frozen, hand: hand([5, 7, 8, 12], x2Count: 1)),
                result(3, hand: hand([4, 7, 8, 10, 12], modifiers: [4: 1, 8: 1]))
            ])
        ]
    }

    private static func hand(
        _ numbers: Set<Int>,
        x2Count: Int = 0,
        modifiers: [Int: Int] = [:]
    ) -> RoundHand {
        RoundHand(selectedNumbers: numbers, x2Count: x2Count, addMods: modifiers)
    }

    private static func result(
        _ playerIndex: Int,
        state: PlayerRoundState = .banked,
        hand: RoundHand
    ) -> RoundResult {
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: state)
        return RoundResult(
            playerId: playerIDs[playerIndex],
            playerName: playerNames[playerIndex],
            roundScore: score,
            state: state,
            manualScoreOverride: nil,
            handSnapshot: hand,
            autoScore: score
        )
    }

    private static func round(_ number: Int, _ results: [RoundResult]) -> GameRound {
        GameRound(roundNumber: number, results: results)
    }

    private static func applyHistoryTotals(to game: inout Game) {
        for playerIndex in game.players.indices {
            let playerID = game.players[playerIndex].id
            game.players[playerIndex].totalScore = game.gameHistory.reduce(0) { total, round in
                total + (round.results.first { $0.playerId == playerID }?.roundScore ?? 0)
            }
        }
    }
}

struct AppStoreCaptureView: View {
    let fixture: AppStoreCaptureFixture
    @State private var viewModel: GameViewModel

    init(fixture: AppStoreCaptureFixture) {
        AppStoreCaptureFixture.prepareDefaults()
        let model = GameViewModel()
        model.game = AppStoreCaptureFixture.game(for: fixture)
        self.fixture = fixture
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        Group {
            switch fixture {
            case .setup:
                ActiveGameRoot(viewModel: $viewModel, animateSetupTitle: false)
            case .live:
                GameView(viewModel: viewModel)
            case .dealer:
                DealerGameView(viewModel: viewModel)
            case .gameOver:
                ZStack {
                    GameView(viewModel: viewModel)
                    GameOverOverlay(
                        viewModel: viewModel,
                        onPlayAgain: {},
                        onNewGame: {},
                        onUndo: {}
                    )
                }
            case .stats:
                if let game = viewModel.game {
                    GameOverStatsView(game: game)
                }
            case .layoutAudit:
                GameView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
        .tint(DesignColor.color(.brandPrimary, theme: .v2, colorScheme: .dark))
        .environment(\.visualTheme, VisualTheme.v2)
    }
}
#endif
