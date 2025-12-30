//
//  GameStatsTests.swift
//  flip7calculatorTests
//
//  Tests for GameStats and PlayerGameStats computation utilities.
//

import Foundation
import Testing
@testable import flip7calculator

struct GameStatsTests {
    
    // MARK: - Test Fixtures
    
    /// Creates a test game with predictable history
    private func createTestGame() -> Game {
        var game = Game(players: [
            Player(name: "Alice"),
            Player(name: "Bob"),
            Player(name: "Charlie")
        ], targetScore: 200)
        
        let aliceId = game.players[0].id
        let bobId = game.players[1].id
        let charlieId = game.players[2].id
        
        // Round 1: Bob leads
        game.gameHistory.append(GameRound(roundNumber: 1, results: [
            RoundResult(
                playerId: aliceId,
                playerName: "Alice",
                roundScore: 30,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [5, 7, 9, 3], x2Count: 0, addMods: [6: 1]),
                autoScore: 30
            ),
            RoundResult(
                playerId: bobId,
                playerName: "Bob",
                roundScore: 50,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [10, 11, 12, 8, 4], x2Count: 0, addMods: [:]),
                autoScore: 50
            ),
            RoundResult(
                playerId: charlieId,
                playerName: "Charlie",
                roundScore: 0,
                state: .busted,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [1, 2, 3], x2Count: 0, addMods: [:]),
                autoScore: 0
            )
        ]))
        
        // Round 2: Alice catches up
        game.gameHistory.append(GameRound(roundNumber: 2, results: [
            RoundResult(
                playerId: aliceId,
                playerName: "Alice",
                roundScore: 45,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [2, 4, 6, 8, 10], x2Count: 0, addMods: [8: 1]),
                autoScore: 45
            ),
            RoundResult(
                playerId: bobId,
                playerName: "Bob",
                roundScore: 0,
                state: .busted,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [1, 5], x2Count: 0, addMods: [:]),
                autoScore: 0
            ),
            RoundResult(
                playerId: charlieId,
                playerName: "Charlie",
                roundScore: 40,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [3, 7, 11, 9], x2Count: 0, addMods: [4: 2]),
                autoScore: 40
            )
        ]))
        
        // Round 3: Alice takes lead with Flip7 + x2
        game.gameHistory.append(GameRound(roundNumber: 3, results: [
            RoundResult(
                playerId: aliceId,
                playerName: "Alice",
                roundScore: 72,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [0, 1, 2, 3, 4, 5, 6], x2Count: 1, addMods: [:]),
                autoScore: 72
            ),
            RoundResult(
                playerId: bobId,
                playerName: "Bob",
                roundScore: 25,
                state: .frozen,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [3, 7, 12], x2Count: 0, addMods: [:]),
                autoScore: 25
            ),
            RoundResult(
                playerId: charlieId,
                playerName: "Charlie",
                roundScore: 35,
                state: .banked,
                manualScoreOverride: nil,
                handSnapshot: RoundHand(selectedNumbers: [5, 8, 10, 6], x2Count: 0, addMods: [:]),
                autoScore: 35
            )
        ]))
        
        // Update player totals
        game.players[0].totalScore = 147 // 30 + 45 + 72
        game.players[1].totalScore = 75  // 50 + 0 + 25
        game.players[2].totalScore = 75  // 0 + 40 + 35
        
        return game
    }
    
    // MARK: - Basic Game Stats Tests
    
    @Test func testRoundsPlayed() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.roundsPlayed == 3)
    }
    
    @Test func testTotalPointsScored() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.totalPointsScored == 297) // 147 + 75 + 75
    }
    
    @Test func testAverageScorePerPlayer() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.averageScorePerPlayer == 99.0) // 297 / 3
    }
    
    // MARK: - Winner Tests
    
    @Test func testWinnerIdentification() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.winners.count == 1)
        #expect(stats.winners.first?.name == "Alice")
    }
    
    @Test func testWinningMargin() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.winningMargin == 72) // 147 - 75
    }
    
    @Test func testRankedPlayers() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.rankedPlayers[0].name == "Alice")
        #expect(stats.rankedPlayers[1].totalScore == 75) // Bob or Charlie
        #expect(stats.rankedPlayers[2].totalScore == 75) // Bob or Charlie
    }
    
    // MARK: - Lead Changes Tests
    
    @Test func testLeadChanges() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        // Round 1: Bob leads (50), Round 2: Alice leads (75 vs 50), Round 3: Alice still leads
        // So there's 1 lead change (Bob → Alice after round 2)
        #expect(stats.leadChanges == 1)
    }
    
    @Test func testCumulativeScoresByRound() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        let cumScores = stats.cumulativeScoresByRound
        
        #expect(cumScores.count == 3)
        
        // After round 1: Alice=30, Bob=50, Charlie=0
        let aliceId = game.players[0].id
        let bobId = game.players[1].id
        #expect(cumScores[0][aliceId] == 30)
        #expect(cumScores[0][bobId] == 50)
        
        // After round 3: Alice=147, Bob=75, Charlie=75
        #expect(cumScores[2][aliceId] == 147)
        #expect(cumScores[2][bobId] == 75)
    }
    
    // MARK: - Round Extremes Tests
    
    @Test func testBestRoundScore() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        let best = stats.bestRoundScore
        
        #expect(best != nil)
        #expect(best?.playerName == "Alice")
        #expect(best?.score == 72)
        #expect(best?.round == 3)
    }
    
    // MARK: - Aggregate Totals Tests
    
    @Test func testTotalBusts() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.totalBusts == 2) // Charlie R1, Bob R2
    }
    
    @Test func testTotalFlip7s() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.totalFlip7s == 1) // Alice R3
    }
    
    @Test func testTotalX2Used() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        #expect(stats.totalX2Used == 1) // Alice R3
    }
    
    @Test func testTotalModifiersUsed() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        // R1: Alice +6, R2: Alice +8, Charlie +4+4, R3: none
        #expect(stats.totalModifiersUsed == 22) // 6 + 8 + 8
    }
    
    // MARK: - Player Comparison Tests
    
    @Test func testMostBusts() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        let mostBusts = stats.mostBusts
        
        #expect(mostBusts != nil)
        #expect(mostBusts?.count == 1) // Both Charlie and Bob have 1 bust
    }
    
    @Test func testMostFlip7s() {
        let game = createTestGame()
        let stats = GameStats(game: game)
        let mostFlip7s = stats.mostFlip7s
        
        #expect(mostFlip7s != nil)
        #expect(mostFlip7s?.player.name == "Alice")
        #expect(mostFlip7s?.count == 1)
    }
}

