//
//  ProbabilityService.swift
//  flip7calculator
//

import Foundation

enum RiskInsightsMode: String, CaseIterable, Identifiable {
    case off
    case heat
    case percentage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off (Default)"
        case .heat: return "Heat only"
        case .percentage: return "Percentage"
        }
    }
}

enum RiskConfidence: Equatable {
    case exactDigitalDeck
    case estimateCurrentTable

    var shortLabel: String {
        switch self {
        case .exactDigitalDeck: return "Exact"
        case .estimateCurrentTable: return "Estimate"
        }
    }
}

struct RiskInsight: Equatable {
    let unsafeCardCount: Int
    let totalCardCount: Int
    let dangerousNumberCounts: [Int: Int]
    let confidence: RiskConfidence

    var probability: Double {
        guard totalCardCount > 0 else { return 0 }
        return Double(unsafeCardCount) / Double(totalCardCount)
    }

    var percentage: Int {
        Int((probability * 100).rounded())
    }

    var heatLabel: String {
        switch probability {
        case ..<0.10: return "Low risk"
        case ..<0.25: return "Rising risk"
        case ..<0.40: return "High risk"
        default: return "Critical risk"
        }
    }

    func compactLabel(mode: RiskInsightsMode) -> String {
        switch mode {
        case .off:
            return ""
        case .heat:
            return confidence == .exactDigitalDeck
                ? "\(heatLabel) · Exact"
                : "\(heatLabel.replacingOccurrences(of: " risk", with: " duplicate risk")) · Estimate"
        case .percentage:
            return confidence == .exactDigitalDeck
                ? "\(percentage)% next-card risk · Exact"
                : "\(percentage)% duplicate risk · Estimate"
        }
    }

    var accessibilityMetricLabel: String {
        confidence == .exactDigitalDeck ? "Next-card bust risk" : "Next-card duplicate risk"
    }
}

struct ProbabilityService {
    static func calculatorEstimate(for playerID: UUID, in game: Game) -> RiskInsight? {
        guard game.scoringRules.mode == .classic,
              let player = game.players.first(where: { $0.id == playerID }) else {
            return nil
        }

        var remainingNumbers = game.deckProfile.numberCardCounts
        var totalRemaining = game.deckProfile.totalCardCount

        for tablePlayer in game.players {
            for number in tablePlayer.currentRound.hand.selectedNumbers {
                remainingNumbers[number] = max(0, (remainingNumbers[number] ?? 0) - 1)
                totalRemaining -= 1
            }
            totalRemaining -= tablePlayer.currentRound.hand.addMods.values.reduce(0, +)
            totalRemaining -= tablePlayer.currentRound.hand.x2Count
        }

        totalRemaining = max(0, totalRemaining)
        let dangerous = Dictionary(uniqueKeysWithValues: player.currentRound.hand.selectedNumbers.sorted().map {
            ($0, max(0, remainingNumbers[$0] ?? 0))
        }).filter { $0.value > 0 }
        let unsafeCount = dangerous.values.reduce(0, +)

        return RiskInsight(
            unsafeCardCount: min(unsafeCount, totalRemaining),
            totalCardCount: totalRemaining,
            dangerousNumberCounts: dangerous,
            confidence: .estimateCurrentTable
        )
    }

    static func exactDigitalRisk(for playerID: UUID, in game: Game) -> RiskInsight? {
        guard let session = game.liveSession,
              let player = game.players.first(where: { $0.id == playerID }) else {
            return nil
        }

        let effectivePile = session.drawPile.isEmpty ? session.discardPile : session.drawPile
        guard !effectivePile.isEmpty else { return nil }

        let hasShield = session.hasShield(playerID: playerID)
        var dangerous: [Int: Int] = [:]
        if !hasShield {
            for card in effectivePile {
                guard case .number(let number) = card.content,
                      player.currentRound.hand.selectedNumbers.contains(number) else {
                    continue
                }
                dangerous[number, default: 0] += 1
            }
        }

        return RiskInsight(
            unsafeCardCount: dangerous.values.reduce(0, +),
            totalCardCount: effectivePile.count,
            dangerousNumberCounts: dangerous,
            confidence: .exactDigitalDeck
        )
    }
}
