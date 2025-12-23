//
//  DeckManagementView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import SwiftUI

struct DeckManagementView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var deckProfile: DeckProfile = .standard
    @State private var hasChanges = false
    
    private var hasActiveGame: Bool {
        viewModel.game != nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Summary section
                Section {
                    HStack {
                        Text("Total Cards")
                        Spacer()
                        Text("\(deckProfile.totalCardCount)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Deck Summary")
                }
                
                // Number cards section
                Section {
                    ForEach(0...12, id: \.self) { number in
                        HStack {
                            Text("\(number)")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                            Spacer()
                            Stepper(
                                value: Binding(
                                    get: { deckProfile.numberCardCounts[number] ?? 0 },
                                    set: { newValue in
                                        deckProfile.numberCardCounts[number] = max(0, newValue)
                                        hasChanges = true
                                    }
                                ),
                                in: 0...20
                            ) {
                                Text("\(deckProfile.numberCardCounts[number] ?? 0)")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 30)
                            }
                        }
                    }
                } header: {
                    Text("Number Cards (0-12)")
                } footer: {
                    Text("Set the quantity of each number card in the deck")
                }
                
                // Modifier cards section
                Section {
                    ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                        HStack {
                            Text("+\(value)")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                            Spacer()
                            Stepper(
                                value: Binding(
                                    get: { deckProfile.addModifierCounts[value] ?? 0 },
                                    set: { newValue in
                                        deckProfile.addModifierCounts[value] = max(0, newValue)
                                        hasChanges = true
                                    }
                                ),
                                in: 0...10
                            ) {
                                Text("\(deckProfile.addModifierCounts[value] ?? 0)")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 30)
                            }
                        }
                    }
                    
                    HStack {
                        Text("×2")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                        Spacer()
                        Stepper(
                            value: Binding(
                                get: { deckProfile.x2Count },
                                set: { newValue in
                                    deckProfile.x2Count = max(0, newValue)
                                    hasChanges = true
                                }
                            ),
                            in: 0...10
                        ) {
                            Text("\(deckProfile.x2Count)")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(minWidth: 30)
                        }
                    }
                } header: {
                    Text("Modifier Cards")
                } footer: {
                    Text("Set the quantity of each modifier card in the deck")
                }
                
                // Action cards section (for future use)
                Section {
                    ForEach(["Freeze", "FlipThree", "SecondChance"], id: \.self) { actionName in
                        HStack {
                            Text(actionNameDisplayName(actionName))
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                            Spacer()
                            Stepper(
                                value: Binding(
                                    get: { deckProfile.actionCardCounts[actionName] ?? 0 },
                                    set: { newValue in
                                        deckProfile.actionCardCounts[actionName] = max(0, newValue)
                                        hasChanges = true
                                    }
                                ),
                                in: 0...10
                            ) {
                                Text("\(deckProfile.actionCardCounts[actionName] ?? 0)")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 30)
                            }
                        }
                    }
                } header: {
                    Text("Action Cards")
                } footer: {
                    Text("Set the quantity of each action card (for future use)")
                }
                
                // Reset section
                Section {
                    Button(role: .destructive, action: resetToStandard) {
                        HStack {
                            Spacer()
                            Text("Reset to Standard Deck")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Restore the default Flip 7 deck composition")
                }
            }
            .navigationTitle("Manage Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDeckProfile()
            }
        }
    }
    
    private func actionNameDisplayName(_ name: String) -> String {
        switch name {
        case "Freeze": return "Freeze"
        case "FlipThree": return "Flip Three"
        case "SecondChance": return "Second Chance"
        default: return name
        }
    }
    
    private func loadDeckProfile() {
        if hasActiveGame, let game = viewModel.game {
            // Load from active game
            deckProfile = game.deckProfile
        } else {
            // Load from persisted default
            deckProfile = PersistedDeckProfile.load().deckProfile
        }
        hasChanges = false
    }
    
    private func saveChanges() {
        // Save as new default
        let persisted = PersistedDeckProfile(deckProfile: deckProfile)
        persisted.save()
        
        // If there's an active game, update it
        if hasActiveGame {
            viewModel.updateDeckProfile(deckProfile)
        }
        
        hasChanges = false
    }
    
    private func resetToStandard() {
        HapticFeedback.light()
        deckProfile = .standard
        hasChanges = true
        saveChanges()
    }
}