// MARK: - Player Game Stats Tests

struct PlayerGameStatsTests {
    
    private func createTestGame() -> Game {
        var game = Game(players: [
            Player(name: "TestPlayer")
        ], targetScore: 200)
        
        let playerId = game.players[0].id
        
        // Create varied round history
        game.gameHistory = [
            GameRound(roundNumber: 1, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 40,
                           state: .banked, manualScoreOverride: nil,
                           handSnapshot: RoundHand(selectedNumbers: [5, 7, 9, 11], x2Count: 0, addMods: [6: 1]),
                           autoScore: 40)
            ]),
            GameRound(roundNumber: 2, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 0,
                           state: .busted, manualScoreOverride: nil,
                           handSnapshot: RoundHand(selectedNumbers: [1, 2], x2Count: 0, addMods: [:]),
                           autoScore: 0)
            ]),
            GameRound(roundNumber: 3, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 60,
                           state: .banked, manualScoreOverride: nil,
                           handSnapshot: RoundHand(selectedNumbers: [3, 6, 9, 10, 12], x2Count: 0, addMods: [10: 1, 4: 1]),
                           autoScore: 60)
            ]),
            GameRound(roundNumber: 4, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 57,
                           state: .banked, manualScoreOverride: nil,
                           handSnapshot: RoundHand(selectedNumbers: [0, 1, 2, 3, 4, 5, 6], x2Count: 1, addMods: [:]),
                           autoScore: 57)
            ]),
            GameRound(roundNumber: 5, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 30,
                           state: .frozen, manualScoreOverride: nil,
                           handSnapshot: RoundHand(selectedNumbers: [4, 8, 10], x2Count: 0, addMods: [8: 1]),
                           autoScore: 30)
            ])
        ]
        
        game.players[0].totalScore = 187 // 40 + 0 + 60 + 57 + 30
        
        return game
    }
    
    // MARK: - Basic Stats Tests
    
    @Test func testRoundScores() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.roundScores == [40, 0, 60, 57, 30])
    }
    
    @Test func testNonBustRoundScores() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.nonBustRoundScores == [40, 60, 57, 30])
    }
    
    @Test func testTotalScore() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.totalScore == 187)
    }
    
    @Test func testAverageRoundScore() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.averageRoundScore == 37.4) // 187 / 5
    }
    
    @Test func testMedianRoundScore() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        // Sorted: [0, 30, 40, 57, 60] -> median is 40
        #expect(stats.medianRoundScore == 40)
    }
    
    @Test func testScoreStandardDeviation() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.scoreStandardDeviation != nil)
        // Roughly 22.5, but we just check it's reasonable
        #expect(stats.scoreStandardDeviation! > 20)
        #expect(stats.scoreStandardDeviation! < 25)
    }
    
    // MARK: - Best/Worst Tests
    
    @Test func testBestRoundScore() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.bestRoundScore == 60)
    }
    
    @Test func testWorstNonBustScore() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.worstNonBustScore == 30)
    }
    
    @Test func testBestRoundNumber() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.bestRoundNumber == 3) // Round 3 had score 60
    }
    
    // MARK: - State Stats Tests
    
    @Test func testBustCount() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.bustCount == 1)
    }
    
    @Test func testBustRate() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.bustRate == 0.2) // 1/5
    }
    
    @Test func testBankedCount() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.bankedCount == 3) // Rounds 1, 3, 4
    }
    
    @Test func testFrozenCount() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.frozenCount == 1) // Round 5
    }
    
    // MARK: - Flip7 / Multipliers / Modifiers Tests
    
    @Test func testFlip7Count() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.flip7Count == 1) // Round 4
    }
    
    @Test func testTotalX2Used() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.totalX2Used == 1) // Round 4
    }
    
    @Test func testTotalModifiersUsed() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        // R1: +6, R3: +10+4, R5: +8
        #expect(stats.totalModifiersUsed == 28)
    }
    
    // MARK: - Streak Tests
    
    @Test func testLongestNonBustStreak() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        // Rounds: 1-good, 2-bust, 3-good, 4-good, 5-good -> streak of 3 at end
        #expect(stats.longestNonBustStreak == 3)
    }
    
    @Test func testLongestHighScoringStreak() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        // Median is 40, scores are [40, 0, 60, 57, 30]
        // Above median (>40): 60, 57 -> streak of 2
        #expect(stats.longestHighScoringStreak == 2)
    }
    
    // MARK: - Cumulative Progress Tests
    
    @Test func testCumulativeScores() {
        let game = createTestGame()
        let stats = PlayerGameStats(playerId: game.players[0].id, game: game)
        
        #expect(stats.cumulativeScores == [40, 40, 100, 157, 187])
    }
}

