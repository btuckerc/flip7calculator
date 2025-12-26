//
//  SettingsView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case midnight = "Midnight"
    case sunset = "Sunset"
    case forest = "Forest"
    case ocean = "Ocean"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .sunset: return .light
        case .dark, .midnight, .forest, .ocean: return .dark
        }
    }
    
    var accentColor: Color {
        switch self {
        case .system, .light, .dark: return .blue
        case .midnight: return .indigo
        case .sunset: return .orange
        case .forest: return .green
        case .ocean: return .cyan
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .midnight: return "moon.stars.fill"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .ocean: return "water.waves"
        }
    }
}

struct SettingsView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.vibrant.rawValue
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    
    @State private var showingTargetScoreEditor = false
    @State private var tempTargetScore: Int = 200
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? .vibrant
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Theme - Compact picker
                Section {
                    OptionChips(
                        options: Array(AppTheme.allCases),
                        selectedOption: selectedTheme,
                        onSelect: { theme in
                            appTheme = theme.rawValue
                        },
                        labelForOption: { $0.rawValue },
                        iconForOption: { $0.icon },
                        colorForOption: { $0.accentColor }
                    )
                    .padding(.vertical, 4)
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose a color scheme for the app")
                }
                
                // Player Palette - Compact picker
                Section {
                    OptionChips(
                        options: Array(PlayerPalette.allCases),
                        selectedOption: selectedPalette,
                        onSelect: { palette in
                            playerPaletteRaw = palette.rawValue
                        },
                        labelForOption: { $0.displayName },
                        iconForOption: { $0.icon },
                        previewColorsForOption: { palette in
                            PlayerColorResolver.previewColors(palette: palette)
                        }
                    )
                    .padding(.vertical, 4)
                } header: {
                    Text("Player Colors")
                } footer: {
                    Text("Choose a color palette for player tiles")
                }
                
                // Feedback
                Section {
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                } header: {
                    Text("Feedback")
                }
                
                // Display
                Section {
                    Toggle("Show Round Score Preview", isOn: $showRoundScorePreview)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Show potential round score on player tiles")
                }
                
                // Accessibility
                Section {
                    Toggle("Reduce Animations", isOn: $reduceAnimations)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Disable state frame animations. iOS Reduce Motion is also respected.")
                }
                
                // Players
                Section {
                    NavigationLink(destination: PlayerManagementView(viewModel: viewModel)) {
                        HStack {
                            Text("Manage Players")
                            Spacer()
                            if let roster = PersistedRoster.load(), !roster.names.isEmpty {
                                Text("\(roster.names.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Players")
                } footer: {
                    Text("Edit and reorder your saved player roster")
                }
                
                // Deck
                Section {
                    NavigationLink(destination: DeckManagementView(viewModel: viewModel)) {
                        HStack {
                            Text("Manage Deck")
                            Spacer()
                            let deckProfile = PersistedDeckProfile.load().deckProfile
                            Text("\(deckProfile.totalCardCount) cards")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Deck")
                } footer: {
                    Text("Customize the deck composition for new games")
                }
                
                // Game settings (if game is active)
                if let game = viewModel.game {
                    Section {
                        // Target Score - editable
                        HStack {
                            Text("Target Score")
                            
                            Spacer()
                            
                            Button {
                                let newScore = max(50, game.targetScore - 25)
                                viewModel.updateTargetScore(newScore)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(game.targetScore > 50 ? .blue : Color(.systemGray4))
                            }
                            .buttonStyle(.borderless)
                            .disabled(game.targetScore <= 50)
                            
                            Button {
                                tempTargetScore = game.targetScore
                                showingTargetScoreEditor = true
                            } label: {
                                Text("\(game.targetScore)")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundStyle(.blue)
                                    .frame(minWidth: 50)
                            }
                            .buttonStyle(.borderless)
                            
                            Button {
                                let newScore = min(5000, game.targetScore + 25)
                                viewModel.updateTargetScore(newScore)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(game.targetScore < 5000 ? .blue : Color(.systemGray4))
                            }
                            .buttonStyle(.borderless)
                            .disabled(game.targetScore >= 5000)
                        }
                        
                        HStack {
                            Text("Current Round")
                            Spacer()
                            Text("\(game.currentRoundNumber)")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Current Game")
                    }
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(selectedTheme.accentColor)
        .sheet(isPresented: $showingTargetScoreEditor) {
            TargetScoreEditorSheet(targetScore: $tempTargetScore) { newScore in
                viewModel.updateTargetScore(newScore)
            }
        }
    }
}
