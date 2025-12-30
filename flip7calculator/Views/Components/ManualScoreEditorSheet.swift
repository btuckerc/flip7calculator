//
//  ManualScoreEditorSheet.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/26/25.
//

import SwiftUI
import UIKit

// MARK: - Sheet Content for Manual Score Entry

struct ManualScoreSheetContent: View {
    let autoScore: Int
    let currentManualScore: Int?
    let onSave: (Int) -> Void
    let onClearManualScore: () -> Void
    let onDismiss: () -> Void
    
    @State private var inputText: String
    
    private let maxScore = 9999
    
    init(autoScore: Int, currentManualScore: Int?, onSave: @escaping (Int) -> Void, onClearManualScore: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.autoScore = autoScore
        self.currentManualScore = currentManualScore
        self.onSave = onSave
        self.onClearManualScore = onClearManualScore
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
            HapticFeedback.light()
            onSave(max(0, min(maxScore, score)))
            onDismiss()
        }
    }
    
    /// Check if input differs from current saved value (to avoid unnecessary saves)
    private var hasChanges: Bool {
        guard let score = parsedScore else { return false }
        let clampedScore = max(0, min(maxScore, score))
        return clampedScore != currentManualScore
    }
    
    /// Save valid input when sheet is dismissed
    private func saveIfValid() {
        if isValidInput && hasChanges, let score = parsedScore {
            onSave(max(0, min(maxScore, score)))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Text field - submit via toolbar checkmark
                ScoreInputField(
                    text: $inputText,
                    isValid: isValidInput,
                    onSubmit: submitScore
                )
                .frame(width: 140, height: 56)
                
                // From cards score hint + revert button
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Text("From cards: \(autoScore)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Show "Use from cards" button only when a manual override exists
                    if currentManualScore != nil {
                        Button(action: {
                            HapticFeedback.light()
                            onClearManualScore()
                            onDismiss()
                        }) {
                            Text("Use from cards")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Manual Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submitScore) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(isValidInput ? .blue : .gray.opacity(0.4))
                    }
                    .disabled(!isValidInput)
                }
            }
            .onDisappear {
                // Save valid input when user dismisses sheet
                saveIfValid()
            }
        }
    }
}

// MARK: - Legacy Popover (kept for reference)

struct ManualScorePopover: View {
    let autoScore: Int
    let currentManualScore: Int?
    let onSave: (Int) -> Void
    let onClearManualScore: () -> Void
    let onDismiss: () -> Void
    
    @State private var inputText: String
    
    private let maxScore = 9999
    
    init(autoScore: Int, currentManualScore: Int?, onSave: @escaping (Int) -> Void, onClearManualScore: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.autoScore = autoScore
        self.currentManualScore = currentManualScore
        self.onSave = onSave
        self.onClearManualScore = onClearManualScore
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
            HapticFeedback.light()
            onSave(max(0, min(maxScore, score)))
            onDismiss()
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ScoreInputField(
                text: $inputText,
                isValid: isValidInput,
                onSubmit: submitScore
            )
            .frame(width: 120, height: 52)
            
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Text("From cards: \(autoScore)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - UIKit TextField (no accessory view - toolbar checkmark is used instead)

struct ScoreInputField: UIViewRepresentable {
    @Binding var text: String
    let isValid: Bool
    let onSubmit: () -> Void
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.font = UIFont.rounded(ofSize: 28, weight: .bold)
        textField.textAlignment = .center
        textField.backgroundColor = UIColor.systemGray6
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        
        // Auto-focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            textField.becomeFirstResponder()
        }
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
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
            // Only allow digits
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
    }
}

// MARK: - Legacy Sheet (kept for reference, not used)

struct ManualScoreEditorSheet: View {
    let autoScore: Int
    let currentManualScore: Int?
    let onSave: (Int) -> Void
    let onClearManualScore: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText: String
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxScore = 9999
    
    init(autoScore: Int, currentManualScore: Int?, onSave: @escaping (Int) -> Void, onClearManualScore: @escaping () -> Void) {
        self.autoScore = autoScore
        self.currentManualScore = currentManualScore
        self.onSave = onSave
        self.onClearManualScore = onClearManualScore
        self._inputText = State(initialValue: currentManualScore.map { "\($0)" } ?? "")
    }
    
    private var parsedScore: Int? {
        Int(inputText)
    }
    
    private var clampedScore: Int {
        max(0, min(maxScore, parsedScore ?? 0))
    }
    
    private var isValidInput: Bool {
        parsedScore != nil && !inputText.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter round score")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                
                TextField("", text: $inputText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? Color.orange : Color.clear, lineWidth: 2)
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isTextFieldFocused = false
                            }
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                    }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("From cards: +\(autoScore)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if currentManualScore != nil {
                        Button("Use from cards") {
                            HapticFeedback.light()
                            onClearManualScore()
                            dismiss()
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .navigationTitle("Manual Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if isValidInput {
                            onSave(clampedScore)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
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
