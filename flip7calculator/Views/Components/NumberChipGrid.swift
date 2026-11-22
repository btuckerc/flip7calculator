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
    var hasHandEntries: Bool = false
    let availability: RoundDeckAvailability
    let canEditCards: Bool
    let onTap: (Int) -> Void
    let onTapSpecialNumber: (SpecialNumberCard) -> Void

    // Manual score state
    let manualScoreOverride: Int?
    let autoScore: Int
    let isManualScoreEnabled: Bool
    let onSaveManualScore: (Int) -> Void
    let onClearManualScore: () -> Void
    let onClearRound: () -> Void
    let allowsNegativeManualScore: Bool

    @State private var showingScorePopover = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    private var chipHeight: CGFloat {
        horizontalSizeClass == .regular ? 58 : 44
    }

    private var hasManualOverride: Bool {
        manualScoreOverride != nil
    }

    private var hasSomethingToClear: Bool {
        hasHandEntries || !selectedNumbers.isEmpty || !selectedSpecialNumbers.isEmpty || hasManualOverride
    }

    private func isNumberEnabled(_ number: Int) -> Bool {
        guard canEditCards else { return false }
        if selectedNumbers.contains(number) { return true }
        return (availability.numbers[number] ?? 0) > 0
    }

    private func isSpecialEnabled(_ card: SpecialNumberCard) -> Bool {
        guard canEditCards else { return false }
        if selectedSpecialNumbers.contains(card) { return true }
        return (availability.specialNumbers[card] ?? 0) > 0
    }

    var body: some View {
        VStack(spacing: 6) {
            // Top row: edge card (1x) | wide Score button (2x) | Clear (1x)
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let totalSpacing = spacing * 3
                let unitWidth = max(0, (geo.size.width - totalSpacing) / 4)
                let edgeNumber = mode == .classic ? 0 : 13

                HStack(spacing: spacing) {
                    NumberChip(
                        number: edgeNumber,
                        isSelected: selectedNumbers.contains(edgeNumber),
                        isEnabled: isNumberEnabled(edgeNumber),
                        onTap: { onTap(edgeNumber) }
                    )
                    .frame(width: unitWidth)

                    ManualScoreSummaryButton(
                        hasOverride: hasManualOverride,
                        manualScore: manualScoreOverride,
                        autoScore: autoScore,
                        isEnabled: isManualScoreEnabled,
                        showingPopover: $showingScorePopover
                    )
                    .frame(width: unitWidth * 2 + spacing)
                    .sheet(isPresented: $showingScorePopover) {
                        ManualScoreSheetContent(
                            autoScore: autoScore,
                            currentManualScore: manualScoreOverride,
                            onSave: onSaveManualScore,
                            onClearManualScore: onClearManualScore,
                            allowsNegative: allowsNegativeManualScore,
                            onDismiss: { showingScorePopover = false }
                        )
                        .presentationDetents([.height(allowsNegativeManualScore ? 270 : 220)])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme))
                    }

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
            .frame(height: chipHeight)

            // Number rows 1-12 (3 rows of 4)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(1...12, id: \.self) { number in
                    NumberChip(
                        number: number,
                        isSelected: selectedNumbers.contains(number),
                        isEnabled: isNumberEnabled(number),
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
                            isEnabled: isSpecialEnabled(card),
                            onTap: { onTapSpecialNumber(card) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Manual Score Controls

struct ManualScoreSummaryButton: View {
    let hasOverride: Bool
    let manualScore: Int?
    let autoScore: Int
    let isEnabled: Bool
    @Binding var showingPopover: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var chipHeight: CGFloat {
        horizontalSizeClass == .regular ? 58 : 44
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
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
                Image(systemName: hasOverride ? "pencil.circle.fill" : "sparkles")
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 0) {
                    Text(displayValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(hasOverride ? "manual" : "round · tap to edit")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .opacity(hasOverride ? 0.85 : 0.72)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: chipHeight)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.96))
        .disabled(!isEnabled)
        .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: hasOverride)
        .accessibilityLabel("Round score \(displayValue)")
        .accessibilityValue(hasOverride ? "Manual override" : "Calculated from cards")
        .accessibilityHint("Double tap to enter a manual round score")
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.45)
        }
        return hasOverride ? accentColor.contrastingForeground : accentColor
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme).opacity(0.45)
        }
        return hasOverride ? accentColor : accentColor.opacity(colorScheme == .dark ? 0.16 : 0.12)
    }

    private var borderColor: Color {
        guard isEnabled else { return .clear }
        return accentColor.opacity(hasOverride ? 0.45 : 0.28)
    }
}

