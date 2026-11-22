//
//  ManualScoreEditorSheet.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/26/25.
//

import SwiftUI
import UIKit

/// Sheet content for manual round score entry.
struct ManualScoreSheetContent: View {
    let autoScore: Int
    let currentManualScore: Int?
    let onSave: (Int) -> Void
    let onClearManualScore: () -> Void
    let allowsNegative: Bool
    let onDismiss: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    @State private var inputText: String
    @State private var didCompleteExplicitAction = false

    private let maxScore = 9999

    init(
        autoScore: Int,
        currentManualScore: Int?,
        onSave: @escaping (Int) -> Void,
        onClearManualScore: @escaping () -> Void,
        allowsNegative: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.autoScore = autoScore
        self.currentManualScore = currentManualScore
        self.onSave = onSave
        self.onClearManualScore = onClearManualScore
        self.allowsNegative = allowsNegative
        self.onDismiss = onDismiss
        self._inputText = State(initialValue: currentManualScore.map { "\($0)" } ?? "")
    }

    private var parsedScore: Int? {
        Int(inputText)
    }

    private var isValidInput: Bool {
        parsedScore != nil && !inputText.isEmpty
    }

    private func submitScore() {
        if isValidInput, let score = parsedScore {
            didCompleteExplicitAction = true
            HapticFeedback.light()
            onSave(clamped(score))
            onDismiss()
        }
    }

    private var hasChanges: Bool {
        guard let score = parsedScore else { return false }
        return clamped(score) != currentManualScore
    }

    private func saveIfValid() {
        guard !didCompleteExplicitAction else { return }
        if isValidInput && hasChanges, let score = parsedScore {
            onSave(clamped(score))
        }
    }

    private func clamped(_ score: Int) -> Int {
        max(allowsNegative ? -maxScore : 0, min(maxScore, score))
    }

    private func toggleSign() {
        if inputText.hasPrefix("-") {
            inputText.removeFirst()
        } else if !inputText.isEmpty && inputText != "0" {
            inputText = "-" + inputText
        }
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScoreInputField(
                    text: $inputText,
                    isValid: isValidInput,
                    onSubmit: submitScore
                )
                .frame(width: 148, height: 56)

                if allowsNegative {
                    Button(action: toggleSign) {
                        Label("Toggle positive or negative", systemImage: "plus.forwardslash.minus")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("From cards: \(autoScore)")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    if currentManualScore != nil {
                        Button(action: {
                            didCompleteExplicitAction = true
                            HapticFeedback.light()
                            onClearManualScore()
                            onDismiss()
                        }) {
                            Text("Use from cards")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity)
            .appChromeBackground()
            .navigationTitle("Manual Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submitScore) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(isValidInput ? accentColor : .gray.opacity(0.4))
                    }
                    .disabled(!isValidInput)
                    .accessibilityLabel("Save manual score")
                }
            }
            .onDisappear {
                saveIfValid()
            }
        }
    }
}

/// UIKit-backed numeric input field with instant auto-focus.
struct ScoreInputField: UIViewRepresentable {
    @Binding var text: String
    let isValid: Bool
    let onSubmit: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: UIColor {
        UIColor(DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme))
    }

    private var borderColor: UIColor {
        UIColor(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride).opacity(0.5))
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.font = UIFont.rounded(ofSize: 28, weight: .bold)
        textField.textAlignment = .center
        textField.textColor = UIColor(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
        textField.backgroundColor = backgroundColor
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = borderColor.cgColor
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.textColor = UIColor(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
        uiView.backgroundColor = backgroundColor
        uiView.layer.borderColor = borderColor.cgColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onSubmit: () -> Void

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
        }

        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
    }
}
