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
    let usesBorderlessStyle: Bool
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
        fillsAvailableWidth: Bool = false,
        usesBorderlessStyle: Bool = false
    ) {
        self.options = options
        self.selectedOption = selectedOption
        self.onSelect = onSelect
        self.labelForOption = labelForOption
        self.iconForOption = iconForOption
        self.colorForOption = colorForOption
        self.previewColorsForOption = previewColorsForOption
        self.fillsAvailableWidth = fillsAvailableWidth
        self.usesBorderlessStyle = usesBorderlessStyle
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
                        repeating: GridItem(.flexible(), spacing: 8),
                        count: max(options.count, 1)
                    ),
                    spacing: 8
                ) {
                    optionChips
                }
            } else {
                HStack(spacing: 8) {
                    optionChips
                }
            }
        }
        .padding(8)
        .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.35),
                    lineWidth: 1
                )
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
                usesBorderlessStyle: usesBorderlessStyle,
                onTap: {
                    HapticFeedback.selection()
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
    var usesBorderlessStyle: Bool = false
    let onTap: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        color ?? DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var chipFill: Color {
        isSelected
            ? accentColor.opacity(colorScheme == .dark ? 0.24 : 0.14)
            : DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
    }

    private var chipStroke: Color {
        if isSelected {
            return accentColor.opacity(colorScheme == .dark ? 0.56 : 0.36)
        }
        return visualTheme == .v2 ? AppBrandPalette.keycapBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.4)
    }

    private var primaryText: Color {
        DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var chipHeight: CGFloat {
        previewColors?.isEmpty == false ? 56 : 40
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

    @ViewBuilder
    private func chipButton(width: CGFloat?) -> some View {
        let baseButton = Button(action: onTap) {
            chipLabel(width: width)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(chipFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(chipStroke, lineWidth: isSelected ? 1.5 : 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if usesBorderlessStyle {
            baseButton.buttonStyle(.borderless)
        } else {
            baseButton.buttonStyle(KeycapButtonStyle(pressedScale: 0.97))
        }
    }

    @ViewBuilder
    private func chipLabel(width: CGFloat?) -> some View {
        if let previewColors, !previewColors.isEmpty {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .medium))
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? accentColor : (color ?? secondaryText))
                    .frame(width: 20, height: 20)

                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: isSelected ? .semibold : .medium))
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
