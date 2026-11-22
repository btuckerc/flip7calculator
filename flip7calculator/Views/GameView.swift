//
//  GameView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

enum ActiveConfirmation {
    case newRound
    case newGame
}

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    var hidesWinnerBanner: Bool = false
    @State private var selectedPlayerId: UUID?
    @State private var showingBustBanner = false
    @State private var bustNumber: Int?
    @State private var activeConfirmation: ActiveConfirmation?
    @State private var showingSettings = false
    @State private var showingGameOverOverlay = false
    @State private var showingRules = false

    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private var themeAccent: Color {
        DesignColor.color(
            .brandPrimary,
            theme: visualTheme,
            colorScheme: colorScheme,
            accentOverride: selectedTheme.hasCustomAccent ? selectedTheme.accentColor : nil
        )
    }

    private var winnerColor: Color {
        DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var playerColors: [Color] {
        guard let game = viewModel.game else { return [] }
        return PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette)
    }

    private var wouldProduceWinner: Bool {
        viewModel.game?.previewHasUniqueWinner ?? false
    }

    private var gameHasWinner: Bool {
        viewModel.game?.hasWinner ?? false
    }

    private var gameIsCompletedWithWinner: Bool {
        viewModel.game?.isCompletedWithWinner ?? false
    }

    private var hasSelection: Bool {
        guard let selectedPlayerId, let game = viewModel.game else { return false }
        return game.players.contains(where: { $0.id == selectedPlayerId })
    }

    var body: some View {
        if let game = viewModel.game {
            NavigationStack {
                Group {
                    if horizontalSizeClass == .regular {
                        GeometryReader { geometry in
                            let isLandscape = geometry.size.width > geometry.size.height
                            if isLandscape {
                                HStack(alignment: .center, spacing: DesignSpacing.lg) {
                                    PlayerGrid(
                                        players: game.players,
                                        playerColors: playerColors,
                                        selectedPlayerId: selectedPlayerId,
                                        scoringRules: game.scoringRules,
                                        isRegularPortrait: false,
                                        onSelect: selectPlayer
                                    )
                                    .frame(maxWidth: 460, maxHeight: .infinity, alignment: .center)

                                    entryColumn(game: game)
                                        .frame(maxWidth: 540, alignment: .center)
                                }
                                .padding(.horizontal, DesignSpacing.lg)
                                .padding(.vertical, DesignSpacing.md)
                                .frame(maxWidth: 1060, maxHeight: .infinity, alignment: .center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            } else {
                                VStack(spacing: DesignSpacing.lg) {
                                    PlayerGrid(
                                        players: game.players,
                                        playerColors: playerColors,
                                        selectedPlayerId: selectedPlayerId,
                                        scoringRules: game.scoringRules,
                                        isRegularPortrait: true,
                                        onSelect: selectPlayer
                                    )
                                    .frame(maxHeight: .infinity, alignment: .top)

                                    entryColumn(game: game)
                                }
                                .padding(.horizontal, DesignSpacing.xl)
                                .padding(.top, DesignSpacing.lg)
                                .padding(.bottom, DesignSpacing.md)
                                .frame(maxWidth: 820, maxHeight: .infinity, alignment: .center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            PlayerGrid(
                                players: game.players,
                                playerColors: playerColors,
                                selectedPlayerId: selectedPlayerId,
                                scoringRules: game.scoringRules,
                                onSelect: selectPlayer
                            )
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                            .frame(maxHeight: .infinity, alignment: .top)

                            entryColumn(game: game)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomActionBar(game: game)
                }
                .navigationTitle("Round \(game.currentRoundNumber)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Scoring Guide", systemImage: "questionmark.circle") {
                                showingRules = true
                            }
                            Divider()
                            Button("New Game", systemImage: "plus.circle", role: .destructive) {
                                activeConfirmation = .newGame
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Game options")
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(viewModel: viewModel)
                        .preferredColorScheme(selectedTheme.colorScheme)
                        .tint(themeAccent)
                }
                .sheet(isPresented: $showingRules) {
                    AppHelpView(scoringRules: game.scoringRules)
                        .preferredColorScheme(selectedTheme.colorScheme)
                        .tint(themeAccent)
                }
                .toolbar(showingGameOverOverlay || activeConfirmation != nil ? .hidden : .visible, for: .navigationBar)
                .overlay {
                    if let confirmation = activeConfirmation {
                        ConfirmationOverlay(
                            title: confirmationTitle(for: confirmation),
                            message: confirmationMessage(for: confirmation, game: game),
                            primaryActionTitle: confirmationButtonTitle(for: confirmation),
                            primaryActionRole: confirmation == .newGame ? .destructive : nil,
                            onPrimary: {
                                if confirmation == .newRound {
                                    HapticFeedback.success()
                                    if wouldProduceWinner {
                                        viewModel.endRound()
                                        selectedPlayerId = nil
                                        showingGameOverOverlay = true
                                    } else {
                                        viewModel.startNewRound()
                                        if let updatedGame = viewModel.game {
                                            selectedPlayerId = GameFlow.preferredSelection(
                                                in: updatedGame,
                                                currentSelection: nil
                                            )
                                        } else {
                                            selectedPlayerId = nil
                                        }
                                    }
                                } else {
                                    HapticFeedback.medium()
                                    viewModel.endGame()
                                }
                            },
                            onDismiss: {
                                activeConfirmation = nil
                            }
                        )
                    }

                    if showingGameOverOverlay {
                        GameOverOverlay(
                            viewModel: viewModel,
                            onPlayAgain: {
                                showingGameOverOverlay = false
                                viewModel.restartGameKeepingSettings()
                                syncSelectionIfNeeded()
                            },
                            onNewGame: {
                                showingGameOverOverlay = false
                                viewModel.endGame()
                            },
                            onUndo: {
                                showingGameOverOverlay = false
                            }
                        )
                    }
                }
                .onAppear {
                    if gameIsCompletedWithWinner {
                        selectedPlayerId = nil
                        showingGameOverOverlay = true
                    } else {
                        syncSelectionIfNeeded()
                    }
                }
                .onChange(of: game.players.map(\.id)) { _, _ in
                    syncSelectionIfNeeded()
                }
                .onChange(of: gameIsCompletedWithWinner) { _, isCompleted in
                    showingGameOverOverlay = isCompleted
                    if isCompleted {
                        selectedPlayerId = nil
                    } else {
                        syncSelectionIfNeeded()
                    }
                }
                .appChromeBackground()
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func entryColumn(game: Game) -> some View {
        ZStack {
            SelectedPlayerPanel(
                game: game,
                selectedPlayerId: selectedPlayerId,
                playerColors: playerColors,
                viewModel: viewModel,
                showingBustBanner: $showingBustBanner,
                bustNumber: $bustNumber,
                onNumberTap: handleNumberTap
            )
            .opacity(hasSelection ? 1 : 0)
            .allowsHitTesting(hasSelection)
            .accessibilityHidden(!hasSelection)

            if !hasSelection {
                RoundSettledPlaceholder(
                    inRoundCount: GameFlow.inRoundCount(in: game),
                    onFinishRound: { activeConfirmation = .newRound }
                )
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .animation(DesignMotion.animation(.fast, reduced: isReducedMotion), value: selectedPlayerId)
    }

    @ViewBuilder
    private func bottomActionBar(game: Game) -> some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(DesignColor.border(theme: visualTheme, colorScheme: colorScheme))

            if game.isCompletedWithWinner && !showingGameOverOverlay && !hidesWinnerBanner {
                HStack(spacing: 5) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(winnerColor)
                    Text(game.winners.map(\.name).joined(separator: ", "))
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(winnerColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            }

            HStack {
                Button(action: {
                    activeConfirmation = .newRound
                }) {
                    Text("Next Round")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(themeAccent)
                        .padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 14) {
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(viewModel.canUndo ? themeAccent : Color(.systemGray3).opacity(0.45))
                    }
                    .buttonStyle(KeycapButtonStyle(pressedScale: 0.92))
                    .disabled(!viewModel.canUndo)
                    .accessibilityLabel("Undo")

                    Button(action: {
                        HapticFeedback.light()
                        viewModel.redo()
                    }) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(viewModel.canRedo ? themeAccent : Color(.systemGray3).opacity(0.45))
                    }
                    .buttonStyle(KeycapButtonStyle(pressedScale: 0.92))
                    .disabled(!viewModel.canRedo)
                    .accessibilityLabel("Redo")
                }

                Button(action: {
                    handleContinueTap(game: game)
                }) {
                    HStack(spacing: 6) {
                        Text("Continue")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 17))
                    }
                    .foregroundStyle(themeAccent.contrastingForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(themeAccent))
                }
                .buttonStyle(KeycapButtonStyle(pressedScale: 0.95))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme))
        }
    }

    // MARK: - Helpers

    private func selectPlayer(_ id: UUID) {
        selectedPlayerId = id
        showingBustBanner = false
        bustNumber = nil
    }

    private func syncSelectionIfNeeded() {
        guard let game = viewModel.game else {
            selectedPlayerId = nil
            return
        }
        if let current = selectedPlayerId,
           game.players.contains(where: { $0.id == current }) {
            return
        }
        selectedPlayerId = GameFlow.preferredSelection(in: game, currentSelection: nil)
    }

    private func handleContinueTap(game: Game) {
        if let nextId = GameFlow.nextInRoundPlayerId(from: selectedPlayerId, players: game.players) {
            if nextId == selectedPlayerId {
                activeConfirmation = .newRound
            } else {
                selectedPlayerId = nextId
                showingBustBanner = false
                bustNumber = nil
                HapticFeedback.selection()
            }
        } else {
            activeConfirmation = .newRound
        }
    }

    private func confirmationTitle(for confirmation: ActiveConfirmation) -> String {
        switch confirmation {
        case .newRound:
            return wouldProduceWinner ? "Finish Game?" : "Finish Round?"
        case .newGame:
            return "New Game"
        }
    }

    private func confirmationMessage(for confirmation: ActiveConfirmation, game: Game) -> String {
        switch confirmation {
        case .newRound:
            if wouldProduceWinner {
                let previewScores = game.players.map {
                    ($0.name, ScoreEngine.previewTotalScore(player: $0, rules: game.scoringRules))
                }
                let maxScore = previewScores.map(\.1).max() ?? 0
                let winners = previewScores.filter { $0.1 == maxScore && $0.1 >= game.targetScore }

                if winners.count == 1 {
                    return "\(winners[0].0) will win with \(winners[0].1) points!\n\n" + nextRoundConfirmationMessage(game: game)
                } else {
                    let names = winners.map(\.0).joined(separator: " & ")
                    return "\(names) will tie for the win with \(maxScore) points!\n\n" + nextRoundConfirmationMessage(game: game)
                }
            } else {
                return nextRoundConfirmationMessage(game: game)
            }
        case .newGame:
            return "This will end the current game and return to setup."
        }
    }

    private func confirmationButtonTitle(for confirmation: ActiveConfirmation) -> String {
        switch confirmation {
        case .newRound:
            return wouldProduceWinner ? "Finish Game" : "Next Round"
        case .newGame:
            return "Start New Game"
        }
    }

    private func handleNumberTap(playerId: UUID, number: Int) {
        guard let game = viewModel.game,
              let player = game.players.first(where: { $0.id == playerId }) else {
            return
        }

        if player.currentRound.hand.selectedNumbers.contains(number) {
            viewModel.removeCardFromPlayer(playerId, number: number)
            return
        }

        let isDuplicate = viewModel.addCardToPlayer(playerId, number: number)
        if isDuplicate {
            bustNumber = number
            showingBustBanner = true
        }
    }

    private func nextRoundConfirmationMessage(game: Game) -> String {
        var parts: [String] = []

        let bustedPlayers = game.players.filter { $0.currentRound.state == .busted }
        let inRoundPlayers = game.players.filter { $0.currentRound.state == .inRound }

        let scoringPlayers = game.players.filter { player in
            ScoreEngine.calculateRoundScore(round: player.currentRound, rules: game.scoringRules) != 0
        }

        if !scoringPlayers.isEmpty {
            let names = scoringPlayers.map {
                let score = ScoreEngine.calculateRoundScore(round: $0.currentRound, rules: game.scoringRules)
                return "\($0.name) (\(score > 0 ? "+" : "")\(score))"
            }
            parts.append("Scoring: \(names.joined(separator: ", "))")
        }

        if !bustedPlayers.isEmpty {
            let names = bustedPlayers.map { player in
                let score = ScoreEngine.calculateRoundScore(round: player.currentRound, rules: game.scoringRules)
                return game.scoringRules.brutalMode ? "\(player.name) (\(score))" : player.name
            }
            parts.append("Busted\(game.scoringRules.brutalMode ? "" : " (0 pts)"): \(names.joined(separator: ", "))")
        }

        if !inRoundPlayers.isEmpty {
            let inRoundWithCards = inRoundPlayers.filter {
                !$0.currentRound.hand.isEmpty || $0.currentRound.manualScoreOverride != nil
            }
            let inRoundNoCards = inRoundPlayers.filter {
                $0.currentRound.hand.isEmpty && $0.currentRound.manualScoreOverride == nil
            }

            if !inRoundWithCards.isEmpty {
                let names = inRoundWithCards.map { player in
                    let score = ScoreEngine.calculateRoundScore(
                        round: player.currentRound,
                        rules: game.scoringRules
                    )
                    return "\(player.name) (\(score > 0 ? "+" : "")\(score))"
                }
                parts.append("Still in round (will score): \(names.joined(separator: ", "))")
            }
            if !inRoundNoCards.isEmpty {
                let names = inRoundNoCards.map(\.name)
                parts.append("No cards drawn: \(names.joined(separator: ", "))")
            }
        }

        if parts.isEmpty {
            return "All scores will be finalized and a new round will begin."
        }

        return parts.joined(separator: "\n")
    }
}

private struct RoundSettledPlaceholder: View {
    let inRoundCount: Int
    let onFinishRound: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: inRoundCount == 0 ? "checkmark.seal.fill" : "hand.tap.fill")
                .font(.title2)
                .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride))

            Text(inRoundCount == 0 ? "All players settled" : "Tap a player to score")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))

            Text(
                inRoundCount == 0
                    ? "Tap any player tile to review their hand, or finish this round."
                    : "Select any player tile above to add cards or modifiers."
            )
            .font(DesignTypography.font(.caption))
            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            .multilineTextAlignment(.center)

            if inRoundCount == 0 {
                Button("Finish Round", action: onFinishRound)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 4)
            }
        }
        .padding(DesignSpacing.lg)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: DesignRadius.lg)
    }
}

