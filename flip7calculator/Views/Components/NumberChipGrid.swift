//
//  NumberChipGrid.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct NumberChipGrid: View {
    let mode: GameMode
    let selectedNumbers: Set<Int>
    let selectedSpecialNumbers: Set<SpecialNumberCard>
    let onTap: (Int) -> Void
    let onTapSpecialNumber: (SpecialNumberCard) -> Void
    let isEnabled: (Int) -> Bool
    let isSpecialNumberEnabled: (SpecialNumberCard) -> Bool
    
    // Manual score state
    let manualScoreOverride: Int?
    let autoScore: Int
    let isManualScoreEnabled: Bool
    let onSaveManualScore: (Int) -> Void
    let onClearManualScore: () -> Void  // Clears only manual override (keeps cards/modifiers)
    let onClearRound: () -> Void  // Clears entire round (cards + modifiers + manual)
    let allowsNegativeManualScore: Bool
    
    @State private var showingScorePopover = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    // 4 columns for number rows 1-12
    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]
    
    private var hasManualOverride: Bool {
        manualScoreOverride != nil
    }
    
    /// Check if there's anything to clear (cards selected or manual override)
    private var hasSomethingToClear: Bool {
        !selectedNumbers.isEmpty || !selectedSpecialNumbers.isEmpty || hasManualOverride
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Top row: 0 (1x) | wide Score button (2x) | Clear (1x)
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let totalSpacing = spacing * 3 // 3 gaps between 4 "units"
                let unitWidth = max(0, (geo.size.width - totalSpacing) / 4)
                
                HStack(spacing: spacing) {
                    // Keep the irregular edge card beside the score control.
                    let edgeNumber = mode == .classic ? 0 : 13
                    NumberChip(
                        number: edgeNumber,
                        isSelected: selectedNumbers.contains(edgeNumber),
                        isEnabled: isEnabled(edgeNumber),
                        onTap: { onTap(edgeNumber) }
                    )
                    .frame(width: unitWidth)
                    
                    // Combined wide Score button (2 units)
                    ManualScoreSummaryButton(
                        hasOverride: hasManualOverride,
                        manualScore: manualScoreOverride,
                        autoScore: autoScore,
                        isEnabled: isManualScoreEnabled,
                        showingPopover: $showingScorePopover
                    )
                    .frame(width: unitWidth * 2 + spacing) // 2 units + 1 gap
                    .sheet(isPresented: $showingScorePopover) {
                        ManualScoreSheetContent(
                            autoScore: autoScore,
                            currentManualScore: manualScoreOverride,
                            onSave: { score in
                                onSaveManualScore(score)
                            },
                            onClearManualScore: {
                                onClearManualScore()
                            },
                            allowsNegative: allowsNegativeManualScore,
                            onDismiss: {
                                showingScorePopover = false
                            }
                        )
                        .presentationDetents([.height(allowsNegativeManualScore ? 270 : 220)])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme))
                    }
                    
                    // Clear Button (1 unit)
                    ManualScoreClearButton(
                        isEnabled: hasSomethingToClear && isManualScoreEnabled,
                        action: {
                            HapticFeedback.light()
                            onClearRound()
                        }
                    )
                    .frame(width: unitWidth)
                }
            }
            .frame(height: 44) // Fixed height for the top row
            
            // Number rows 1-12 (3 rows of 4)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(1...12, id: \.self) { number in
                    NumberChip(
                        number: number,
                        isSelected: selectedNumbers.contains(number),
                        isEnabled: isEnabled(number),
                        onTap: { onTap(number) }
                    )
                }
            }

            if mode == .vengeance {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                    spacing: 6
                ) {
                    ForEach(SpecialNumberCard.allCases) { card in
                        SpecialNumberChip(
                            card: card,
                            isSelected: selectedSpecialNumbers.contains(card),
                            isEnabled: isSpecialNumberEnabled(card),
                            onTap: { onTapSpecialNumber(card) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Manual Score Controls

/// Combined wide Score button that shows calculated score from cards or manual value
struct ManualScoreSummaryButton: View {
    let hasOverride: Bool
    let manualScore: Int?
    let autoScore: Int
    let isEnabled: Bool
    @Binding var showingPopover: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isPressed = false
    
    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
    }
    
    private var displayValue: String {
        if let manual = manualScore {
            return "\(manual)"
        }
        return "\(autoScore)"
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            HapticFeedback.light()
            showingPopover = true
        }) {
            HStack(spacing: 6) {
                // Icon
                Image(systemName: hasOverride ? "pencil.circle.fill" : "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                
                // Value/label
                VStack(alignment: .leading, spacing: 0) {
                    Text(displayValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    if hasOverride {
                        Text("manual")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .opacity(0.8)
                    } else {
                        Text("from cards · tap to edit")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .opacity(0.7)
                    }
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor.opacity(hasOverride ? 0.3 : (isEnabled ? 0.2 : 0)), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: hasOverride)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isEnabled)
        .animation(.spring(response: 0.1, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var foregroundColor: Color {
        if !isEnabled {
            return hasOverride ? .white.opacity(0.6) : accentColor.opacity(0.4)
        }
        return hasOverride ? .white : accentColor
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return hasOverride ? accentColor.opacity(0.35) : DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme)
        }
        return hasOverride ? accentColor : accentColor.opacity(0.15)
    }
}

struct ManualScoreClearButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("Clear")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isEnabled ? accentColor : accentColor.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled ? accentColor.opacity(0.15) : DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEnabled ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isEnabled)
        .animation(.spring(response: 0.1, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Number Chip

struct NumberChip: View {
    let number: Int
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            HapticFeedback.light()
            onTap()
        }) {
            Text("\(number)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : (isEnabled ? .primary : .secondary))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isSelected
                                ? accentColor
                                : (isEnabled
                                    ? DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme)
                                    : DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.78))
                        )
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.1, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SpecialNumberChip: View {
    let card: SpecialNumberCard
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        switch card {
        case .zero: return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        case .unluckySeven: return DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
        case .luckyThirteen: return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
        }
    }

    var body: some View {
        Button {
            guard isEnabled else { return }
            HapticFeedback.light()
            onTap()
        } label: {
            VStack(spacing: 1) {
                Text(card.shortLabel)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Text(card.displayName)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? .white : (isEnabled ? accentColor : .secondary))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected
                            ? accentColor
                            : DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor.opacity(isEnabled ? 0.28 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(card.displayName)
        .accessibilityHint(card.effectSummary)
    }
}
