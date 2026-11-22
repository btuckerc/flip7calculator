//
//  QuickCardPicker.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct QuickCardPicker: View {
    let player: Player
    let scoringRules: ScoringRules
    let availability: RoundDeckAvailability
    let canEditCards: Bool
    let canEditVengeanceModifiers: Bool
    let onTapNumber: (Int) -> Void
    let onTapSpecialNumber: (SpecialNumberCard) -> Void
    let onIncrementModifier: (Int) -> Void
    let onDecrementModifier: (Int) -> Void
    let onIncrementX2: () -> Void
    let onDecrementX2: () -> Void
    let onIncrementSubtractModifier: (Int) -> Void
    let onDecrementSubtractModifier: (Int) -> Void
    let onIncrementDivideByTwo: () -> Void
    let onDecrementDivideByTwo: () -> Void
    let showingBustBanner: Bool
    let bustNumber: Int?
    let onConfirmBust: () -> Void
    let onUndoBust: () -> Void

    // Manual score
    let isManualScoreEnabled: Bool
    let onSaveManualScore: (Int) -> Void
    let onClearManualScore: () -> Void
    let onClearRound: () -> Void

    // Deck configuration
    let hasOnlyOneOfEachModifier: Bool

    private var autoScore: Int {
        ScoreEngine.calculateAutoScore(round: player.currentRound, rules: scoringRules)
    }

    var body: some View {
        VStack(spacing: 8) {
            if showingBustBanner, let bustNumber = bustNumber {
                InlineBustBanner(
                    duplicateNumber: bustNumber,
                    onConfirmBust: onConfirmBust,
                    onUndo: onUndoBust
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Numbers")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                NumberChipGrid(
                    mode: scoringRules.mode,
                    selectedNumbers: player.currentRound.hand.selectedNumbers,
                    selectedSpecialNumbers: player.currentRound.hand.specialNumbers,
                    hasHandEntries: !player.currentRound.hand.isEmpty,
                    availability: availability,
                    canEditCards: canEditCards,
                    onTap: onTapNumber,
                    onTapSpecialNumber: onTapSpecialNumber,
                    manualScoreOverride: player.currentRound.manualScoreOverride,
                    autoScore: autoScore,
                    isManualScoreEnabled: isManualScoreEnabled,
                    onSaveManualScore: onSaveManualScore,
                    onClearManualScore: onClearManualScore,
                    onClearRound: onClearRound,
                    allowsNegativeManualScore: scoringRules.brutalMode
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Modifiers")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    if !hasOnlyOneOfEachModifier {
                        Text("Hold to remove")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }

                ModifierGrid(
                    mode: scoringRules.mode,
                    addMods: player.currentRound.hand.addMods,
                    x2Count: player.currentRound.hand.x2Count,
                    subtractMods: player.currentRound.hand.subtractMods,
                    divideByTwoCount: player.currentRound.hand.divideByTwoCount,
                    availability: availability,
                    canEditClassicModifiers: canEditCards,
                    canEditVengeanceModifiers: canEditVengeanceModifiers,
                    onTapModifier: onIncrementModifier,
                    onLongPressModifier: onDecrementModifier,
                    onTapX2: onIncrementX2,
                    onLongPressX2: onDecrementX2,
                    onTapSubtractModifier: onIncrementSubtractModifier,
                    onLongPressSubtractModifier: onDecrementSubtractModifier,
                    onTapDivideByTwo: onIncrementDivideByTwo,
                    onLongPressDivideByTwo: onDecrementDivideByTwo,
                    showCountBadges: !hasOnlyOneOfEachModifier
                )
            }
        }
        .padding(.vertical, 2)
    }
}