// MARK: - Selected Player Panel

struct SelectedPlayerPanel: View {
    let game: Game
    let selectedPlayerId: UUID?
    let playerColors: [Color]
    @Bindable var viewModel: GameViewModel
    @Binding var showingBustBanner: Bool
    @Binding var bustNumber: Int?
    let onNumberTap: (UUID, Int) -> Void

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("riskInsightsMode") private var riskInsightsModeRaw: String = RiskInsightsMode.off.rawValue
    @State private var showingRiskInsight = false

    private var effectivePlayer: Player {
        if let id = selectedPlayerId,
           let player = game.players.first(where: { $0.id == id }) {
            return player
        }
        return game.players.first ?? Player(name: "")
    }

    private var effectivePlayerId: UUID {
        selectedPlayerId ?? (game.players.first?.id ?? UUID())
    }

    private var playerIndex: Int {
        game.players.firstIndex(where: { $0.id == effectivePlayerId }) ?? 0
    }

    private var playerColor: Color {
        playerColors[safe: playerIndex] ?? DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var bonusColor: Color {
        DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme)
    }

    private var riskInsightsMode: RiskInsightsMode {
        RiskInsightsMode(rawValue: riskInsightsModeRaw) ?? .off
    }

    var body: some View {
        let player = effectivePlayer
        let selectedId = effectivePlayerId
        let availability = viewModel.roundAvailability

        VStack(spacing: 8) {
            // Player header with mode tag and 7-card bonus badge
            HStack(spacing: 8) {
                Circle()
                    .fill(playerColor)
                    .frame(width: 10, height: 10)

                Text(player.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(game.scoringRules.brutalMode ? "BRUTAL" : game.scoringRules.mode.displayName.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(
                        game.scoringRules.brutalMode
                            ? DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
                            : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                    )
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            (game.scoringRules.brutalMode
                                ? DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
                                : DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                                .opacity(0.14)
                        )
                    )

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(bonusColor)
                    Text("+\(AppBrand.sevenCardBonusValue)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(bonusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.18 : 0.22))
                )
                .opacity(player.currentRound.hand.hasSevenCardBonus ? 1 : 0)
                .accessibilityHidden(!player.currentRound.hand.hasSevenCardBonus)
            }
            .padding(.horizontal, 12)

            if riskInsightsMode != .off,
               let insight = ProbabilityService.calculatorEstimate(for: selectedId, in: game) {
                HStack {
                    RiskPillButton(
                        insight: insight,
                        mode: riskInsightsMode,
                        action: { showingRiskInsight = true }
                    )
                    Spacer()
                }
                .padding(.horizontal, 12)
            }

            PlayerActionButtons(
                player: player,
                selectedId: selectedId,
                viewModel: viewModel,
                scoringRules: game.scoringRules
            )
            .padding(.horizontal, 12)

            if game.scoringRules.brutalMode && player.currentRound.hand.hasSevenCardBonus {
                BrutalBonusChoiceRow(
                    sourcePlayer: player,
                    players: game.players,
                    onSelectTarget: { targetId in
                        viewModel.setSevenCardBonusTarget(
                            sourcePlayerId: selectedId,
                            targetPlayerId: targetId
                        )
                    }
                )
                .padding(.horizontal, 12)
            }

            let hasManualOverride = player.currentRound.manualScoreOverride != nil
            let allowsActionEdits = game.scoringRules.mode == .vengeance
                && player.currentRound.state != .busted
            let canEditCards = !hasManualOverride
                && (player.currentRound.state == .inRound || allowsActionEdits)
            let canEditBrutalModifiers = !hasManualOverride
                && game.scoringRules.brutalMode
                && player.currentRound.state == .busted
            let canEditVengeanceModifiers = canEditCards || canEditBrutalModifiers
            let isManualScoreLocked = player.currentRound.state == .busted && !game.scoringRules.brutalMode

            let deckProfile = game.deckProfile
            let hasOnlyOneOfEachModifier = game.scoringRules.mode == .classic
                ? deckProfile.addModifierCounts.values.allSatisfy { $0 <= 1 } && deckProfile.x2Count <= 1
                : deckProfile.subtractModifierCounts.values.allSatisfy { $0 <= 1 } && deckProfile.divideByTwoCount <= 1

            QuickCardPicker(
                player: player,
                scoringRules: game.scoringRules,
                availability: availability,
                canEditCards: canEditCards,
                canEditVengeanceModifiers: canEditVengeanceModifiers,
                onTapNumber: { number in
                    onNumberTap(selectedId, number)
                },
                onTapSpecialNumber: { card in
                    if player.currentRound.hand.specialNumbers.contains(card) {
                        viewModel.removeSpecialNumberFromPlayer(selectedId, card: card)
                    } else {
                        viewModel.addSpecialNumberToPlayer(selectedId, card: card)
                    }
                },
                onIncrementModifier: { value in
                    let deckCount = game.deckProfile.addModifierCounts[value] ?? 0
                    let playerCount = player.currentRound.hand.addMods[value] ?? 0
                    if deckCount == 1 && playerCount > 0 {
                        viewModel.removeModifierFromPlayer(selectedId, value: value)
                    } else {
                        viewModel.addModifierToPlayer(selectedId, value: value)
                    }
                },
                onDecrementModifier: { value in
                    viewModel.removeModifierFromPlayer(selectedId, value: value)
                },
                onIncrementX2: {
                    let deckCount = game.deckProfile.x2Count
                    let playerCount = player.currentRound.hand.x2Count
                    if deckCount == 1 && playerCount > 0 {
                        viewModel.removeX2FromPlayer(selectedId)
                    } else {
                        viewModel.addX2ToPlayer(selectedId)
                    }
                },
                onDecrementX2: {
                    viewModel.removeX2FromPlayer(selectedId)
                },
                onIncrementSubtractModifier: { value in
                    let deckCount = game.deckProfile.subtractModifierCounts[value] ?? 0
                    let playerCount = player.currentRound.hand.subtractMods[value] ?? 0
                    if deckCount == 1 && playerCount > 0 {
                        viewModel.removeSubtractModifierFromPlayer(selectedId, value: value)
                    } else {
                        viewModel.addSubtractModifierToPlayer(selectedId, value: value)
                    }
                },
                onDecrementSubtractModifier: { value in
                    viewModel.removeSubtractModifierFromPlayer(selectedId, value: value)
                },
                onIncrementDivideByTwo: {
                    let deckCount = game.deckProfile.divideByTwoCount
                    let playerCount = player.currentRound.hand.divideByTwoCount
                    if deckCount == 1 && playerCount > 0 {
                        viewModel.removeDivideByTwoFromPlayer(selectedId)
                    } else {
                        viewModel.addDivideByTwoToPlayer(selectedId)
                    }
                },
                onDecrementDivideByTwo: {
                    viewModel.removeDivideByTwoFromPlayer(selectedId)
                },
                showingBustBanner: showingBustBanner,
                bustNumber: bustNumber,
                onConfirmBust: {
                    viewModel.bustPlayer(selectedId)
                    showingBustBanner = false
                    bustNumber = nil
                },
                onUndoBust: {
                    viewModel.undo()
                    showingBustBanner = false
                    bustNumber = nil
                },
                isManualScoreEnabled: !isManualScoreLocked,
                onSaveManualScore: { score in
                    viewModel.setManualScoreOverride(selectedId, score: score)
                },
                onClearManualScore: {
                    HapticFeedback.light()
                    viewModel.clearManualScoreOverride(selectedId)
                },
                onClearRound: {
                    HapticFeedback.light()
                    viewModel.clearPlayerRoundEntry(selectedId)
                },
                hasOnlyOneOfEachModifier: hasOnlyOneOfEachModifier
            )
            .padding(.horizontal, 12)
        }
        .sheet(isPresented: $showingRiskInsight) {
            if let insight = ProbabilityService.calculatorEstimate(for: selectedId, in: game) {
                RiskInsightSheet(insight: insight)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                .fill(DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignRadius.lg, style: .continuous)
                .stroke(
                    visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator).opacity(0.35),
                    lineWidth: 1
                )
        )
    }
}

private struct BrutalBonusChoiceRow: View {
    let sourcePlayer: Player
    let players: [Player]
    let onSelectTarget: (UUID?) -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var selectedTarget: Player? {
        guard let targetId = sourcePlayer.currentRound.sevenCardBonusTargetId else { return nil }
        return players.first(where: { $0.id == targetId })
    }

