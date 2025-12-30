//
//  SettingsView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI
import StoreKit

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
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @AppStorage("showOpeningAnimation") private var showOpeningAnimation: Bool = true
    @AppStorage("animateMainMenuTitle") private var animateMainMenuTitle: Bool = true
    @AppStorage("defaultTargetScore") private var defaultTargetScore: Int = 200
    
    @State private var showingTargetScoreEditor = false
    @State private var tempTargetScore: Int = 200
    
    private let appStoreId = "6756905042"
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }
    
    /// The displayed target score: from active game if present, otherwise from default
    private var displayedTargetScore: Int {
        viewModel.game?.targetScore ?? defaultTargetScore
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
                
                // Game Options: Target Score, Manage Players, Manage Deck
                Section {
                    // Target Score - editable
                    HStack {
                        Text("Target Score")
                        
                        Spacer()
                        
                        Button {
                            let newScore = max(50, displayedTargetScore - 25)
                            updateTargetScore(newScore)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(displayedTargetScore > 50 ? .blue : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore <= 50)
                        
                        Button {
                            tempTargetScore = displayedTargetScore
                            showingTargetScoreEditor = true
                        } label: {
                            Text("\(displayedTargetScore)")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(minWidth: 50)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            let newScore = min(5000, displayedTargetScore + 25)
                            updateTargetScore(newScore)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(displayedTargetScore < 5000 ? .blue : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore >= 5000)
                    }
                    
                    // Manage Players
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
                    
                    // Manage Deck
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
                    Text("Game Options")
                } footer: {
                    if viewModel.game != nil {
                        Text("Changes to target score will update the current game")
                    } else {
                        Text("Target score will be used for new games")
                    }
                }
                
                // Haptics
                Section {
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                } header: {
                    Text("Haptics")
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
                    Toggle("Show Opening Animation", isOn: $showOpeningAnimation)
                    Toggle("Animate Title", isOn: $animateMainMenuTitle)
                    Toggle("Reduce Animations", isOn: $reduceAnimations)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Opening animation plays when the app launches. Title animation loops on the main menu. Reduce Animations and iOS Reduce Motion disable both animated effects.")
                }
                
                // Support
                Section {
                    Button {
                        if let url = URL(string: "https://btuckerc.dev/contact") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.blue)
                            Text("Send Feedback")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    Button {
                        requestAppReview()
                    } label: {
                        HStack {
                            Image(systemName: "star")
                                .foregroundStyle(.blue)
                            Text("Rate the App")
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Support")
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
                updateTargetScore(newScore)
            }
            .preferredColorScheme(selectedTheme.colorScheme)
            .tint(selectedTheme.accentColor)
            .id(appTheme)
        }
    }
    
    // MARK: - Helpers
    
    /// Updates both the default target score and the active game's target score (if present)
    private func updateTargetScore(_ newScore: Int) {
        let clampedScore = max(50, min(5000, newScore))
        defaultTargetScore = clampedScore
        if viewModel.game != nil {
            viewModel.updateTargetScore(clampedScore)
        }
    }
    
    /// Requests an App Store review using in-app prompt, with fallback to opening the App Store
    private func requestAppReview() {
        // Try the in-app review prompt
        requestReview()
        
        // Note: requestReview() may or may not show a prompt depending on Apple's rate limits.
        // We cannot reliably detect if it was shown, so we don't automatically fall back.
        // Users who want to leave a review can tap again, or we could add a separate "Write a Review" option.
        // For now, the button tries the prompt. If users want guaranteed access, they can use the App Store link.
    }
    
    /// Opens the App Store review page directly
    private func openAppStoreReview() {
        if let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") {
            openURL(url)
        }
    }
}