// MARK: - RoundResult Tests

struct RoundResultTests {
    
    @Test func testIsBustedWithState() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 0,
            state: .busted,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(),
            autoScore: 0
        )
        #expect(result.isBusted == true)
    }
    
    @Test func testIsBustedWithoutState() {
        // Legacy result without state
        let result = RoundResult(playerId: UUID(), playerName: "Test", roundScore: 0)
        #expect(result.isBusted == true) // Falls back to roundScore == 0
    }
    
    @Test func testIsNotBustedWithZeroScoreButBankedState() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 0,
            state: .banked,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(),
            autoScore: 0
        )
        #expect(result.isBusted == false) // State takes precedence
    }
    
    @Test func testHasFlip7() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 50,
            state: .banked,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(selectedNumbers: [0, 1, 2, 3, 4, 5, 6], x2Count: 0, addMods: [:]),
            autoScore: 50
        )
        #expect(result.hasFlip7 == true)
    }
    
    @Test func testX2Count() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 50,
            state: .banked,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(selectedNumbers: [5, 6], x2Count: 2, addMods: [:]),
            autoScore: 50
        )
        #expect(result.x2Count == 2)
    }
    
    @Test func testModifierTotal() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 50,
            state: .banked,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(selectedNumbers: [5, 6], x2Count: 0, addMods: [4: 2, 6: 1]),
            autoScore: 50
        )
        #expect(result.modifierTotal == 14) // 4*2 + 6
    }
    
    @Test func testCardCount() {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "Test",
            roundScore: 50,
            state: .banked,
            manualScoreOverride: nil,
            handSnapshot: RoundHand(selectedNumbers: [1, 3, 5, 7, 9], x2Count: 0, addMods: [:]),
            autoScore: 50
        )
        #expect(result.cardCount == 5)
    }
}

