//
//  OverhaulPerformanceAndAvailabilityTests.swift
//  flip7calculatorTests
//
//  Verifies cached deck availability, persistence efficiency, idempotent round finalization,
//  mid-round target-score safety, manual score idempotency, modifier-only clear,
//  deterministic unique chart IDs (including duplicate/renamed players), WCAG contrast,
//  visual theme migration preservation, and precomputed stats snapshots.
//

import Foundation
import SwiftUI
import Testing
@testable import flip7calculator

private final class CountingUserDefaults: UserDefaults {
    private(set) var writeCount = 0
    private(set) var removeCount = 0
    private(set) var writtenKeys: [String] = []

    override func set(_ value: Any?, forKey defaultName: String) {
        writeCount += 1
        writtenKeys.append(defaultName)
        super.set(value, forKey: defaultName)
    }

    override func removeObject(forKey defaultName: String) {
        removeCount += 1
        super.removeObject(forKey: defaultName)
    }

    func resetCounters() {
        writeCount = 0
        removeCount = 0
        writtenKeys.removeAll()
    }
}

struct OverhaulPerformanceAndAvailabilityTests {
    private func makeIsolatedDefaults() -> (CountingUserDefaults, String) {
        let suiteName = "com.tcraig.flip7calculator.tests.\(UUID().uuidString)"
        let defaults = CountingUserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    @Test func cachedAvailabilityTracksMutationsUndoRedoAndModeSwitch() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        guard let game = vm.game else {
            Issue.record("Expected active game")
            return
        }
        let alice = game.players[0].id
        let bob = game.players[1].id

        #expect(vm.roundAvailability.remainingNumberCount(1) == 1)
        #expect(vm.canAddNumber(1, toPlayer: alice))
        #expect(vm.canAddX2())

        _ = vm.addCardToPlayer(alice, number: 1)
        #expect(vm.roundAvailability.remainingNumberCount(1) == 0)
        #expect(!vm.canAddNumber(1, toPlayer: bob))

        vm.addX2ToPlayer(alice)
        #expect(vm.roundAvailability.x2 == 0)
        #expect(!vm.canAddX2())

        vm.undo()
        #expect(vm.roundAvailability.x2 == 1)
        #expect(vm.canAddX2())

        vm.redo()
        #expect(vm.roundAvailability.x2 == 0)
        #expect(!vm.canAddX2())

        vm.switchGameMode(to: .vengeance)
        #expect(vm.roundAvailability.divideByTwo == 1)
        #expect(vm.canAddDivideByTwo())
        #expect(vm.roundAvailability.specialNumbers[.luckyThirteen] == 1)
    }

    @Test func loadingExistingGamePerformsZeroWritesAndSingleWritePerCommit() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let writer = GameViewModel(defaults: defaults)
        defaults.resetCounters()

        writer.startNewGame(players: ["Alice", "Bob", "Carol", "Dave"], targetScore: 250)
        #expect(defaults.writeCount == 1)

        let aliceId = writer.game!.players[0].id
        defaults.resetCounters()
        _ = writer.addCardToPlayer(aliceId, number: 7)
        #expect(defaults.writeCount == 1)

        defaults.resetCounters()
        writer.addModifierToPlayer(aliceId, value: 4)
        #expect(defaults.writeCount == 1)