    private var dangerColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "burst.fill")
                .foregroundStyle(dangerColor)

            Text("7-card reward")
                .font(.system(.caption, design: .rounded, weight: .semibold))

            Spacer()

            Menu {
                Button {
                    onSelectTarget(nil)
                } label: {
                    Label("Keep +15", systemImage: "plus.circle")
                }

                ForEach(players.filter { $0.id != sourcePlayer.id }) { player in
                    Button {
                        onSelectTarget(player.id)
                    } label: {
                        Label("Give \(player.name) -15", systemImage: "minus.circle")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedTarget.map { "\($0.name) −15" } ?? "Keep +15")
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(dangerColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(dangerColor.opacity(0.14)))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Player Action Buttons

struct PlayerActionButtons: View {
    let player: Player
    let selectedId: UUID
    @Bindable var viewModel: GameViewModel
    let scoringRules: ScoringRules
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var bankColor: Color {
        DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
    }

    private var bustColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    private var freezeColor: Color {
        DesignColor.color(.stateFrozen, theme: visualTheme, colorScheme: colorScheme)
    }

    private var resumeColor: Color {
        DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                ActionPillButton(
                    title: scoringRules.mode == .vengeance ? "Stay" : "Bank",
                    icon: "checkmark.circle.fill",
                    color: bankColor,
                    action: {
                        HapticFeedback.success()
                        viewModel.bankPlayer(selectedId)
                    }
                )

                ActionPillButton(
                    title: "Bust",
                    icon: "xmark.circle.fill",
                    color: bustColor,
                    action: {
                        HapticFeedback.error()
                        viewModel.bustPlayer(selectedId)
                    }
                )

                ActionPillButton(
                    title: scoringRules.mode == .vengeance ? "Forced Stay" : "Freeze",
                    icon: "snowflake",
                    color: freezeColor,
                    action: {
                        HapticFeedback.medium()
                        viewModel.freezePlayer(selectedId)
                    }
                )
            }
            .opacity(player.currentRound.state == .inRound ? 1 : 0)
            .allowsHitTesting(player.currentRound.state == .inRound)
            .accessibilityHidden(player.currentRound.state != .inRound)

            settledStateRow(
                icon: "xmark.circle.fill",
                label: "Busted",
                tint: bustColor,
                isVisible: player.currentRound.state == .busted
            )

            settledStateRow(
                icon: "checkmark.circle.fill",
                label: scoringRules.mode == .vengeance ? "Stayed" : "Banked",
                tint: bankColor,
                isVisible: player.currentRound.state == .banked
            )

            settledStateRow(
                icon: "snowflake",
                label: scoringRules.mode == .vengeance ? "Forced Stay" : "Frozen",
                tint: freezeColor,
                isVisible: player.currentRound.state == .frozen
            )
        }
        .frame(height: horizontalSizeClass == .regular ? 46 : 38)
    }

    private func settledStateRow(icon: String, label: String, tint: Color, isVisible: Bool) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity)

            ActionPillButton(
                title: "Resume",
                icon: "arrow.uturn.backward.circle.fill",
                color: resumeColor,
                action: {
                    HapticFeedback.medium()
                    viewModel.setPlayerState(selectedId, state: .inRound)
                }
            )
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
    }
}

// MARK: - Action Pill Button

struct ActionPillButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var pillHeight: CGFloat {
        horizontalSizeClass == .regular ? 44 : 36
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: horizontalSizeClass == .regular ? 14 : 12, weight: .semibold))
                Text(title)
                    .font(.system(size: horizontalSizeClass == .regular ? 14 : 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(color.contrastingForeground)
            .frame(maxWidth: .infinity)
            .frame(height: pillHeight)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(color)
            )
        }
        .buttonStyle(KeycapButtonStyle(pressedScale: 0.96))
        .accessibilityLabel(title)
    }
}
