//
//  GameView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

enum ActiveConfirmation {
    case newRound
    case newGame
}

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @State private var selectedPlayerId: UUID?
    @State private var showingBustBanner = false
    @State private var bustNumber: Int?
    @State private var activeConfirmation: ActiveConfirmation?
    @State private var showingSettings = false
    @State private var showingGameOverOverlay = false
    @State private var showingRules = false
    
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @AppStorage("appTheme") private var appTheme: String = "system"
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    private var themeAccent: Color {
        switch visualTheme {
        case .legacy:
            return selectedTheme.accentColor
        case .v2:
            return DesignColor.color(.brandPrimary, theme: .v2, colorScheme: colorScheme)
        }
    }

    private var winnerColor: Color {
        colorScheme == .dark ? AppBrandPalette.gold : AppBrandPalette.brandBlueDeep
    }
    
    private var playerColors: [Color] {
        guard let game = viewModel.game else { return [] }
        return PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette)
    }
    
    /// Checks if finalizing the current round would produce at least one winner
    private var wouldProduceWinner: Bool {
        guard let game = viewModel.game else { return false }
        return game.previewHasUniqueWinner
    }
    
    /// Checks if the game currently has a winner (scores already banked)
    private var gameHasWinner: Bool {
        viewModel.game?.hasWinner ?? false
    }
    
    /// Whether a player is currently selected (panel should be visible)
    private var hasSelection: Bool {
        selectedPlayerId != nil
    }
    
    var body: some View {
        if let game = viewModel.game {
            NavigationStack {
                VStack(spacing: 0) {
                    // Player grid fills available space above the panel
                    PlayerGrid(
                        players: game.players,
                        playerColors: playerColors,
                        selectedPlayerId: selectedPlayerId,
                        scoringRules: game.scoringRules,
                        onSelect: { id in
                            // Animate only tile selection styling, not layout
                            selectedPlayerId = id
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // Selected player panel - ALWAYS in hierarchy to prevent layout reflow
                    // Uses opacity + hit testing to show/hide without changing layout
                    SelectedPlayerPanel(
                        game: game,
                        selectedPlayerId: selectedPlayerId,
                        playerColors: playerColors,
                        viewModel: viewModel,
                        showingBustBanner: $showingBustBanner,
                        bustNumber: $bustNumber,
                        onNumberTap: { playerId, number in
                            handleNumberTap(playerId: playerId, number: number)
                        }
                    )
                    .opacity(hasSelection ? 1 : 0)
                    .allowsHitTesting(hasSelection)
                    .accessibilityHidden(!hasSelection)
                    // Animate content changes within panel, not the panel appearance
                    .animation(.easeInOut(duration: 0.15), value: selectedPlayerId)
                }
                // Bottom bar pinned via safeAreaInset - prevents content underlap
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        Divider()
                        
                        // Winner indicator (shown above controls when there's a winner)
                        if game.hasWinner {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(winnerColor)
                                Text(game.winners.map { $0.name }.joined(separator: ", "))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(winnerColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                        }
                        
                        HStack {
                            // Next Round button (left side, text button)
                            Button(action: {
                                activeConfirmation = .newRound
                            }) {
                                Text("Next Round")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(themeAccent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Undo/Redo (centered)
                            HStack(spacing: 12) {
                                Button(action: {
                                    HapticFeedback.light()
                                    viewModel.undo()
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(viewModel.canUndo ? themeAccent : .gray.opacity(0.4))
                                }
                                .disabled(!viewModel.canUndo)
                                
                                Button(action: {
                                    HapticFeedback.light()
                                    viewModel.redo()
                                }) {
                                    Image(systemName: "arrow.uturn.forward.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(viewModel.canRedo ? themeAccent : .gray.opacity(0.4))
                                }
                                .disabled(!viewModel.canRedo)
                            }
                            
                            // Continue button (right side)
                            Button(action: {
                                handleContinueTap(game: game)
                            }) {
                                HStack(spacing: 6) {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(themeAccent)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme))
                    }
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
                            Button("Scoring Guide") { showingRules = true }
                            Divider()
                            Button("New Game", role: .destructive) { activeConfirmation = .newGame }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(viewModel: viewModel)
                        .preferredColorScheme(selectedTheme.colorScheme)
                        .tint(themeAccent)
                        .id(appTheme)
                }
                .sheet(isPresented: $showingRules) {
                    AppHelpView(scoringRules: game.scoringRules)
                        .preferredColorScheme(selectedTheme.colorScheme)
                        .tint(themeAccent)
                        .id(appTheme)
                }
                // Hide navigation bar when Game Over overlay is showing
                .toolbar(showingGameOverOverlay ? .hidden : .visible, for: .navigationBar)
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
                                        // This is a winning round - finalize and show game over
                                        viewModel.endRound()
                                        selectedPlayerId = nil
                                        showingGameOverOverlay = true
                                    } else {
                                        // Normal round - start next round
                                        viewModel.startNewRound()
                                        selectedPlayerId = nil
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
                    
                    // Game Over overlay
                    if showingGameOverOverlay {
                        GameOverOverlay(
                            viewModel: viewModel,
                            onPlayAgain: {
                                showingGameOverOverlay = false
                                viewModel.restartGameKeepingSettings()
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
                .onChange(of: gameHasWinner) { _, hasWinner in
                    // Auto-dismiss game over overlay if undo removes winner state
                    if !hasWinner && showingGameOverOverlay {
                        showingGameOverOverlay = false
                    }
                }
                .appChromeBackground()
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Helpers
    
    /// Finds the next player who is still in-round, starting from the current selection.
    /// Returns nil if no players are in-round.
    private func nextInRoundPlayerId(from currentId: UUID?, players: [Player]) -> UUID? {
        let inRoundPlayers = players.filter { $0.currentRound.state == .inRound }
        
        // If no players are in-round, return nil
        guard !inRoundPlayers.isEmpty else { return nil }
        
        // If no current selection, return the first in-round player
        guard let currentId = currentId,
              let currentIndex = players.firstIndex(where: { $0.id == currentId }) else {
            return inRoundPlayers.first?.id
        }
        
        // Find the next in-round player after the current one (wrap around)
        let playersAfterCurrent = players.dropFirst(currentIndex + 1) + players.prefix(currentIndex + 1)
        for player in playersAfterCurrent {
            if player.currentRound.state == .inRound {
                return player.id
            }
        }
        
        // Shouldn't reach here if inRoundPlayers is not empty, but fallback
        return inRoundPlayers.first?.id
    }
    
    /// Handles the Continue button tap - advances to next in-round player or prompts to finish round
    private func handleContinueTap(game: Game) {
        if let nextId = nextInRoundPlayerId(from: selectedPlayerId, players: game.players) {
            // If the next in-round player is the same as current (last one standing), prompt to finish
            if nextId == selectedPlayerId {
                activeConfirmation = .newRound
            } else {
                // Advance to the next in-round player (no layout animation)
                selectedPlayerId = nextId
                HapticFeedback.light()
            }
        } else {
            // No in-round players remain - prompt to finish round
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
                // Find the preview winner(s)
                let previewScores = game.players.map {
                    ($0.name, ScoreEngine.previewTotalScore(player: $0, rules: game.scoringRules))
                }
                let maxScore = previewScores.map { $0.1 }.max() ?? 0
                let winners = previewScores.filter { $0.1 == maxScore && $0.1 >= game.targetScore }
                
                if winners.count == 1 {
                    return "\(winners[0].0) will win with \(winners[0].1) points!\n\n" + nextRoundConfirmationMessage(game: game)
                } else {
                    let names = winners.map { $0.0 }.joined(separator: " & ")
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
        
        // If number is already selected, remove it
        if player.currentRound.hand.selectedNumbers.contains(number) {
            viewModel.removeCardFromPlayer(playerId, number: number)
            return
        }
        
        // Add the number
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
        
        // Players who will score points
        let scoringPlayers = game.players.filter { player in
            let score = ScoreEngine.calculateRoundScore(round: player.currentRound, rules: game.scoringRules)
            return score != 0
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
                let names = inRoundNoCards.map { $0.name }
                parts.append("No cards drawn: \(names.joined(separator: ", "))")
            }
        }
        
        if parts.isEmpty {
            return "All scores will be finalized and a new round will begin."
        }
        
        return parts.joined(separator: "\n")
    }
}

// MARK: - Selected Player Panel

/// Extracted panel component for the selected player's card picker and actions.
/// This is always present in the view hierarchy to prevent layout reflow when selection changes.
struct SelectedPlayerPanel: View {
    let game: Game
    let selectedPlayerId: UUID?
    let playerColors: [Color]
    @Bindable var viewModel: GameViewModel
    @Binding var showingBustBanner: Bool
    @Binding var bustNumber: Int?
    let onNumberTap: (UUID, Int) -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("riskInsightsMode") private var riskInsightsModeRaw: String = RiskInsightsMode.off.rawValue
    @State private var showingRiskInsight = false
    
    /// Falls back to first player for layout measurement when no selection
    private var effectivePlayer: Player {
        if let id = selectedPlayerId,
           let player = game.players.first(where: { $0.id == id }) {
            return player
        }
        // Fallback to first player to maintain consistent layout height
        return game.players.first ?? Player(name: "")
    }
    
    private var effectivePlayerId: UUID {
        selectedPlayerId ?? (game.players.first?.id ?? UUID())
    }
    
    private var playerIndex: Int {
        game.players.firstIndex(where: { $0.id == effectivePlayerId }) ?? 0
    }
    
    private var playerColor: Color {
        playerColors[safe: playerIndex] ?? DesignColor.color(.playerHighlight, theme: visualTheme, colorScheme: colorScheme)
    }

    private var bonusColor: Color {
        colorScheme == .dark ? AppBrandPalette.gold : AppBrandPalette.brandBlueDeep
    }

    private var riskInsightsMode: RiskInsightsMode {
        RiskInsightsMode(rawValue: riskInsightsModeRaw) ?? .off
    }
    
    var body: some View {
        let player = effectivePlayer
        let selectedId = effectivePlayerId
        
        VStack(spacing: 8) {
            // Player header with 7-card bonus
            HStack {
                Text(player.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(playerColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(game.scoringRules.brutalMode ? "BRUTAL" : game.scoringRules.mode.displayName.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(game.scoringRules.brutalMode ? AppBrandPalette.copper : bonusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill((game.scoringRules.brutalMode ? AppBrandPalette.copper : bonusColor).opacity(0.14)))
                
                Spacer()
                
                // 7-card bonus indicator - always reserve space to prevent layout shift
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(bonusColor)
                        .symbolEffect(.bounce, value: player.currentRound.hand.hasSevenCardBonus)
                    Text("+\(AppBrand.sevenCardBonusValue)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(bonusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.20 : 0.26))
                )
                .opacity(player.currentRound.hand.hasSevenCardBonus ? 1 : 0)
                .accessibilityHidden(!player.currentRound.hand.hasSevenCardBonus)
            }
            .padding(.horizontal)

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
                .padding(.horizontal)
            }
            
            // Action buttons - use fixed height container to prevent layout shifts between states
            PlayerActionButtons(
                player: player,
                selectedId: selectedId,
                viewModel: viewModel,
                scoringRules: game.scoringRules
            )
            .padding(.horizontal)

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
                .padding(.horizontal)
            }
            
            // Card picker - compute availability outside to help compiler
            // Editing is locked when: banked, frozen, busted, or manual score override is set
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
            let x2Enabled = canEditCards && (player.currentRound.hand.x2Count > 0 || viewModel.canAddX2())
            let divideByTwoEnabled = canEditVengeanceModifiers
                && (player.currentRound.hand.divideByTwoCount > 0 || viewModel.canAddDivideByTwo())
            
            // Check if deck has only one of each modifier (to hide "Hold to remove" hint and badges)
            let deckProfile = game.deckProfile
            let hasOnlyOneOfEachModifier = game.scoringRules.mode == .classic
                ? deckProfile.addModifierCounts.values.allSatisfy { $0 <= 1 } && deckProfile.x2Count <= 1
                : deckProfile.subtractModifierCounts.values.allSatisfy { $0 <= 1 } && deckProfile.divideByTwoCount <= 1
            
            QuickCardPicker(
                player: player,
                scoringRules: game.scoringRules,
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
                    // If deck has only 1 copy and player already has it, remove on tap
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
                    // If deck has only 1 copy and player already has it, remove on tap
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
                isNumberEnabled: { number in
                    // Disabled when editing is locked (banked/frozen/busted/manual score)
                    if !canEditCards {
                        return false
                    }
                    // Allow if player already has it (can remove) or if available in deck
                    if player.currentRound.hand.selectedNumbers.contains(number) {
                        return true // Can always remove
                    }
                    return viewModel.canAddNumber(number, toPlayer: selectedId)
                },
                isSpecialNumberEnabled: { card in
                    guard canEditCards else { return false }
                    if player.currentRound.hand.specialNumbers.contains(card) {
                        return true
                    }
                    return viewModel.canAddSpecialNumber(card, toPlayer: selectedId)
                },
                isModifierEnabled: { value in
                    // Disabled when editing is locked
                    if !canEditCards {
                        return false
                    }
                    // Allow if player already has it (can remove) or if available in deck
                    if (player.currentRound.hand.addMods[value] ?? 0) > 0 {
                        return true // Can always remove
                    }
                    return viewModel.canAddModifier(value)
                },
                isX2Enabled: x2Enabled,
                isSubtractModifierEnabled: { value in
                    guard canEditVengeanceModifiers else { return false }
                    if (player.currentRound.hand.subtractMods[value] ?? 0) > 0 {
                        return true
                    }
                    return viewModel.canAddSubtractModifier(value)
                },
                isDivideByTwoEnabled: divideByTwoEnabled,
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
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingRiskInsight) {
            if let insight = ProbabilityService.calculatorEstimate(for: selectedId, in: game) {
                RiskInsightSheet(insight: insight)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.md)
                .fill(DesignColor.color(.surfaceSecondary, theme: visualTheme, colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignRadius.md)
                .stroke(AppBrandPalette.cardBorder(colorScheme: colorScheme), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 8) // Comfortable gap before the bottom bar
    }
}

private struct BrutalBonusChoiceRow: View {
    let sourcePlayer: Player
    let players: [Player]
    let onSelectTarget: (UUID?) -> Void

    private var selectedTarget: Player? {
        guard let targetId = sourcePlayer.currentRound.sevenCardBonusTargetId else { return nil }
        return players.first(where: { $0.id == targetId })
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "burst.fill")
                .foregroundStyle(AppBrandPalette.copper)

            Text("7-card reward")
                .font(.system(size: 12, weight: .semibold, design: .rounded))

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
                    Text(selectedTarget.map { "\($0.name) -15" } ?? "Keep +15")
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppBrandPalette.copper)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppBrandPalette.copper.opacity(0.14)))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Player Action Buttons

/// Fixed-height action button row that maintains consistent height regardless of player state.
/// This prevents layout shifts when switching between inRound/banked/busted/frozen states.
struct PlayerActionButtons: View {
    let player: Player
    let selectedId: UUID
    @Bindable var viewModel: GameViewModel
    let scoringRules: ScoringRules
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var bankColor: Color {
        DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
    }

    private var bustColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    private var holdColor: Color {
        DesignColor.color(.playerHighlight, theme: visualTheme, colorScheme: colorScheme)
    }

    private var resumeColor: Color {
        DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
    }
    
    var body: some View {
        // Use ZStack with fixed height to prevent layout shifts between states
        ZStack {
            // In Round: Bank/Stay, Bust, Freeze/Forced Stay
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
                    color: holdColor,
                    action: {
                        HapticFeedback.medium()
                        viewModel.freezePlayer(selectedId)
                    }
                )
            }
            .opacity(player.currentRound.state == .inRound ? 1 : 0)
            .allowsHitTesting(player.currentRound.state == .inRound)
            .accessibilityHidden(player.currentRound.state != .inRound)
            
            // Busted state
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(bustColor)
                    Text("Busted")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(bustColor)
                }
                .frame(maxWidth: .infinity)
                
                ActionPillButton(
                    title: "Resume",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: resumeColor,
                    foregroundColor: AppBrandPalette.ink,
                    action: {
                        HapticFeedback.success()
                        viewModel.setPlayerState(selectedId, state: .inRound)
                    }
                )
            }
            .opacity(player.currentRound.state == .busted ? 1 : 0)
            .allowsHitTesting(player.currentRound.state == .busted)
            .accessibilityHidden(player.currentRound.state != .busted)
            
            // Banked state
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(bankColor)
                    Text(scoringRules.mode == .vengeance ? "Stayed" : "Banked")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(bankColor)
                }
                .frame(maxWidth: .infinity)
                
                ActionPillButton(
                    title: "Resume",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: resumeColor,
                    foregroundColor: AppBrandPalette.ink,
                    action: {
                        HapticFeedback.medium()
                        viewModel.setPlayerState(selectedId, state: .inRound)
                    }
                )
            }
            .opacity(player.currentRound.state == .banked ? 1 : 0)
            .allowsHitTesting(player.currentRound.state == .banked)
            .accessibilityHidden(player.currentRound.state != .banked)
            
            // Held state
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 18))
                        .foregroundStyle(holdColor)
                    Text(scoringRules.mode == .vengeance ? "Forced Stay" : "Frozen")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(holdColor)
                }
                .frame(maxWidth: .infinity)
                
                ActionPillButton(
                    title: "Resume",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: resumeColor,
                    foregroundColor: AppBrandPalette.ink,
                    action: {
                        HapticFeedback.medium()
                        viewModel.setPlayerState(selectedId, state: .inRound)
                    }
                )
            }
            .opacity(player.currentRound.state == .frozen ? 1 : 0)
            .allowsHitTesting(player.currentRound.state == .frozen)
            .accessibilityHidden(player.currentRound.state != .frozen)
        }
        // Fixed height ensures consistent layout
        .frame(height: 36)
    }
}

// MARK: - Action Pill Button

struct ActionPillButton: View {
    let title: String
    let icon: String
    let color: Color
    var foregroundColor: Color = .white
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
