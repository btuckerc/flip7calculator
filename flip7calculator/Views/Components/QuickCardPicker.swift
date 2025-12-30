//
//  QuickCardPicker.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct QuickCardPicker: View {
    let player: Player
    let onTapNumber: (Int) -> Void
    let onIncrementModifier: (Int) -> Void
    let onDecrementModifier: (Int) -> Void
    let onIncrementX2: () -> Void
    let onDecrementX2: () -> Void
    let showingBustBanner: Bool
    let bustNumber: Int?
    let onConfirmBust: () -> Void
    let onUndoBust: () -> Void
    let isNumberEnabled: (Int) -> Bool
    let isModifierEnabled: (Int) -> Bool
    let isX2Enabled: Bool
    
    // Manual score
    let isManualScoreEnabled: Bool
    let onSaveManualScore: (Int) -> Void
    let onClearManualScore: () -> Void  // Clears only manual override (keeps cards/modifiers)
    let onClearRound: () -> Void  // Clears entire round (cards + modifiers + manual)
    
    // Deck configuration
    let hasOnlyOneOfEachModifier: Bool  // True when deck has ≤1 of each modifier and ≤1 x2
    
    /// Auto score computed from cards (ignoring manual override)
    private var autoScore: Int {
        ScoreEngine.calculateAutoScore(hand: player.currentRound.hand, state: player.currentRound.state)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Bust banner (if applicable)
            if showingBustBanner, let bustNumber = bustNumber {
                InlineBustBanner(
                    duplicateNumber: bustNumber,
                    onConfirmBust: onConfirmBust,
                    onUndo: onUndoBust
                )
            }
            
            // Numbers section
            VStack(alignment: .leading, spacing: 4) {
                Text("Numbers")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                
                NumberChipGrid(
                    selectedNumbers: player.currentRound.hand.selectedNumbers,
                    onTap: onTapNumber,
                    isEnabled: isNumberEnabled,
                    manualScoreOverride: player.currentRound.manualScoreOverride,
                    autoScore: autoScore,
                    isManualScoreEnabled: isManualScoreEnabled,
                    onSaveManualScore: onSaveManualScore,
                    onClearManualScore: onClearManualScore,
                    onClearRound: onClearRound
                )
            }
            
            // Modifiers section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Modifiers")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Only show "Hold to remove" hint when deck has multiple of at least one modifier
                    if !hasOnlyOneOfEachModifier {
                        Text("Hold to remove")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                ModifierGrid(
                    addMods: player.currentRound.hand.addMods,
                    x2Count: player.currentRound.hand.x2Count,
                    onTapModifier: onIncrementModifier,
                    onLongPressModifier: onDecrementModifier,
                    onTapX2: onIncrementX2,
                    onLongPressX2: onDecrementX2,
                    isModifierEnabled: isModifierEnabled,
                    isX2Enabled: isX2Enabled,
                    showCountBadges: !hasOnlyOneOfEachModifier
                )
            }
        }
        .padding(.vertical, 4)
    }
}
