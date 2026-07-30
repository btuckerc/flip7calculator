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
    let fillsAvailableWidth: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        options: [T],
        selectedOption: T,
        onSelect: @escaping (T) -> Void,
        labelForOption: @escaping (T) -> String,
        iconForOption: @escaping (T) -> String,
        colorForOption: ((T) -> Color)? = nil,
        previewColorsForOption: ((T) -> [Color])? = nil,
        fillsAvailableWidth: Bool = false
    ) {
        self.options = options
        self.selectedOption = selectedOption
        self.onSelect = onSelect
        self.labelForOption = labelForOption
        self.iconForOption = iconForOption
        self.colorForOption = colorForOption
        self.previewColorsForOption = previewColorsForOption
        self.fillsAvailableWidth = fillsAvailableWidth
    }
    
    var body: some View {
        Group {
            if fillsAvailableWidth {
                chipRow
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    chipRow
                }
            }
        }
    }

    private var chipRow: some View {
        Group {
            if fillsAvailableWidth {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 10),
                        count: max(options.count, 1)
                    ),
                    spacing: 10
                ) {
                    optionChips
                }
            } else {
                HStack(spacing: 10) {
                    optionChips
                }
            }
        }
        .padding(10)
        .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
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

    @ViewBuilder
    private var optionChips: some View {
        ForEach(options, id: \.rawValue) { option in
            OptionChip(
                option: option,
                isSelected: option == selectedOption,
                label: labelForOption(option),
                icon: iconForOption(option),
                color: colorForOption?(option),
                previewColors: previewColorsForOption?(option),
                fillsAvailableWidth: fillsAvailableWidth,
                onTap: {
                    HapticFeedback.light()
                    onSelect(option)
                }
            )
            .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
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
    let fillsAvailableWidth: Bool
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

    private var chipHeight: CGFloat {
        previewColors?.isEmpty == false ? 58 : 40
    }
    
    var body: some View {
        Group {
            if fillsAvailableWidth {
                GeometryReader { geometry in
                    chipButton(width: max(0, geometry.size.width))
                }
                .frame(height: chipHeight)
            } else {
                chipButton(width: nil)
            }
        }
    }

    private func chipButton(width: CGFloat?) -> some View {
        Button(action: onTap) {
            chipLabel(width: width)
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
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func chipLabel(width: CGFloat?) -> some View {
        if let previewColors = previewColors, !previewColors.isEmpty {
            VStack(spacing: 6) {
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

                HStack(spacing: 3) {
                    ForEach(Array(previewColors.prefix(6).enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, width == nil ? 12 : 0)
            .padding(.vertical, 8)
            .frame(width: width)
        } else {
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
            .padding(.horizontal, width == nil ? 12 : 0)
            .padding(.vertical, 8)
            .frame(width: width)
        }
    }
}
