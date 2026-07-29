//
//  GameFlow.swift
//  flip7calculator
//
//  Small pure helpers for player selection and round progress.
//

import Foundation

enum GameFlow {
    static func nextInRoundPlayerId(from currentId: UUID?, players: [Player]) -> UUID? {
        let inRoundPlayers = players.filter { $0.currentRound.state == .inRound }

        guard !inRoundPlayers.isEmpty else { return nil }

        guard let currentId,
              let currentIndex = players.firstIndex(where: { $0.id == currentId }) else {
            return inRoundPlayers.first?.id
        }

        let wrappedPlayers = Array(players.dropFirst(currentIndex + 1)) + Array(players.prefix(currentIndex + 1))
        return wrappedPlayers.first(where: { $0.currentRound.state == .inRound })?.id
            ?? inRoundPlayers.first?.id
    }

    static func preferredSelection(in game: Game, currentSelection: UUID?) -> UUID? {
        if let currentSelection,
           let player = game.players.first(where: { $0.id == currentSelection }),
           player.currentRound.state == .inRound {
            return currentSelection
        }

        return nextInRoundPlayerId(from: currentSelection, players: game.players)
    }

    static func leadingPlayerIds(in game: Game) -> Set<UUID> {
        let maxScore = game.players.map(\.totalScore).max() ?? 0
        return Set(game.players.filter { $0.totalScore == maxScore }.map(\.id))
    }

    static func inRoundCount(in game: Game) -> Int {
        game.players.filter { $0.currentRound.state == .inRound }.count
    }

    static func selectedProgress(for player: Player, targetScore: Int) -> Double {
        guard targetScore > 0 else { return 0 }
        return min(Double(player.totalScore) / Double(targetScore), 1.0)
    }
}
