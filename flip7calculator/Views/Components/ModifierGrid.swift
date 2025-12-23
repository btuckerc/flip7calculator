//
//  ModifierGrid.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct ModifierGrid: View {
    let addMods: [Int: Int]
    let x2Count: Int
    let onTapModifier: (Int) -> Void
    let onLongPressModifier: (Int) -> Void
    let onTapX2: () -> Void
    let onLongPressX2: () -> Void
    let isModifierEnabled: (Int) -> Bool
    let isX2Enabled: Bool
    
    // 6 columns - all modifiers in a single row
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            // Additive modifiers
            ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                ModifierTile(
                    label: "+\(value)",
                    count: addMods[value] ?? 0,
                    color: .green,
                    isEnabled: isModifierEnabled(value),
                    onTap: { onTapModifier(value) },
                    onLongPress: { onLongPressModifier(value) }
                )
            }
            
            // x2 multiplier
            ModifierTile(
                label: "×2",
                count: x2Count,
                color: .purple,
                isEnabled: isX2Enabled,
                onTap: onTapX2,
                onLongPress: onLongPressX2
            )
        }
    }
}

struct ModifierTile: View {
    let label: String
    let count: Int
    let color: Color
    let isEnabled: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var longPressTriggered = false
    @State private var pressStartTime: Date?
    
    private let longPressDuration: TimeInterval = 0.35
    
    var body: some View {
        ZStack {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(count > 0 ? .white : (isEnabled ? .primary : .secondary))
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.8))
                    )
                    .offset(x: 14, y: -12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(count > 0 ? color : (isEnabled ? Color(.systemGray5) : Color(.systemGray6)))
        )
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: count)
        .animation(.spring(response: 0.1, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isEnabled)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard isEnabled else { return }
                    if !isPressed {
                        isPressed = true
                        longPressTriggered = false
                        pressStartTime = Date()
                        
                        // Schedule long press check
                        DispatchQueue.main.asyncAfter(deadline: .now() + longPressDuration) {
                            if isPressed, let startTime = pressStartTime,
                               Date().timeIntervalSince(startTime) >= longPressDuration {
                                longPressTriggered = true
                                HapticFeedback.medium()
                                onLongPress()
                            }
                        }
                    }
                }
                .onEnded { _ in
                    guard isEnabled else {
                        isPressed = false
                        pressStartTime = nil
                        return
                    }
                    if !longPressTriggered {
                        // It was a tap
                        HapticFeedback.light()
                        onTap()
                    }
                    isPressed = false
                    pressStartTime = nil
                }
        )
    }
}

