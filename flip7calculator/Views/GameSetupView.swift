//
//  GameSetupView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct GameSetupView: View {
    @Binding var viewModel: GameViewModel
    @State private var playerRows: [PlayerNameRow] = [PlayerNameRow(), PlayerNameRow()]
    @State private var targetScore: Int = 200
    @StateObject private var focusCoordinator = FocusCoordinator()
    @State private var hasLoadedRoster = false
    @State private var hasLoadedTargetScore = false
    @State private var showingTargetScoreEditor = false
    @State private var showingRules = false
    @State private var showingSettings = false
    
    @AppStorage("defaultTargetScore") private var defaultTargetScore: Int = 200
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

    private var filledPlayerCount: Int {
        playerRows.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    private var deckSummary: String {
        let deckProfile = PersistedDeckProfile.load().deckProfile
        return "\(deckProfile.totalCardCount)-card deck"
    }

    private var playerSummary: String {
        let count = playerRows.count
        return "\(count) \(count == 1 ? "player" : "players")"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SetupHeroCard(themeAccent: themeAccent)

                    PlayersEditorCard(
                        playerRows: $playerRows,
                        focusCoordinator: focusCoordinator,
                        onPersist: persistRosterOrder
                    )

                    if playerRows.count > 2 || playerRows.contains(where: { !$0.name.isEmpty }) {
                        Button(action: clearPlayers) {
                            Text("Reset players")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }

                    SetupTargetScoreCard(
                        targetScore: $targetScore,
                        themeAccent: themeAccent,
                        showingTargetScoreEditor: $showingTargetScoreEditor
                    )

                    if targetScore != 200 {
                        Button(action: { targetScore = 200 }) {
                            Text("Reset to 200")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                }
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
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("\(playerSummary) • target \(targetScore) • \(deckSummary)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                            .multilineTextAlignment(.center)

                        Text(filledPlayerCount == 0 ? "Blank names become Player 1, Player 2, and so on." : "Names save automatically, so the next game is ready faster.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme).opacity(0.92))
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        HapticFeedback.success()
                        startGame()
                    }) {
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canStartGame)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
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
            .onAppear {
                if !hasLoadedRoster {
                    loadPersistedRoster()
                    hasLoadedRoster = true
                }
                if !hasLoadedTargetScore {
                    targetScore = defaultTargetScore
                    hasLoadedTargetScore = true
                }
            }
            .onChange(of: targetScore) { _, newValue in
                defaultTargetScore = newValue
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
        viewModel.startNewGame(players: players, targetScore: targetScore)
    }
    
    private func persistRosterOrder() {
        let names = playerRows.map { $0.name.trimmingCharacters(in: .whitespaces) }
        PersistedRoster(names: names).save()
        focusCoordinator.setOrder(playerRows.map { $0.id })
    }
}

private struct SetupHeroCard: View {
    let themeAccent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppTitleView(showTagline: false)

            HStack(spacing: 8) {
                SetupFeatureChip(icon: "bolt.fill", label: "Fast entry", tint: themeAccent)
                SetupFeatureChip(icon: "wifi.slash", label: "Offline", tint: AppBrandPalette.brandBlueSky)
                SetupFeatureChip(icon: "arrow.uturn.backward.circle", label: "Undo ready", tint: AppBrandPalette.gold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .cardSurface(cornerRadius: 26)
    }
}

private struct SetupFeatureChip: View {
    let icon: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tint.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.18), lineWidth: 0.8)
        )
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Score")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                        .textCase(.uppercase)

                    Text("Quick presets keep setup moving, and you can tap the score for an exact value.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

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