// MARK: - Backward Compatibility Tests

struct BackwardCompatibilityTests {
    
    @Test func testLegacyRoundResultDecoding() throws {
        // JSON representing old RoundResult format (no snapshot fields)
        let legacyJSON = """
        {
            "playerId": "550e8400-e29b-41d4-a716-446655440000",
            "playerName": "OldPlayer",
            "roundScore": 42
        }
        """
        
        let data = legacyJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let result = try decoder.decode(RoundResult.self, from: data)
        
        #expect(result.playerName == "OldPlayer")
        #expect(result.roundScore == 42)
        #expect(result.state == nil)
        #expect(result.handSnapshot == nil)
        #expect(result.manualScoreOverride == nil)
        #expect(result.autoScore == nil)
    }
    
    @Test func testNewRoundResultDecoding() throws {
        let newJSON = """
        {
            "playerId": "550e8400-e29b-41d4-a716-446655440000",
            "playerName": "NewPlayer",
            "roundScore": 55,
            "state": "banked",
            "handSnapshot": {
                "selectedNumbers": [1, 3, 5, 7, 9],
                "x2Count": 1,
                "addMods": {"4": 1}
            },
            "autoScore": 55
        }
        """
        
        let data = newJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let result = try decoder.decode(RoundResult.self, from: data)
        
        #expect(result.playerName == "NewPlayer")
        #expect(result.roundScore == 55)
        #expect(result.state == .banked)
        #expect(result.handSnapshot != nil)
        #expect(result.handSnapshot?.selectedNumbers.count == 5)
        #expect(result.handSnapshot?.x2Count == 1)
        #expect(result.autoScore == 55)
    }
    
    @Test func testRoundResultEncoding() throws {
        let result = RoundResult(
            playerId: UUID(),
            playerName: "EncodeTest",
            roundScore: 30,
            state: .frozen,
            manualScoreOverride: 35,
            handSnapshot: RoundHand(selectedNumbers: [2, 4, 6], x2Count: 0, addMods: [8: 1]),
            autoScore: 28
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RoundResult.self, from: data)
        
        #expect(decoded.playerName == "EncodeTest")
        #expect(decoded.roundScore == 30)
        #expect(decoded.state == .frozen)
        #expect(decoded.manualScoreOverride == 35)
        #expect(decoded.autoScore == 28)
        #expect(decoded.handSnapshot?.selectedNumbers == [2, 4, 6])
    }
    
