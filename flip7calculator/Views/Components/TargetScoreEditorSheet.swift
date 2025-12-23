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
    
    @State private var inputText: String
    @FocusState private var isTextFieldFocused: Bool
    
    private let minScore = 50
    private let maxScore = 5000
    
    init(targetScore: Binding<Int>, onSave: @escaping (Int) -> Void) {
        self._targetScore = targetScore
        self.onSave = onSave
        self._inputText = State(initialValue: "\(targetScore.wrappedValue)")
    }
    
    private var clampedScore: Int {
        let value = Int(inputText) ?? minScore
        return max(minScore, min(maxScore, value))
    }
    
    private let defaultScore = 200
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Instructions
                Text("Enter target score")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                
                // Text field
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
                            .stroke(isTextFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
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
                
                // Range hint and reset
                HStack {
                    Text("Range: \(minScore) - \(maxScore)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    if Int(inputText) != defaultScore {
                        Button("Reset to \(defaultScore)") {
                            inputText = "\(defaultScore)"
                            HapticFeedback.light()
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
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
                // Focus text field when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

