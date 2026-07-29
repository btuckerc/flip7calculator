//
//  OptionChips.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct OptionChips<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    let selectedOption: T
    let onSelect: (T) -> Void
    let labelForOption: (T) -> String
    let iconForOption: (T) -> String
    let colorForOption: ((T) -> Color)?
    let previewColorsForOption: ((T) -> [Color])?
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        options: [T],
        selectedOption: T,
        onSelect: @escaping (T) -> Void,
        labelForOption: @escaping (T) -> String,
        iconForOption: @escaping (T) -> String,
        colorForOption: ((T) -> Color)? = nil,
        previewColorsForOption: ((T) -> [Color])? = nil
    ) {
        self.options = options
        self.selectedOption = selectedOption
        self.onSelect = onSelect
        self.labelForOption = labelForOption
        self.iconForOption = iconForOption
        self.colorForOption = colorForOption
        self.previewColorsForOption = previewColorsForOption
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.rawValue) { option in
                    OptionChip(
                        option: option,
                        isSelected: option == selectedOption,
                        label: labelForOption(option),
                        icon: iconForOption(option),
                        color: colorForOption?(option),
                        previewColors: previewColorsForOption?(option),
                        onTap: {
                            HapticFeedback.light()
                            onSelect(option)
                        }
                    )
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppBrandPalette.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            .padding(.horizontal, 2)
        }
    }
}

struct OptionChip: View {
    let option: Any
    let isSelected: Bool
    let label: String
    let icon: String
    let color: Color?
    let previewColors: [Color]?
    let onTap: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        color ?? DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var chipFill: Color {
        if visualTheme == .v2 {
            return isSelected
                ? accentColor.opacity(colorScheme == .dark ? 0.24 : 0.16)
                : DesignColor.color(.surfaceInteractive, theme: visualTheme, colorScheme: colorScheme)
        }

        return isSelected ? accentColor.opacity(0.15) : Color(.systemGray6)
    }

    private var chipStroke: Color {
        if visualTheme == .v2 {
            return isSelected
                ? accentColor.opacity(colorScheme == .dark ? 0.48 : 0.30)
                : AppBrandPalette.cardBorder(colorScheme: colorScheme)
        }

        return isSelected ? accentColor.opacity(0.4) : .clear
    }

    private var primaryText: Color {
        DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
    }
    
    var body: some View {
        Button(action: onTap) {
            if let previewColors = previewColors, !previewColors.isEmpty {
                // Vertical layout for palette options: label on top, swatches below
                VStack(spacing: 6) {
                    // Top row: Label and checkmark
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(isSelected ? primaryText : secondaryText)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    }
                    
                    // Bottom row: Color swatches
                    HStack(spacing: 3) {
                        ForEach(Array(previewColors.prefix(6).enumerated()), id: \.offset) { _, color in
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                // Horizontal layout for theme options: icon + label + checkmark
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? accentColor : (color ?? secondaryText))
                        .frame(width: 24, height: 24)
                    
                    Text(label)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(isSelected ? primaryText : secondaryText)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(chipFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(chipStroke, lineWidth: isSelected ? 1.5 : 1)
        )
        .shadow(
            color: accentColor.opacity(isSelected ? 0.12 : 0),
            radius: isSelected ? 8 : 0,
            y: isSelected ? 4 : 0
        )
        .buttonStyle(.plain)
    }
}
