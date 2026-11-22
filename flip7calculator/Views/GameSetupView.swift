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
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var themeAccent: Color {
        DesignColor.color(
            .brandPrimary,
            theme: visualTheme,
            colorScheme: colorScheme,
            accentOverride: selectedTheme.hasCustomAccent ? selectedTheme.accentColor : nil
        )
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
                VStack(spacing: 16) {
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
                        Button(action: {
                            HapticFeedback.light()
                            targetScore = 200
                        }) {
                            Text("Reset to 200")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 132)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                focusCoordinator.clearFocus()
            }
            .navigationBarTitleDisplayMode(.inline)
            .appChromeBackground()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                        .overlay(DesignColor.border(theme: visualTheme, colorScheme: colorScheme))

                    Button(action: {
                        HapticFeedback.success()
                        startGame()
                    }) {
                        Text(effectiveEntryIntent == .playWithDealer ? "Start Simulator" : "Start Scoring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canStartGame)
                    .accessibilityIdentifier("setup.startGame")
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
                    .frame(maxWidth: 760)
                }
                .frame(maxWidth: .infinity)
                .background(
                    DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
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
                    .accessibilityLabel("Scoring Guide")
                }
            }
            .sheet(isPresented: $showingTargetScoreEditor) {
                TargetScoreEditorSheet(targetScore: $targetScore) { newScore in
                    targetScore = newScore
                }
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(themeAccent)
            }
            .sheet(isPresented: $showingRules) {
                AppHelpView()
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(themeAccent)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(themeAccent)
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
                if !isShowing {
                    loadPersistedRoster()
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
            playerRows = [PlayerNameRow(), PlayerNameRow()]
        }
        focusCoordinator.setOrder(playerRows.map(\.id))
    }

    private var canStartGame: Bool {
        playerRows.count >= 2 && playerRows.count <= 8
    }

    private func clearPlayers() {
        HapticFeedback.light()
        playerRows = [PlayerNameRow(), PlayerNameRow()]
        focusCoordinator.setOrder(playerRows.map(\.id))
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
        focusCoordinator.setOrder(playerRows.map(\.id))
    }
}

private struct SetupPlayStyleCard: View {
    let selectedIntent: GameEntryIntent
    let dealerEnabled: Bool
    let onSelect: (GameEntryIntent) -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            Text("How are you playing?")
                .font(DesignTypography.font(.label))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                .textCase(.uppercase)

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
        }
        .padding(DesignSpacing.md)
        .cardSurface(cornerRadius: 20)
        .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: selectedIntent)
    }

    private func intentButton(_ intent: GameEntryIntent, isEnabled: Bool) -> some View {
        let isSelected = selectedIntent == intent
        return Button(action: {
            HapticFeedback.selection()
            onSelect(intent)
        }) {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : intent.icon)
                    .font(.system(.subheadline, weight: .semibold))
                Text(intent.title)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 28)
        }
        .buttonStyle(SelectionCardButtonStyle(isSelected: isSelected))
        .disabled(!isEnabled)
        .accessibilityLabel(intent.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isEnabled ? intent.detail : "Available for Classic games")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("setup.entry.\(intent.rawValue)")
    }
}

private struct SetupRiskInsightsCard: View {
    @Binding var riskInsightsModeRaw: String
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    private var selectedMode: RiskInsightsMode {
        RiskInsightsMode(rawValue: riskInsightsModeRaw) ?? .off
    }

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Risk Insights")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                Text("Optional duplicate and bust context")
                    .font(DesignTypography.font(.caption))
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
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(DesignTypography.font(.label))
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
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                }

                Text(selectedMode.shortDescription)
                    .font(DesignTypography.font(.caption))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            }

            if selectedMode == .vengeance {
                Toggle(isOn: Binding(get: { brutalMode }, set: onSetBrutalMode)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Brutal Mode")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        Text(ScoringRules.brutalModeDescription)
                            .font(DesignTypography.font(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Brutal Mode")
                .accessibilityHint("Changes scoring for the next game")
            }
        }
        .padding(18)
        .cardSurface(cornerRadius: 20)
        .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: selectedMode)
    }
}

private struct SetupHeroCard: View {
    let animateTitle: Bool

    var body: some View {
        AppTitleView(showTagline: false, allowsAnimation: animateTitle)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .cardSurface(cornerRadius: 24)
    }
}

private struct SetupTargetScoreCard: View {
    @Binding var targetScore: Int
    let themeAccent: Color
    @Binding var showingTargetScoreEditor: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private let presets = [150, 200, 250, 300]

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Target Score")
                .font(DesignTypography.font(.label))
                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                .textCase(.uppercase)

            HStack(spacing: 18) {
                Button(action: {
                    HapticFeedback.light()
                    targetScore = max(50, targetScore - 25)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(targetScore > 50 ? themeAccent : Color(.systemGray4))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(KeycapButtonStyle(pressedScale: 0.92))
                .disabled(targetScore <= 50)
                .accessibilityLabel("Decrease target score by 25")

                Spacer()

                Button(action: {
                    HapticFeedback.light()
                    showingTargetScoreEditor = true
                }) {
                    VStack(spacing: 3) {
                        Text("\(targetScore)")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .monospacedDigit()
                            .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                            .contentTransition(.numericText())
                        Text("Tap to type")
                            .font(DesignTypography.font(.caption))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    }
                    .frame(minWidth: 110)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Target score \(targetScore)")
                .accessibilityHint("Opens keyboard to enter a custom target score")

                Spacer()

                Button(action: {
                    HapticFeedback.light()
                    targetScore = min(5000, targetScore + 25)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(targetScore < 5000 ? themeAccent : Color(.systemGray4))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(KeycapButtonStyle(pressedScale: 0.92))
                .disabled(targetScore >= 5000)
                .accessibilityLabel("Increase target score by 25")
            }

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: {
                        HapticFeedback.selection()
                        targetScore = preset
                    }) {
                        Text("\(preset)")
                            .monospacedDigit()
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
        .padding(18)
        .cardSurface(cornerRadius: 20)
        .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: targetScore)
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(fill.contrastingForeground)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(fill.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .scaleEffect(configuration.isPressed && !isReducedMotion ? 0.97 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    func makeBody(configuration: Configuration) -> some View {
        let surface = DesignColor.color(.surfaceKeycap, theme: visualTheme, colorScheme: colorScheme)
        let border = visualTheme == .v2 ? AppBrandPalette.keycapBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.45)

        return configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(surface.opacity(configuration.isPressed ? 0.84 : 1))
            )
            .overlay(
                Capsule()
                    .stroke(border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !isReducedMotion ? 0.97 : 1)
            .animation(DesignMotion.animation(.press, reduced: isReducedMotion), value: configuration.isPressed)
    }
}
