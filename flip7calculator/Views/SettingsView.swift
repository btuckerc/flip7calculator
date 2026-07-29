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
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @AppStorage("showOpeningAnimation") private var showOpeningAnimation: Bool = true
    @AppStorage("animateMainMenuTitle") private var animateMainMenuTitle: Bool = true
    @AppStorage("defaultTargetScore") private var defaultTargetScore: Int = 200
    @AppStorage("visualThemeVersion") private var visualThemeVersion: String = VisualTheme.v2.rawValue
    
    @State private var showingTargetScoreEditor = false
    @State private var tempTargetScore: Int = 200
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    private var selectedVisualTheme: VisualTheme {
        VisualTheme(rawValue: visualThemeVersion) ?? .v2
    }

    private var themeTint: Color {
        switch selectedVisualTheme {
        case .legacy:
            return selectedTheme.accentColor
        case .v2:
            return DesignColor.color(.brandPrimary, theme: .v2, colorScheme: selectedTheme.colorScheme)
        }
    }

    private var rowBackground: Color {
        DesignColor.color(.surfaceRaised, theme: selectedVisualTheme, colorScheme: selectedTheme.colorScheme ?? colorScheme)
    }

    private var rowSeparator: Color {
        AppBrandPalette.cardBorder(colorScheme: selectedTheme.colorScheme ?? colorScheme)
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
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose a color scheme for the app")
                }

                Section {
                    OptionChips(
                        options: Array(VisualTheme.allCases),
                        selectedOption: selectedVisualTheme,
                        onSelect: { visualTheme in
                            visualThemeVersion = visualTheme.rawValue
                        },
                        labelForOption: { $0.displayName },
                        iconForOption: { $0.icon },
                        colorForOption: { visualTheme in
                            DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: selectedTheme.colorScheme)
                        }
                    )
                    .padding(.vertical, 4)
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Visual Theme")
                } footer: {
                    Text("Legacy keeps the original UI. \(AppBrand.visualThemeV2Name) uses the current design system.")
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
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
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
                                .foregroundStyle(displayedTargetScore > 50 ? themeTint : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore <= 50)
                        
                        Button {
                            tempTargetScore = displayedTargetScore
                            showingTargetScoreEditor = true
                        } label: {
                            Text("\(displayedTargetScore)")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(themeTint)
                                .frame(minWidth: 50)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            let newScore = min(5000, displayedTargetScore + 25)
                            updateTargetScore(newScore)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(displayedTargetScore < 5000 ? themeTint : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore >= 5000)
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    
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
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    
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
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
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
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Haptics")
                }
                
                // Display
                Section {
                    Toggle("Show Round Score Preview", isOn: $showRoundScorePreview)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Show potential round score on player tiles")
                }
                
                // Accessibility
                Section {
                    Toggle("Show Opening Animation", isOn: $showOpeningAnimation)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    Toggle("Animate Title", isOn: $animateMainMenuTitle)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    Toggle("Reduce Animations", isOn: $reduceAnimations)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Opening animation plays when the app launches. Title animation loops on the main menu. Reduce Animations and iOS Reduce Motion disable both animated effects.")
                }
                
                // Support
                Section {
                    Button {
                        if let url = URL(string: AppBrand.supportURL) {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(themeTint)
                            Text("Send Feedback")
                                .foregroundStyle(.primary)
                        }
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    
                    Button {
                        requestAppReview()
                    } label: {
                        HStack {
                            Image(systemName: "star")
                                .foregroundStyle(themeTint)
                            Text("Rate the App")
                                .foregroundStyle(.primary)
                        }
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Support")
                }
                
                // About
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text("App")
                        Spacer()
                        Text(AppBrand.appName)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppBrand.versionSummary)
                            .foregroundStyle(.secondary)
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("About")
                } footer: {
                    Text(AppBrand.independenceNotice)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .appChromeBackground()
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
        .tint(themeTint)
        .sheet(isPresented: $showingTargetScoreEditor) {
            TargetScoreEditorSheet(targetScore: $tempTargetScore) { newScore in
                updateTargetScore(newScore)
            }
            .preferredColorScheme(selectedTheme.colorScheme)
            .tint(themeTint)
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
        if let url = URL(string: "https://apps.apple.com/app/id\(AppBrand.appStoreId)?action=write-review") {
            openURL(url)
        }
    }
}

private struct SettingsRowChrome: ViewModifier {
    let background: Color
    let separator: Color

    func body(content: Content) -> some View {
        content
            .listRowBackground(background)
            .listRowSeparatorTint(separator.opacity(0.34))
    }
}

private extension View {
    func settingsRowStyle(background: Color, separator: Color) -> some View {
        modifier(SettingsRowChrome(background: background, separator: separator))
    }
}
