//
//  TargetScoreEditorSheet.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct TargetScoreEditorSheet: View {
    @Binding var targetScore: Int
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    @State private var inputText: String
    @FocusState private var isTextFieldFocused: Bool

    private let minScore = 50
    private let maxScore = 5000
    private let defaultScore = 200

    init(targetScore: Binding<Int>, onSave: @escaping (Int) -> Void) {
        self._targetScore = targetScore
        self.onSave = onSave
        self._inputText = State(initialValue: "\(targetScore.wrappedValue)")
    }

    private var clampedScore: Int {
        let value = Int(inputText) ?? minScore
        return max(minScore, min(maxScore, value))
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text("Enter target score")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    .padding(.top, 8)

                TextField("", text: $inputText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isTextFieldFocused ? accentColor : DesignColor.keycapBorder(theme: visualTheme, colorScheme: colorScheme),
                                lineWidth: isTextFieldFocused ? 2 : 1
                            )
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isTextFieldFocused = false
                            }
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                    }

                HStack {
                    Text("Range: \(minScore) – \(maxScore)")
                        .font(DesignTypography.font(.caption))
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))

                    Spacer()

                    if Int(inputText) != defaultScore {
                        Button("Reset to \(defaultScore)") {
                            inputText = "\(defaultScore)"
                            HapticFeedback.light()
                        }
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(accentColor)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .appChromeBackground()
            .navigationTitle("Target Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let finalScore = clampedScore
                        targetScore = finalScore
                        onSave(finalScore)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}
