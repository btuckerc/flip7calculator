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
    
    // 7 columns to fit 0-12 in 2 rows (7 + 6)
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0...12, id: \.self) { number in
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
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : (isEnabled ? .primary : .secondary))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
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