    @Test func testLegacyRoundResultFallbacks() {
        // Legacy result (no snapshot)
        let result = RoundResult(playerId: UUID(), playerName: "Legacy", roundScore: 0)
        
        // Should use fallback behaviors
        #expect(result.isBusted == true) // Falls back to roundScore == 0
        #expect(result.hasFlip7 == false) // No snapshot
        #expect(result.x2Count == 0) // No snapshot
        #expect(result.modifierTotal == 0) // No snapshot
        #expect(result.cardCount == 0) // No snapshot
    }
    
    @Test func testGameRoundWithMixedResults() throws {
        // A game round might have a mix of old and new results during migration
        let json = """
        {
            "roundNumber": 1,
            "results": [
                {
                    "playerId": "550e8400-e29b-41d4-a716-446655440001",
                    "playerName": "OldFormat",
                    "roundScore": 25
                },
                {
                    "playerId": "550e8400-e29b-41d4-a716-446655440002",
                    "playerName": "NewFormat",
                    "roundScore": 40,
                    "state": "banked",
                    "handSnapshot": {
                        "selectedNumbers": [5, 10, 12],
                        "x2Count": 0,
                        "addMods": {}
                    },
                    "autoScore": 40
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let round = try decoder.decode(GameRound.self, from: data)
        
        #expect(round.roundNumber == 1)
        #expect(round.results.count == 2)
        #expect(round.results[0].state == nil) // Old format
        #expect(round.results[1].state == .banked) // New format
    }
}

// MARK: - Chart Data Tests

struct ChartDataTests {
    
    @Test func testCumulativeChartDataGeneration() {
        var game = Game(players: [
            Player(name: "P1"),
            Player(name: "P2")
        ], targetScore: 100)
        
        let p1Id = game.players[0].id
        let p2Id = game.players[1].id
        
        game.gameHistory = [
            GameRound(roundNumber: 1, results: [
                RoundResult(playerId: p1Id, playerName: "P1", roundScore: 20),
                RoundResult(playerId: p2Id, playerName: "P2", roundScore: 30)
            ]),
            GameRound(roundNumber: 2, results: [
                RoundResult(playerId: p1Id, playerName: "P1", roundScore: 25),
                RoundResult(playerId: p2Id, playerName: "P2", roundScore: 15)
            ])
        ]
        
        let stats = GameStats(game: game)
        let chartData = stats.cumulativeChartData()
        
        // Should have: 2 players × (1 start point + 2 rounds) = 6 points
        #expect(chartData.count == 6)
        
        // Check round 0 (start)
        let startPoints = chartData.filter { $0.roundNumber == 0 }
        #expect(startPoints.count == 2)
        #expect(startPoints.allSatisfy { $0.score == 0 })
        
        // Check final cumulative scores (round 2)
        let round2Points = chartData.filter { $0.roundNumber == 2 }
        #expect(round2Points.count == 2)
        
        let p1Final = round2Points.first { $0.playerId == p1Id }
        let p2Final = round2Points.first { $0.playerId == p2Id }
        #expect(p1Final?.score == 45) // 20 + 25
        #expect(p2Final?.score == 45) // 30 + 15
    }
    
    @Test func testRoundScoreChartDataForPlayer() {
        var game = Game(players: [
            Player(name: "TestPlayer")
        ], targetScore: 100)
        
        let playerId = game.players[0].id
        
        game.gameHistory = [
            GameRound(roundNumber: 1, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 30)
            ]),
            GameRound(roundNumber: 2, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 0)
            ]),
            GameRound(roundNumber: 3, results: [
                RoundResult(playerId: playerId, playerName: "TestPlayer", roundScore: 45)
            ])
        ]
        
        let stats = GameStats(game: game)
        let chartData = stats.roundScoreChartData(for: playerId)
        
        #expect(chartData.count == 3)
        #expect(chartData[0].roundNumber == 1)
        #expect(chartData[0].score == 30)
        #expect(chartData[1].roundNumber == 2)
        #expect(chartData[1].score == 0)
        #expect(chartData[2].roundNumber == 3)
        #expect(chartData[2].score == 45)
    }
}

