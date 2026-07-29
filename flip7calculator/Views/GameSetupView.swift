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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SetupHeroCard(animateTitle: animateTitle)

                    PlayersEditorCard(
                        playerRows: $playerRows,
                        focusCoordinator: focusCoordinator,
                        onPersist: persistRosterOrder,
                        onReset: clearPlayers,
                        showsPlayerSummary: false
                    )

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
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canStartGame)
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