        defaults.resetCounters()
        let reader = GameViewModel(defaults: defaults)
        #expect(defaults.writeCount == 0)
        #expect(defaults.removeCount == 0)
        #expect(reader.game?.targetScore == 250)
        #expect(reader.game?.players[0].currentRound.hand.selectedNumbers == [7])
        #expect(reader.game?.players[0].currentRound.hand.addMods[4] == 1)
        #expect(reader.roundAvailability.remainingNumberCount(7) == 6)
        #expect(reader.roundAvailability.addModifiers[4] == 0)
    }

    @Test func endingGameClearsPersistedCurrentGameAndAvailability() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        #expect(defaults.data(forKey: "currentGame") != nil)

        vm.endGame()
        #expect(defaults.data(forKey: "currentGame") == nil)
        #expect(vm.roundAvailability == .empty)

        let reloaded = GameViewModel(defaults: defaults)
        #expect(reloaded.game == nil)
    }

    @Test func endRoundIsIdempotentWithoutPushingDuplicateUndoAndDuplicateRoundsStayUnique() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 50)
        let alice = vm.game!.players[0].id
        vm.setManualScoreOverride(alice, score: 60)

        vm.endRound()
        #expect(vm.game?.isCompletedWithWinner == true)
        let countAfterFirst = vm.game?.gameHistory.count
        let scoreAfterFirst = vm.game?.players[0].totalScore

        // Second call must be a no-op without pushing an extra undo entry.
        vm.endRound()
        #expect(vm.game?.gameHistory.count == countAfterFirst)
        #expect(vm.game?.players[0].totalScore == scoreAfterFirst)

        // Single undo must immediately restore the unfinalized round, and single redo restores completion.
        vm.undo()
        #expect(vm.game?.isCurrentRoundFinalized == false)
        #expect(vm.game?.isCompletedWithWinner == false)
        #expect(vm.game?.players[0].currentRound.manualScoreOverride == 60)

        vm.redo()
        #expect(vm.game?.isCompletedWithWinner == true)
        #expect(vm.game?.players[0].totalScore == 60)

        // Legacy decoded histories with repeated roundNumber still produce unique chart point IDs.
        var legacyGame = vm.game!
        if let firstRound = legacyGame.gameHistory.first {
            legacyGame.gameHistory.append(firstRound)
        }
        let stats = GameStats(game: legacyGame)
        let cumulativeIDs = stats.cumulativeChartData().map(\.id)
        #expect(Set(cumulativeIDs).count == cumulativeIDs.count)

        let barIDs = stats.roundScoreChartData(for: alice).map(\.id)
        #expect(Set(barIDs).count == barIDs.count)
    }

    @Test func loweringTargetMidRoundDoesNotPrematurelyCompleteGameBeforeFinalization() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        let alice = vm.game!.players[0].id
        let bob = vm.game!.players[1].id

        // Round 1: Alice banks 75, Bob banks 60.
        vm.setManualScoreOverride(alice, score: 75)
        vm.setManualScoreOverride(bob, score: 60)
        vm.startNewRound()

        // Round 2 in progress: Bob enters 30 unbanked points (would reach 90).
        vm.setManualScoreOverride(bob, score: 30)

        // Lower target to 75 mid-round: Alice meets target on banked total,
        // but round 2 is NOT finalized, so Game Over must NOT trigger yet.
        vm.updateTargetScore(75)
        #expect(vm.game?.hasWinner == true)
        #expect(vm.game?.isCompletedWithWinner == false)

        // Reload mid-round still preserves unfinalized state.
        let reloaded = GameViewModel(defaults: defaults)
        #expect(reloaded.game?.isCompletedWithWinner == false)
        #expect(reloaded.game?.players[1].currentRound.manualScoreOverride == 30)

        // Finalizing round 2 completes the game with Bob winning at 90.
        reloaded.endRound()
        #expect(reloaded.game?.isCompletedWithWinner == true)
        #expect(reloaded.game?.winners.map(\.name) == ["Bob"])
        #expect(reloaded.game?.players[1].totalScore == 90)
    }

    @Test func manualScoreOverrideIsIdempotentAndClearLeavesNil() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        let alice = vm.game!.players[0].id

        vm.setManualScoreOverride(alice, score: 42)
        // Setting the exact same value again must not push a duplicate undo step.
        vm.setManualScoreOverride(alice, score: 42)
        #expect(vm.game?.players[0].currentRound.manualScoreOverride == 42)

        vm.undo()
        #expect(vm.game?.players[0].currentRound.manualScoreOverride == nil)

        vm.redo()
        #expect(vm.game?.players[0].currentRound.manualScoreOverride == 42)

        vm.clearManualScoreOverride(alice)
        #expect(vm.game?.players[0].currentRound.manualScoreOverride == nil)
    }

    @Test func clearingModifierOnlyHandRestoresAvailabilityAndSupportsUndo() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        let alice = vm.game!.players[0].id

        vm.addModifierToPlayer(alice, value: 4)
        vm.addX2ToPlayer(alice)
        #expect(vm.game?.players[0].currentRound.hand.isEmpty == false)
        #expect(vm.roundAvailability.addModifiers[4] == 0)
        #expect(vm.roundAvailability.x2 == 0)

        vm.clearPlayerRoundEntry(alice)
        #expect(vm.game?.players[0].currentRound.hand.isEmpty == true)
        #expect(vm.roundAvailability.addModifiers[4] == 1)
        #expect(vm.roundAvailability.x2 == 1)

        vm.undo()
        #expect(vm.game?.players[0].currentRound.hand.addMods[4] == 1)
        #expect(vm.game?.players[0].currentRound.hand.x2Count == 1)
        #expect(vm.roundAvailability.x2 == 0)
    }

    @Test func semanticActionAndKeycapPairsMeetWCAGAAInLightAndDark() {
        let solidRoles: [DesignColor.Role] = [
            .brandPrimary,
            .brandSecondary,
            .stateSuccess,
            .stateFrozen,
            .stateWarning,
            .stateDanger
        ]

        for scheme in [ColorScheme.light, ColorScheme.dark] {
            for role in solidRoles {
                let fill = DesignColor.color(role, theme: .v2, colorScheme: scheme)
                let fg = fill.contrastingForeground
                let ratio = fill.contrastRatio(with: fg)
                #expect(
                    ratio >= 4.5,
                    "Expected WCAG AA (>= 4.5:1) for \(role) in \(scheme), got \(ratio)"
                )
            }

            // Unselected enabled keycaps (numbers & special cards) render textPrimary on surfaceKeycap.
            let keycapBg = DesignColor.color(.surfaceKeycap, theme: .v2, colorScheme: scheme)
            let keycapFg = DesignColor.color(.textPrimary, theme: .v2, colorScheme: scheme)
            let keycapRatio = keycapBg.contrastRatio(with: keycapFg)
            #expect(
                keycapRatio >= 4.5,
                "Expected WCAG AA (>= 4.5:1) for unselected keycap text in \(scheme), got \(keycapRatio)"
            )
        }
    }

    @Test func visualThemeMigrationPreservesSavedLegacyAndCustomAccents() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Case 1: Fresh install (no stored value, no migration flag) -> defaults to .v2.
        let freshTheme = VisualThemeMigration.migrateIfNeeded(defaults: defaults)
        #expect(freshTheme == .v2)
        #expect(defaults.string(forKey: VisualThemeMigration.themeKey) == VisualTheme.v2.rawValue)
        #expect(defaults.bool(forKey: VisualThemeMigration.migratedKey) == true)

        // Case 2: Existing user with "legacy" saved and migration flag absent -> preserves .legacy.
        defaults.removeObject(forKey: VisualThemeMigration.migratedKey)
        defaults.set(VisualTheme.legacy.rawValue, forKey: VisualThemeMigration.themeKey)
        let preserved = VisualThemeMigration.migrateIfNeeded(defaults: defaults)
        #expect(preserved == .legacy)
        #expect(defaults.string(forKey: VisualThemeMigration.themeKey) == VisualTheme.legacy.rawValue)

        // Custom accents stay active and distinct from plain appearance themes.
        #expect(AppTheme.midnight.hasCustomAccent)
        #expect(AppTheme.sunset.hasCustomAccent)
        #expect(AppTheme.forest.hasCustomAccent)
        #expect(AppTheme.ocean.hasCustomAccent)
        #expect(!AppTheme.system.hasCustomAccent)
        #expect(!AppTheme.light.hasCustomAccent)
        #expect(!AppTheme.dark.hasCustomAccent)
    }

    @Test func cumulativeChartDataPreservesDistinctSeriesForDuplicateNames() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        vm.startNewGame(players: ["Alex", "Alex"], targetScore: 200)
        let firstAlex = vm.game!.players[0].id
        let secondAlex = vm.game!.players[1].id

        vm.setManualScoreOverride(firstAlex, score: 30)
        vm.setManualScoreOverride(secondAlex, score: 50)
        vm.startNewRound()

        let stats = GameStats(game: vm.game!)
        let points = stats.cumulativeChartData()
        let firstSeries = points.filter { $0.playerId == firstAlex }
        let secondSeries = points.filter { $0.playerId == secondAlex }
        #expect(firstSeries.map(\.score) == [0, 30])
        #expect(secondSeries.map(\.score) == [0, 50])
        #expect(Set(points.map(\.id)).count == points.count)
    }

    @Test func eightPlayerTenRoundWorkflowMaintainsAvailabilityAndPrecomputedStats() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vm = GameViewModel(defaults: defaults)
        let names = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]
        vm.startNewGame(players: names, targetScore: 500)

        for _ in 0..<10 {
            for player in vm.game!.players {
                _ = vm.addCardToPlayer(player.id, number: 8)
                _ = vm.addCardToPlayer(player.id, number: 9)
                vm.bankPlayer(player.id)
            }
            vm.startNewRound()
        }

        let targetId = vm.game!.players[0].id
        defaults.resetCounters()
        for number in 1...7 {
            _ = vm.addCardToPlayer(targetId, number: number)
        }

        #expect(defaults.writeCount == 7)
        #expect(vm.game?.players[0].currentRound.hand.hasSevenCardBonus == true)

        let playerStats = PlayerGameStats(playerId: targetId, game: vm.game!)
        #expect(playerStats.roundResults.count == 10)
        #expect(playerStats.roundScores.count == 10)
        #expect(playerStats.totalScore == 170)
    }
}