struct ManualScoreClearButton: View {
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var dangerColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    private var chipHeight: CGFloat {
        horizontalSizeClass == .regular ? 58 : 44
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isEnabled ? dangerColor : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.38))
                Text("Clear")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        isEnabled
                            ? DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
                            : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.38)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: chipHeight)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isEnabled
                            ? DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
                            : DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme).opacity(0.45)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isEnabled ? dangerColor.opacity(0.55) : Color.clear, lineWidth: 1.25)
            )
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.94))
        .disabled(!isEnabled)
        .accessibilityLabel("Clear round cards")
    }
}

// MARK: - Number Chip

struct NumberChip: View {
    let number: Int
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @ScaledMetric(relativeTo: .body) private var compactFontSize: CGFloat = 17
    @ScaledMetric(relativeTo: .title3) private var regularFontSize: CGFloat = 20

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var chipFontSize: CGFloat {
        horizontalSizeClass == .regular ? min(regularFontSize, 28) : min(compactFontSize, 24)
    }

    private var chipHeight: CGFloat {
        horizontalSizeClass == .regular ? 58 : 44
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var keycapFill: Color {
        if isSelected {
            return accentColor
        }
        return DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
            .opacity(isEnabled ? 1 : 0.42)
    }

    private var keycapBorder: Color {
        if isSelected {
            return accentColor.opacity(0.45)
        }
        if !isEnabled {
            return Color.clear
        }
        return DesignColor.keycapBorder(theme: visualTheme, colorScheme: colorScheme)
    }

    private var foregroundColor: Color {
        if isSelected {
            return accentColor.contrastingForeground
        }
        if isEnabled {
            return DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
        }
        return DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.38)
    }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            HapticFeedback.light()
            onTap()
        }) {
            Text("\(number)")
                .font(.system(size: chipFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: chipHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(keycapFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(keycapBorder, lineWidth: 1)
                )
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.94))
        .disabled(!isEnabled)
        .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: isSelected)
        .accessibilityLabel("Number \(number)")
        .accessibilityValue(isSelected ? "Selected" : (isEnabled ? "Available" : "Unavailable"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SpecialNumberChip: View {
    let card: SpecialNumberCard
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @ScaledMetric(relativeTo: .subheadline) private var shortLabelSize: CGFloat = 15
    @ScaledMetric(relativeTo: .caption2) private var detailLabelSize: CGFloat = 8.5

    private var accentColor: Color {
        switch card {
        case .zero: return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        case .unluckySeven: return DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
        case .luckyThirteen: return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
        }
    }

    private var chipHeight: CGFloat {
        horizontalSizeClass == .regular ? 58 : 44
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        Button {
            guard isEnabled else { return }
            HapticFeedback.light()
            onTap()
        } label: {
            VStack(spacing: 1) {
                Text(card.shortLabel)
                    .font(.system(size: min(horizontalSizeClass == .regular ? shortLabelSize + 2 : shortLabelSize, 20), weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(card.displayName)
                    .font(.system(size: min(horizontalSizeClass == .regular ? detailLabelSize + 1 : detailLabelSize, 12), weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(
                isSelected
                    ? accentColor.contrastingForeground
                    : (isEnabled
                        ? DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
                        : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.4))
            )
            .frame(maxWidth: .infinity)
            .frame(height: chipHeight)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? accentColor
                            : DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme).opacity(isEnabled ? 1 : 0.42)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accentColor.opacity(isEnabled ? 0.52 : 0.08), lineWidth: isSelected ? 1 : 1.25)
            )
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.94))
        .disabled(!isEnabled)
        .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: isSelected)
        .accessibilityLabel(card.displayName)
        .accessibilityValue(isSelected ? "Selected" : (isEnabled ? "Available" : "Unavailable"))
        .accessibilityHint(card.effectSummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
