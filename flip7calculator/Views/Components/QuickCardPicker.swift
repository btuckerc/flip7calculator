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
                    isEnabled: isNumberEnabled
                )
            }
            
            // Modifiers section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Modifiers")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Hold to remove")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                
                ModifierGrid(
                    addMods: player.currentRound.hand.addMods,
                    x2Count: player.currentRound.hand.x2Count,
                    onTapModifier: onIncrementModifier,
                    onLongPressModifier: onDecrementModifier,
                    onTapX2: onIncrementX2,
                    onLongPressX2: onDecrementX2,
                    isModifierEnabled: isModifierEnabled,
                    isX2Enabled: isX2Enabled
                )
            }
        }
        .padding(.vertical, 4)
    }
}
