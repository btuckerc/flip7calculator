//
//  GameSetupView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct GameSetupView: View {
    @Binding var viewModel: GameViewModel
    var animateTitle = true
    @State private var playerRows: [PlayerNameRow] = [PlayerNameRow(), PlayerNameRow()]
    @State private var targetScore: Int = 200
    @StateObject private var focusCoordinator = FocusCoordinator()
    @State private var hasLoadedRoster = false
    @State private var hasLoadedTargetScore = false
    @State private var showingTargetScoreEditor = false
    @State private var showingRules = false
    @State private var showingSettings = false
    @State private var selectedEntryIntent: GameEntryIntent = .scoreCalculator
    @State private var hasLoadedEntryIntent = false
    @State private var showingStartError = false
    
    @AppStorage("defaultTargetScore") private var defaultTargetScore: Int = 200
    @AppStorage("defaultGameMode") private var defaultGameModeRaw: String = GameMode.classic.rawValue
    @AppStorage("defaultBrutalMode") private var defaultBrutalMode: Bool = ScoringRules.defaultBrutalMode
    @AppStorage("lastGameEntryIntent") private var lastGameEntryIntentRaw: String = GameEntryIntent.scoreCalculator.rawValue
    @AppStorage("riskInsightsMode") private var riskInsightsModeRaw: String = RiskInsightsMode.off.rawValue
    @AppStorage("appTheme") private var appTheme: String = "system"
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var themeAccent: Color {
        switch visualTheme {
        case .legacy:
            return selectedTheme.accentColor
        case .v2:
            return DesignColor.color(.brandPrimary, theme: .v2, colorScheme: colorScheme)
        }
    }

    private var selectedGameMode: GameMode {
        GameMode(rawValue: defaultGameModeRaw) ?? .classic
    }

    private var effectiveEntryIntent: GameEntryIntent {
        guard DealerAvailability.isPreviewEnabled, selectedGameMode == .classic else {
            return .scoreCalculator
        }
        return selectedEntryIntent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SetupHeroCard(animateTitle: animateTitle)

                    if DealerAvailability.isPreviewEnabled {
                        SetupPlayStyleCard(
                            selectedIntent: effectiveEntryIntent,
                            dealerEnabled: selectedGameMode == .classic,
                            onSelect: { selectedEntryIntent = $0 }
                        )
                    }

                    PlayersEditorCard(
                        playerRows: $playerRows,
                        focusCoordinator: focusCoordinator,
                        onPersist: persistRosterOrder,
                        onReset: clearPlayers,
                        showsPlayerSummary: false
                    )

                    SetupGameModeCard(
                        selectedMode: selectedGameMode,
                        brutalMode: defaultBrutalMode,
                        onSelectMode: { mode in
                            defaultGameModeRaw = mode.rawValue
                            if mode == .classic {
                                defaultBrutalMode = ScoringRules.defaultBrutalMode
                            }
                        },
                        onSetBrutalMode: { defaultBrutalMode = $0 }
                    )

                    SetupTargetScoreCard(
                        targetScore: $targetScore,
                        themeAccent: themeAccent,
                        showingTargetScoreEditor: $showingTargetScoreEditor
                    )

                    if selectedGameMode == .classic {
                        SetupRiskInsightsCard(riskInsightsModeRaw: $riskInsightsModeRaw)
                    }

                    if targetScore != 200 {
                        Button(action: { targetScore = 200 }) {
                            Text("Reset to 200")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                focusCoordinator.clearFocus()
            }
            .navigationBarTitleDisplayMode(.inline)
            .appChromeBackground()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack {
                    Button(action: {
                        HapticFeedback.success()
                        startGame()
                    }) {
                        Text(effectiveEntryIntent == .playWithDealer ? "Start Dealer Game" : "Start Scoring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canStartGame)
                    .accessibilityIdentifier("setup.startGame")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .background(
                    DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
                        .opacity(0.98)
                        .shadow(color: AppBrandPalette.ink.opacity(visualTheme == .v2 ? 0.10 : 0.05), radius: 18, y: -6)
                        .ignoresSafeArea()
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingRules = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingTargetScoreEditor) {
                TargetScoreEditorSheet(targetScore: $targetScore) { newScore in
                    targetScore = newScore
                }
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(themeAccent)
                .id(appTheme)
            }
            .sheet(isPresented: $showingRules) {
                AppHelpView()
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(themeAccent)
                    .id(appTheme)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(themeAccent)
                    .id(appTheme)
            }
            .alert("Unable to Start", isPresented: $showingStartError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.liveErrorMessage ?? "Please review the game settings and try again.")
            }
            .onAppear {
                if !hasLoadedRoster {
                    loadPersistedRoster()
                    hasLoadedRoster = true
                }
                if !hasLoadedTargetScore {
                    targetScore = defaultTargetScore
                    hasLoadedTargetScore = true
                }
                if !hasLoadedEntryIntent {
                    selectedEntryIntent = GameEntryIntent(rawValue: lastGameEntryIntentRaw) ?? .scoreCalculator
                    if selectedGameMode != .classic {
                        selectedEntryIntent = .scoreCalculator
                    }
                    hasLoadedEntryIntent = true
                }
            }
            .onChange(of: targetScore) { _, newValue in
                defaultTargetScore = newValue
            }
            .onChange(of: defaultGameModeRaw) { _, newValue in
                if GameMode(rawValue: newValue) != .classic {
                    selectedEntryIntent = .scoreCalculator
                }
            }
            .onChange(of: showingSettings) { _, isShowing in
                // Sync state when Settings sheet dismisses
                if !isShowing {
                    // Reload players from persisted roster
                    loadPersistedRoster()
                    // Sync target score from AppStorage
                    targetScore = defaultTargetScore
                }
            }
        }
    }
    
    private func loadPersistedRoster() {
        if let roster = PersistedRoster.load(), !roster.names.isEmpty {
            let names = Array(roster.names.prefix(8))
            playerRows = names.map { PlayerNameRow(name: $0) }
        } else {
            // No saved roster or cleared - reset to default
            playerRows = [PlayerNameRow(), PlayerNameRow()]
        }
        focusCoordinator.setOrder(playerRows.map { $0.id })
    }
    
    private var canStartGame: Bool {
        return playerRows.count >= 2 && playerRows.count <= 8
    }
    
    private func clearPlayers() {
        HapticFeedback.light()
        playerRows = [PlayerNameRow(), PlayerNameRow()]
        focusCoordinator.setOrder(playerRows.map { $0.id })
        focusCoordinator.clearFocus()
        PersistedRoster.clear()
    }
    
    private func startGame() {
        guard playerRows.count >= 2 && playerRows.count <= 8 else { return }
        
        let players = playerRows.enumerated().map { index, row in
            let trimmed = row.name.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
        }
        
        PersistedRoster(names: players).save()
        let didStart = viewModel.startNewGame(
            players: players,
            targetScore: targetScore,
            scoringRules: ScoringRules(mode: selectedGameMode, brutalMode: defaultBrutalMode),
            playStyle: effectiveEntryIntent.playStyle
        )
        if didStart {
            lastGameEntryIntentRaw = effectiveEntryIntent.rawValue
        } else {
            showingStartError = true
        }
    }
    
    private func persistRosterOrder() {
        let names = playerRows.map { $0.name.trimmingCharacters(in: .whitespaces) }
        PersistedRoster(names: names).save()
        focusCoordinator.setOrder(playerRows.map { $0.id })
    }
}

private struct SetupPlayStyleCard: View {
    let selectedIntent: GameEntryIntent
    let dealerEnabled: Bool
    let onSelect: (GameEntryIntent) -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            HStack {
                Text("How are you playing?")
                    .font(DesignTypography.font(.label))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    .textCase(.uppercase)
                Spacer()
                Text("Dealer Preview")
                    .pillBadge(.info)
            }

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: DesignSpacing.xs) {
                        intentButton(.scoreCalculator, isEnabled: true)
                        intentButton(.playWithDealer, isEnabled: dealerEnabled)
                    }
                } else {
                    HStack(spacing: DesignSpacing.xs) {
                        intentButton(.scoreCalculator, isEnabled: true)
                        intentButton(.playWithDealer, isEnabled: dealerEnabled)
                    }
                }
            }

            Text(
                dealerEnabled || selectedIntent == .scoreCalculator
                    ? selectedIntent.detail
                    : "Dealer preview currently supports Classic games."
            )
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
        }
        .padding(DesignSpacing.md)
        .cardSurface(cornerRadius: 22)
        .animation(reduceMotion ? nil : DesignMotion.animation(.fast), value: selectedIntent)
    }

    private func intentButton(_ intent: GameEntryIntent, isEnabled: Bool) -> some View {
        let isSelected = selectedIntent == intent
        return Button(action: { onSelect(intent) }) {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : intent.icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(intent.title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
        .buttonStyle(SelectionCardButtonStyle(isSelected: isSelected))
        .disabled(!isEnabled)
        .accessibilityLabel(intent.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(intent.detail)
        .accessibilityIdentifier("setup.entry.\(intent.rawValue)")
    }
}

private struct SetupRiskInsightsCard: View {
    @Binding var riskInsightsModeRaw: String
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var selectedMode: RiskInsightsMode {
        RiskInsightsMode(rawValue: riskInsightsModeRaw) ?? .off
    }

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Risk Insights")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                Text("Optional duplicate and bust context")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            }

            Spacer()

            Menu {
                ForEach(RiskInsightsMode.allCases) { mode in
                    Button {
                        riskInsightsModeRaw = mode.rawValue
                    } label: {
                        if mode == selectedMode {
                            Label(mode.displayName, systemImage: "checkmark")
                        } else {
                            Text(mode.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selectedMode.displayName)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .pillBadge(selectedMode == .off ? .neutral : .info)
            }
            .accessibilityLabel("Risk Insights")
            .accessibilityValue(selectedMode.displayName)
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .cardSurface(cornerRadius: DesignRadius.lg)
    }
}

private struct SetupGameModeCard: View {
    let selectedMode: GameMode
    let brutalMode: Bool
    let onSelectMode: (GameMode) -> Void
    let onSetBrutalMode: (Bool) -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                .textCase(.uppercase)

            OptionChips(
                options: GameMode.allCases,
                selectedOption: selectedMode,
                onSelect: onSelectMode,
                labelForOption: { $0.displayName },
                iconForOption: { $0.icon },
                fillsAvailableWidth: true
            )

            VStack(alignment: .leading, spacing: 5) {
                if let expansionRequirement = selectedMode.expansionRequirement {
                    Text(expansionRequirement)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                }

                Text(selectedMode.shortDescription)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            }

            if selectedMode == .vengeance {
                Toggle(isOn: Binding(get: { brutalMode }, set: onSetBrutalMode)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Brutal Mode")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text(ScoringRules.brutalModeDescription)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Brutal Mode")
                .accessibilityHint("Changes scoring for the next game")
            }
        }
        .padding(20)
        .cardSurface(cornerRadius: 22)
        .animation(DesignMotion.animation(.fast), value: selectedMode)
    }
}

private struct SetupHeroCard: View {
    let animateTitle: Bool

    var body: some View {
        AppTitleView(showTagline: false, allowsAnimation: animateTitle)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .cardSurface(cornerRadius: 26)
    }
}

private struct SetupTargetScoreCard: View {
    @Binding var targetScore: Int
    let themeAccent: Color
    @Binding var showingTargetScoreEditor: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private let presets = [150, 200, 250, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Target Score")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                .textCase(.uppercase)

            HStack(spacing: 18) {
                Button(action: { targetScore = max(50, targetScore - 25) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(targetScore > 50 ? themeAccent : Color(.systemGray4))
                }
                .disabled(targetScore <= 50)

                Spacer()

                Button(action: { showingTargetScoreEditor = true }) {
                    VStack(spacing: 4) {
                        Text("\(targetScore)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                            .contentTransition(.numericText())
                        Text("Tap to type")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    }
                    .frame(minWidth: 110)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { targetScore = min(5000, targetScore + 25) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(targetScore < 5000 ? themeAccent : Color(.systemGray4))
                }
                .disabled(targetScore >= 5000)
            }

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: { targetScore = preset }) {
                        Text("\(preset)")
                            .frame(maxWidth: .infinity)
                    }
                    .modifier(
                        TargetScorePresetStyleModifier(
                            isSelected: preset == targetScore,
                            fill: themeAccent
                        )
                    )
                }
            }
        }
        .padding(20)
        .cardSurface(cornerRadius: 22)
        .animation(.snappy(duration: 0.2), value: targetScore)
    }
}

private struct TargetScorePresetStyleModifier: ViewModifier {
    let isSelected: Bool
    let fill: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content.buttonStyle(PrimaryPillButtonStyle(fill: fill))
        } else {
            content.buttonStyle(SecondaryPillButtonStyle())
        }
    }
}

private struct PrimaryPillButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(fill.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignMotion.animation(.fast), value: configuration.isPressed)
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let surface = DesignColor.color(.surfaceInteractive, theme: visualTheme, colorScheme: colorScheme)
        let border = DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme).opacity(0.12)

        return configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(surface.opacity(configuration.isPressed ? 0.88 : 1))
            )
            .overlay(
                Capsule()
                    .stroke(border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignMotion.animation(.fast), value: configuration.isPressed)
    }
}
