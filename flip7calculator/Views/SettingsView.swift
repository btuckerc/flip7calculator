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

    var hasCustomAccent: Bool {
        switch self {
        case .system, .light, .dark:
            return false
        case .midnight, .sunset, .forest, .ocean:
            return true
        }
    }

    var accentColor: Color {
        switch self {
        case .system, .light, .dark: return AppBrandPalette.brandBlue
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

    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("visualThemeVersion") private var visualThemeVersion: String = VisualTheme.v2.rawValue
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("showRoundScorePreview") private var showRoundScorePreview: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @AppStorage("showOpeningAnimation") private var showOpeningAnimation: Bool = true
    @AppStorage("animateMainMenuTitle") private var animateMainMenuTitle: Bool = true
    @AppStorage("defaultTargetScore") private var defaultTargetScore: Int = 200
    @AppStorage("defaultGameMode") private var defaultGameModeRaw: String = GameMode.classic.rawValue
    @AppStorage("defaultBrutalMode") private var defaultBrutalMode: Bool = ScoringRules.defaultBrutalMode

    @State private var showingTargetScoreEditor = false
    @State private var tempTargetScore: Int = 200

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var selectedVisualTheme: VisualTheme {
        VisualTheme(rawValue: visualThemeVersion) ?? .v2
    }

    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    private var selectedDefaultGameMode: GameMode {
        GameMode(rawValue: defaultGameModeRaw) ?? .classic
    }

    private var displayedGameMode: GameMode {
        viewModel.game?.scoringRules.mode ?? selectedDefaultGameMode
    }

    private var brutalModeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.game?.scoringRules.brutalMode ?? defaultBrutalMode },
            set: { enabled in
                defaultBrutalMode = enabled
                if viewModel.game?.scoringRules.mode == .vengeance {
                    viewModel.setBrutalMode(enabled)
                }
            }
        )
    }

    private var effectiveColorScheme: ColorScheme {
        selectedTheme.colorScheme ?? colorScheme
    }

    private var accentOverride: Color? {
        selectedTheme.hasCustomAccent ? selectedTheme.accentColor : nil
    }

    private var themeTint: Color {
        DesignColor.color(.brandPrimary, theme: selectedVisualTheme, colorScheme: effectiveColorScheme, accentOverride: accentOverride)
    }

    private var rowBackground: Color {
        DesignColor.listRowBackground(theme: selectedVisualTheme, colorScheme: effectiveColorScheme)
    }

    private var rowSeparator: Color {
        DesignColor.border(theme: selectedVisualTheme, colorScheme: effectiveColorScheme)
    }

    private var displayedTargetScore: Int {
        viewModel.game?.targetScore ?? defaultTargetScore
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OptionChips(
                        options: Array(VisualTheme.allCases),
                        selectedOption: selectedVisualTheme,
                        onSelect: { theme in
                            visualThemeVersion = theme.rawValue
                        },
                        labelForOption: { $0.displayName },
                        iconForOption: { $0.icon },
                        fillsAvailableWidth: true,
                        usesBorderlessStyle: true
                    )
                    .padding(.vertical, 4)
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Visual Theme")
                } footer: {
                    Text("Switch between the classic system look and the Flipping Seven palette.")
                }

                Section {
                    OptionChips(
                        options: Array(AppTheme.allCases),
                        selectedOption: selectedTheme,
                        onSelect: { theme in
                            appTheme = theme.rawValue
                        },
                        labelForOption: { $0.rawValue },
                        iconForOption: { $0.icon },
                        colorForOption: { $0.accentColor },
                        usesBorderlessStyle: true
                    )
                    .padding(.vertical, 4)
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose a color scheme and accent for the app.")
                }

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
                        },
                        usesBorderlessStyle: true
                    )
                    .padding(.vertical, 4)
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Player Colors")
                } footer: {
                    Text("Choose an accessible color palette for player accents and charts.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.game == nil ? "Default Game Mode" : "Game Mode")
                            .font(.system(.body, design: .rounded, weight: .medium))

                        OptionChips(
                            options: GameMode.allCases,
                            selectedOption: displayedGameMode,
                            onSelect: selectGameMode,
                            labelForOption: { $0.displayName },
                            iconForOption: { $0.icon },
                            fillsAvailableWidth: true,
                            usesBorderlessStyle: true
                        )
                    }
                    .padding(.vertical, 4)
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)

                    if displayedGameMode == .vengeance {
                        Toggle(isOn: brutalModeBinding) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Brutal Mode")
                                Text(ScoringRules.brutalModeDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("Brutal Mode")
                        .accessibilityHint(
                            viewModel.game == nil
                                ? "Uses the optional cutthroat rules for new Vengeance games"
                                : "Changes the optional cutthroat rules for the current Vengeance game"
                        )
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                    }

                    HStack {
                        Text("Target Score")

                        Spacer()

                        Button {
                            HapticFeedback.light()
                            updateTargetScore(max(50, displayedTargetScore - 25))
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(displayedTargetScore > 50 ? themeTint : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore <= 50)
                        .accessibilityLabel("Decrease target score by 25")

                        Button {
                            tempTargetScore = displayedTargetScore
                            showingTargetScoreEditor = true
                        } label: {
                            Text("\(displayedTargetScore)")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(themeTint)
                                .frame(minWidth: 50)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Target score \(displayedTargetScore)")

                        Button {
                            HapticFeedback.light()
                            updateTargetScore(min(5000, displayedTargetScore + 25))
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(displayedTargetScore < 5000 ? themeTint : Color(.systemGray4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(displayedTargetScore >= 5000)
                        .accessibilityLabel("Increase target score by 25")
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)

                    NavigationLink(destination: PlayerManagementView(viewModel: viewModel)) {
                        HStack {
                            Text("Manage Players")
                            Spacer()
                            if let roster = PersistedRoster.load(), !roster.names.isEmpty {
                                Text("\(roster.names.count)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)

                    NavigationLink(destination: DeckManagementView(viewModel: viewModel)) {
                        HStack {
                            Text("Manage Deck")
                            Spacer()
                            let deckProfile = viewModel.game?.deckProfile
                                ?? PersistedDeckProfile.load(for: selectedDefaultGameMode).deckProfile
                            Text("\(deckProfile.totalCardCount) cards")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Game Options")
                } footer: {
                    if viewModel.game != nil {
                        Text("Mode changes apply immediately. Shared number cards stay in this round; mode-specific entries return if you switch back.")
                    } else {
                        Text("These defaults will be used for new games.")
                    }
                }

                Section {
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Haptics")
                }

                Section {
                    Toggle("Show Round Score Preview", isOn: $showRoundScorePreview)
                        .settingsRowStyle(background: rowBackground, separator: rowSeparator)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Show potential round score on player tiles.")
                }

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
                    Text("Opening animation plays briefly when the app launches and can be tapped to skip. Reduce Animations and iOS Reduce Motion disable animated effects.")
                }

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
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
        .tint(themeTint)
        .environment(\.visualTheme, selectedVisualTheme)
        .environment(\.appAccentOverride, accentOverride)
        .sheet(isPresented: $showingTargetScoreEditor) {
            TargetScoreEditorSheet(targetScore: $tempTargetScore) { newScore in
                updateTargetScore(newScore)
            }
            .preferredColorScheme(selectedTheme.colorScheme)
            .tint(themeTint)
            .environment(\.visualTheme, selectedVisualTheme)
            .environment(\.appAccentOverride, accentOverride)
        }
    }

    private func updateTargetScore(_ newScore: Int) {
        let clampedScore = max(50, min(5000, newScore))
        defaultTargetScore = clampedScore
        if viewModel.game != nil {
            viewModel.updateTargetScore(clampedScore)
        }
    }

    private func selectGameMode(_ mode: GameMode) {
        guard mode != displayedGameMode else { return }

        defaultGameModeRaw = mode.rawValue
        if mode == .classic {
            defaultBrutalMode = ScoringRules.defaultBrutalMode
        }

        if viewModel.game != nil {
            viewModel.switchGameMode(to: mode, brutalMode: defaultBrutalMode)
            if let activeRules = viewModel.game?.scoringRules {
                defaultBrutalMode = activeRules.brutalMode
            }
        }
    }

    private func requestAppReview() {
        requestReview()
    }
}

private struct SettingsRowChrome: ViewModifier {
    let background: Color
    let separator: Color

    func body(content: Content) -> some View {
        content
            .listRowBackground(background)
            .listRowSeparatorTint(separator.opacity(0.6))
    }
}

private extension View {
    func settingsRowStyle(background: Color, separator: Color) -> some View {
        modifier(SettingsRowChrome(background: background, separator: separator))
    }
}
