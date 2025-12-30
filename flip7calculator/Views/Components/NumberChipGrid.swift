//
//  NumberChipGrid.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct NumberChipGrid: View {
    let selectedNumbers: Set<Int>
    let onTap: (Int) -> Void
    let isEnabled: (Int) -> Bool
    
    // Manual score state
    let manualScoreOverride: Int?
    let autoScore: Int
    let isManualScoreEnabled: Bool
    let onSaveManualScore: (Int) -> Void
    let onClearManualScore: () -> Void  // Clears only manual override (keeps cards/modifiers)
    let onClearRound: () -> Void  // Clears entire round (cards + modifiers + manual)
    
    @State private var showingScorePopover = false
    
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
        !selectedNumbers.isEmpty || hasManualOverride
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Top row: 0 (1x) | wide Score button (2x) | Clear (1x)
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let totalSpacing = spacing * 3 // 3 gaps between 4 "units"
                let unitWidth = (geo.size.width - totalSpacing) / 4
                
                HStack(spacing: spacing) {
                    // Number 0 chip (1 unit)
                    NumberChip(
                        number: 0,
                        isSelected: selectedNumbers.contains(0),
                        isEnabled: isEnabled(0),
                        onTap: { onTap(0) }
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
                            onDismiss: {
                                showingScorePopover = false
                            }
                        )
                        .presentationDetents([.height(220)])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(Color(.systemBackground))
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
    
    @State private var isPressed = false
    
    private var accentColor: Color { .blue }
    
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
            return hasOverride ? accentColor.opacity(0.5) : Color(.systemGray6)
        }
        return hasOverride ? accentColor : accentColor.opacity(0.15)
    }
}

struct ManualScoreClearButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var accentColor: Color { .red }
    
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
                    .fill(isEnabled ? accentColor.opacity(0.15) : Color(.systemGray6))
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
                        .fill(isSelected ? Color.blue : (isEnabled ? Color(.systemGray5) : Color(.systemGray6)))
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
