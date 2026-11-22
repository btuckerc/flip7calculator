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
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("defaultGameMode") private var defaultGameModeRaw: String = GameMode.classic.rawValue
    @AppStorage("defaultBrutalMode") private var defaultBrutalMode: Bool = ScoringRules.defaultBrutalMode
    @State private var deckProfile: DeckProfile = .standard
    @State private var hasChanges = false
    @State private var showingResetConfirmation = false

    private var hasActiveGame: Bool {
        viewModel.game != nil
    }

    private var mode: GameMode {
        deckProfile.mode
    }

    private var numberRange: ClosedRange<Int> {
        mode == .classic ? 0...12 : 1...13
    }

    var body: some View {
        List {
            modeSection
            summarySection
            numberCardsSection

            if mode == .vengeance {
                specialNumberCardsSection
            }

            modifierCardsSection
            actionCardsSection
            resetSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .appChromeBackground()
        .navigationTitle("Deck Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
            }
        }
        .onAppear(perform: loadDeckProfile)
        .confirmationDialog(
            "Reset \(mode.displayName) deck?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to \(mode.displayName) Default", role: .destructive, action: resetToDefault)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces every custom card count in the \(mode.displayName) profile.")
        }
    }

    private var modeSection: some View {
        Section {
            OptionChips(
                options: GameMode.allCases,
                selectedOption: mode,
                onSelect: switchMode,
                labelForOption: { $0.displayName },
                iconForOption: { $0.icon },
                fillsAvailableWidth: true
            )
            .padding(.vertical, 4)
        } header: {
            Text("Game Mode")
        } footer: {
            if hasActiveGame {
                Text("Switches the current game. Shared number cards stay in this round; mode-specific entries return if you switch back.")
            } else {
                Text("Classic and Vengeance custom decks are saved separately.")
            }
        }
    }

    private var summarySection: some View {
        Section {
            LabeledContent("Total Cards", value: "\(deckProfile.totalCardCount)")
            LabeledContent("Configuration", value: deckProfile.isDefaultProfile ? "Default" : "Custom")
        } header: {
            Text("Deck Summary")
        }
    }

    private var numberCardsSection: some View {
        Section {
            ForEach(numberRange, id: \.self) { number in
                cardCountRow(label: "\(number)", count: binding(forNumber: number), range: 0...20)
            }
        } header: {
            Text(mode == .classic ? "Number Cards (0-12)" : "Regular Number Cards (1-13)")
        } footer: {
            if mode == .vengeance {
                Text("The default has six regular 7s and twelve regular 13s; their final copies are special cards below.")
            } else {
                Text("Set the quantity of each number card in the Classic deck")
            }
        }
    }

    private var specialNumberCardsSection: some View {
        Section {
            ForEach(SpecialNumberCard.allCases) { card in
                cardCountRow(
                    label: card.displayName,
                    count: binding(forSpecialNumber: card),
                    range: 0...10
                )
            }
        } header: {
            Text("Special Number Cards")
        } footer: {
            Text("These cards have scoring or hand-reset effects and count toward the 7-card bonus.")
        }
    }

    private var modifierCardsSection: some View {
        Section {
            if mode == .classic {
                ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                    cardCountRow(label: "+\(value)", count: binding(forAddModifier: value), range: 0...10)
                }
                cardCountRow(label: "x2", count: bindingForX2, range: 0...10)
            } else {
                ForEach([2, 4, 6, 8, 10], id: \.self) { value in
                    cardCountRow(label: "-\(value)", count: binding(forSubtractModifier: value), range: 0...10)
                }
                cardCountRow(label: "Divide by 2", count: bindingForDivideByTwo, range: 0...10)
            }
        } header: {
            Text("Modifier Cards")
        } footer: {
            Text(
                mode == .classic
                    ? "Classic modifiers increase the number-card score."
                    : "Divide first, round down, then subtract negative modifiers."
            )
        }
    }

    private var actionCardsSection: some View {
        Section {
            ForEach(DeckProfile.ActionCard.cards(for: mode), id: \.rawValue) { actionCard in
                cardCountRow(
                    label: actionCard.displayName,
                    icon: actionCard.icon,
                    count: binding(forAction: actionCard),
                    range: 0...10
                )
            }
        } header: {
            Text("Action Cards")
        } footer: {
            Text("Action counts contribute to deck size; score entry records their resulting hand changes.")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Text("Reset to \(mode.displayName) Default")
                    .frame(maxWidth: .infinity)
            }
            .disabled(deckProfile.isDefaultProfile)
        } footer: {
            Text("Restores the verified \(mode == .classic ? 94 : 108)-card composition for this mode only.")
        }
    }

    private func cardCountRow(
        label: String,
        icon: String? = nil,
        count: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(.system(size: 17, weight: .medium, design: .rounded))
            Spacer()
            Stepper(value: count, in: range) {
                Text("\(count.wrappedValue)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 30)
            }
        }
    }

    private func trackedBinding(get: @escaping () -> Int, set: @escaping (Int) -> Void) -> Binding<Int> {
        Binding(
            get: get,
            set: { value in
                set(max(0, value))
                hasChanges = true
            }
        )
    }

    private func binding(forNumber number: Int) -> Binding<Int> {
        trackedBinding(
            get: { deckProfile.numberCardCounts[number] ?? 0 },
            set: {
                if $0 == 0 {
                    deckProfile.numberCardCounts.removeValue(forKey: number)
                } else {
                    deckProfile.numberCardCounts[number] = $0
                }
            }
        )
    }

    private func binding(forSpecialNumber card: SpecialNumberCard) -> Binding<Int> {
        trackedBinding(
            get: { deckProfile.specialNumberCardCounts[card.rawValue] ?? 0 },
            set: {
                if $0 == 0 {
                    deckProfile.specialNumberCardCounts.removeValue(forKey: card.rawValue)
                } else {
                    deckProfile.specialNumberCardCounts[card.rawValue] = $0
                }
            }
        )
    }

    private func binding(forAddModifier value: Int) -> Binding<Int> {
        trackedBinding(
            get: { deckProfile.addModifierCounts[value] ?? 0 },
            set: {
                if $0 == 0 {
                    deckProfile.addModifierCounts.removeValue(forKey: value)
                } else {
                    deckProfile.addModifierCounts[value] = $0
                }
            }
        )
    }

    private func binding(forSubtractModifier value: Int) -> Binding<Int> {
        trackedBinding(
            get: { deckProfile.subtractModifierCounts[value] ?? 0 },
            set: {
                if $0 == 0 {
                    deckProfile.subtractModifierCounts.removeValue(forKey: value)
                } else {
                    deckProfile.subtractModifierCounts[value] = $0
                }
            }
        )
    }

    private func binding(forAction card: DeckProfile.ActionCard) -> Binding<Int> {
        trackedBinding(
            get: { deckProfile.actionCardCounts[card.rawValue] ?? 0 },
            set: {
                if $0 == 0 {
                    deckProfile.actionCardCounts.removeValue(forKey: card.rawValue)
                } else {
                    deckProfile.actionCardCounts[card.rawValue] = $0
                }
            }
        )
    }

    private var bindingForX2: Binding<Int> {
        trackedBinding(get: { deckProfile.x2Count }, set: { deckProfile.x2Count = $0 })
    }

    private var bindingForDivideByTwo: Binding<Int> {
        trackedBinding(get: { deckProfile.divideByTwoCount }, set: { deckProfile.divideByTwoCount = $0 })
    }

    private func loadDeckProfile() {
        if let activeGame = viewModel.game {
            deckProfile = activeGame.deckProfile
        } else {
            let selectedMode = GameMode(rawValue: defaultGameModeRaw) ?? .classic
            deckProfile = PersistedDeckProfile.load(for: selectedMode).deckProfile
        }
        hasChanges = false
    }

    private func switchMode(_ newMode: GameMode) {
        guard newMode != mode else { return }
        saveChanges()
        defaultGameModeRaw = newMode.rawValue
        if newMode == .classic {
            defaultBrutalMode = ScoringRules.defaultBrutalMode
        }

        if hasActiveGame {
            viewModel.switchGameMode(to: newMode, brutalMode: defaultBrutalMode)
            deckProfile = viewModel.game?.deckProfile ?? .defaultProfile(for: newMode)
            defaultBrutalMode = viewModel.game?.scoringRules.brutalMode ?? defaultBrutalMode
        } else {
            deckProfile = PersistedDeckProfile.load(for: newMode).deckProfile
        }
        hasChanges = false
    }

    private func saveChanges() {
        guard hasChanges else { return }
        PersistedDeckProfile(deckProfile: deckProfile).save()
        if hasActiveGame {
            viewModel.updateDeckProfile(deckProfile)
        }
        hasChanges = false
    }

    private func resetToDefault() {
        HapticFeedback.light()
        deckProfile = .defaultProfile(for: mode)
        hasChanges = true
        saveChanges()
    }
}
