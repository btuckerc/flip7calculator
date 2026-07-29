#if DEBUG
import SwiftUI

enum AppStoreCaptureFixture: String {
    case setup
    case live
    case gameOver = "game-over"
    case stats

    static let requested: AppStoreCaptureFixture? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-appStoreCapture"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return AppStoreCaptureFixture(rawValue: arguments[flagIndex + 1])
    }()

    static let playerNames = ["Peter", "Ned", "Mary", "Gwen"]

    private static let playerIDs = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    ]

    static func prepareDefaults() {
        UserDefaults.standard.set("dark", forKey: "appTheme")
        UserDefaults.standard.set(VisualTheme.v2.rawValue, forKey: "visualThemeVersion")
        UserDefaults.standard.set(false, forKey: "showOpeningAnimation")
        PersistedRoster(names: playerNames).save()
    }

    static func game(for fixture: AppStoreCaptureFixture) -> Game? {
        switch fixture {
        case .setup:
            return nil
        case .live:
            return liveGame()
        case .gameOver, .stats:
            return completedGame()
        }
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
                GameSetupView(viewModel: $viewModel, animateTitle: false)
            case .live:
                GameView(viewModel: viewModel)
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
            }
        }
        .preferredColorScheme(.dark)
        .tint(DesignColor.color(.brandPrimary, theme: .v2, colorScheme: .dark))
        .environment(\.visualTheme, VisualTheme.v2)
    }
}
#endif
