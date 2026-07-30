//
//  DealerGameView.swift
//  flip7calculator
//

import SwiftUI
import UIKit

private enum DealerConfirmation {
    case continueAsCalculator
    case newGame
}

struct DealerGameView: View {
    @Bindable var viewModel: GameViewModel
    @State private var showingHistory = false
    @State private var showingHelp = false
    @State private var showingRisk = false
    @State private var showingGameOver = false
    @State private var confirmation: DealerConfirmation?

    @AppStorage("riskInsightsMode") private var riskInsightsModeRaw: String = RiskInsightsMode.off.rawValue
    @AppStorage("keepScreenAwakeDuringDealer") private var keepScreenAwake = true
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var riskMode: RiskInsightsMode {
        RiskInsightsMode(rawValue: riskInsightsModeRaw) ?? .off
    }

    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }

    var body: some View {
        if let game = viewModel.game, let session = game.liveSession {
            NavigationStack {
                Group {
                    if horizontalSizeClass == .regular {
                        HStack(spacing: DesignSpacing.lg) {
                            DealerPlayerBoard(
                                game: game,
                                session: session,
                                colors: PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette),
                                layout: .grid
                            )
                            .frame(maxWidth: 390)

                            DealerStage(
                                game: game,
                                session: session,
                                eligibleTargets: viewModel.liveEligibleTargets,
                                riskMode: riskMode,
                                centersContent: true,
                                onChooseTarget: chooseTarget,
                                onShowRisk: { showingRisk = true }
                            )
                            .frame(maxWidth: 680, maxHeight: 780)
                        }
                        .padding(DesignSpacing.lg)
                    } else {
                        VStack(spacing: DesignSpacing.sm) {
                            DealerPlayerBoard(
                                game: game,
                                session: session,
                                colors: PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette),
                                layout: .strip
                            )
                            .frame(maxHeight: 124)

                            DealerStage(
                                game: game,
                                session: session,
                                eligibleTargets: viewModel.liveEligibleTargets,
                                riskMode: riskMode,
                                centersContent: false,
                                onChooseTarget: chooseTarget,
                                onShowRisk: { showingRisk = true }
                            )
                            .frame(maxHeight: .infinity)
                        }
                        .padding(.horizontal, DesignSpacing.sm)
                        .padding(.top, DesignSpacing.xs)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    DealerActionBar(
                        game: game,
                        task: session.currentTask,
                        canUndo: viewModel.canUndo,
                        canRedo: viewModel.canRedo,
                        onDraw: draw,
                        onStay: stay,
                        onRoundComplete: completeRound,
                        onUndo: {
                            HapticFeedback.light()
                            viewModel.undo()
                        },
                        onRedo: {
                            HapticFeedback.light()
                            viewModel.redo()
                        }
                    )
                }
                .navigationTitle("Round \(game.currentRoundNumber) · Dealer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(showingGameOver ? .hidden : .visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("Table log")
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("How Dealer Works", systemImage: "questionmark.circle") {
                                showingHelp = true
                            }
                            Toggle("Keep Screen Awake", isOn: $keepScreenAwake)
                            Divider()
                            Button("Continue as Score Calculator", systemImage: "plus.forwardslash.minus") {
                                confirmation = .continueAsCalculator
                            }
                            Button("New Game", systemImage: "plus.circle", role: .destructive) {
                                confirmation = .newGame
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Dealer options")
                    }
                }
                .sheet(isPresented: $showingHistory) {
                    DealerTableLogView(events: session.eventLog)
                }
                .sheet(isPresented: $showingHelp) {
                    DealerHelpView()
                }
                .sheet(isPresented: $showingRisk) {
                    if let playerID = session.currentTask?.riskPlayerID,
                       let insight = ProbabilityService.exactDigitalRisk(for: playerID, in: game) {
                        RiskInsightSheet(insight: insight)
                    }
                }
                .overlay {
                    if let confirmation {
                        ConfirmationOverlay(
                            title: confirmation == .newGame ? "Start a New Game?" : "Continue in the Calculator?",
                            message: confirmationMessage(confirmation),
                            primaryActionTitle: confirmation == .newGame ? "New Game" : "Continue",
                            primaryActionRole: confirmation == .newGame ? .destructive : nil,
                            onPrimary: { performConfirmation(confirmation) },
                            onDismiss: { self.confirmation = nil }
                        )
                    }

                    if showingGameOver {
                        GameOverOverlay(
                            viewModel: viewModel,
                            onPlayAgain: {
                                showingGameOver = false
                                viewModel.restartGameKeepingSettings()
                            },
                            onNewGame: {
                                showingGameOver = false
                                viewModel.endGame()
                            },
                            onUndo: { showingGameOver = false }
                        )
                    }
                }
                .alert("Dealer Paused", isPresented: liveErrorBinding) {
                    Button("OK", role: .cancel) { viewModel.liveErrorMessage = nil }
                } message: {
                    Text(viewModel.liveErrorMessage ?? "The requested action could not be completed.")
                }
                .appChromeBackground()
            }
            .onAppear { updateIdleTimer() }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: keepScreenAwake) { _, _ in updateIdleTimer() }
            .onChange(of: scenePhase) { _, _ in updateIdleTimer() }
        } else {
            ContentUnavailableView {
                Label("Dealer Session Unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text("The saved deck could not be restored. Return to setup to begin a new game.")
            } actions: {
                Button("Return to Setup") {
                    viewModel.endGame()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(DesignSpacing.lg)
            .appChromeBackground()
        }
    }

    private var liveErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.liveErrorMessage != nil },
            set: { if !$0 { viewModel.liveErrorMessage = nil } }
        )
    }

    private func draw() {
        let previousStates = viewModel.game?.players.map(\.currentRound.state)
        if viewModel.drawLiveCard() {
            let newStates = viewModel.game?.players.map(\.currentRound.state)
            if zip(previousStates ?? [], newStates ?? []).contains(where: { $0 != .busted && $1 == .busted }) {
                HapticFeedback.error()
            } else {
                HapticFeedback.light()
            }
        }
    }

    private func stay() {
        if viewModel.stayLivePlayer() {
            HapticFeedback.medium()
        }
    }

    private func chooseTarget(_ playerID: UUID) {
        if viewModel.chooseLiveTarget(playerID) {
            HapticFeedback.light()
        }
    }

    private func completeRound() {
        guard let game = viewModel.game else { return }
        if game.previewHasUniqueWinner {
            if viewModel.finishLiveGameRound() {
                HapticFeedback.success()
                showingGameOver = true
            }
        } else if viewModel.startNextLiveRound() {
            HapticFeedback.success()
        }
    }

    private func confirmationMessage(_ confirmation: DealerConfirmation) -> String {
        switch confirmation {
        case .continueAsCalculator:
            return "Scores and score-relevant cards stay in place. The exact shoe and dealer history will be abandoned, and this game cannot return to Dealer."
        case .newGame:
            return "This ends the current game and returns to setup."
        }
    }

    private func performConfirmation(_ confirmation: DealerConfirmation) {
        switch confirmation {
        case .continueAsCalculator:
            viewModel.continueDealerAsScorekeeper()
        case .newGame:
            viewModel.endGame()
        }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepScreenAwake && scenePhase == .active
    }
}

private enum DealerPlayerBoardLayout {
    case strip
    case grid
}

private struct DealerPlayerBoard: View {
    let game: Game
    let session: LiveSession
    let colors: [Color]
    let layout: DealerPlayerBoardLayout

    var body: some View {
        Group {
            if layout == .grid {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160), spacing: DesignSpacing.xs)],
                        spacing: DesignSpacing.xs
                    ) {
                        playerTiles
                    }
                    .padding(DesignSpacing.xs)
                }
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: DesignSpacing.xs) {
                        playerTiles
                    }
                    .padding(.horizontal, DesignSpacing.xs)
                    .padding(.vertical, 6)
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Players")
    }

    @ViewBuilder
    private var playerTiles: some View {
        ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
            DealerPlayerTile(
                player: player,
                rules: game.scoringRules,
                cards: session.cards(for: player.id),
                color: colors[safe: index] ?? .accentColor,
                isCurrent: session.currentTask?.focusPlayerID == player.id,
                isDealer: session.dealerPlayerID == player.id
            )
            .frame(width: layout == .strip ? 142 : nil)
        }
    }
}

private struct DealerPlayerTile: View {
    let player: Player
    let rules: ScoringRules
    let cards: [LiveCardInstance]
    let color: Color
    let isCurrent: Bool
    let isDealer: Bool
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 9, height: 9)
                Text(player.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 2)
                if isDealer {
                    Image(systemName: "rectangle.stack.badge.person.crop")
                        .font(.system(size: 11, weight: .semibold))
                        .accessibilityLabel("Dealer")
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text("\(player.totalScore)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("+\(ScoreEngine.calculateRoundScore(round: player.currentRound, rules: rules))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                Spacer()
                if cards.contains(where: { $0.content == .action(.shield) }) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme))
                        .accessibilityLabel("Shield protected")
                }
            }

            HStack {
                Text(statusLabel)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.4)
                Spacer()
                Text("\(player.currentRound.hand.numberCardCount)/7")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(statusColor)
        }
        .padding(DesignSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .cardSurface(cornerRadius: DesignRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignRadius.md)
                .stroke(isCurrent ? color : .clear, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name), \(player.totalScore) total, \(ScoreEngine.calculateRoundScore(round: player.currentRound, rules: rules)) this round, \(statusLabel)")
    }

    private var statusLabel: String {
        switch player.currentRound.state {
        case .inRound: return isCurrent ? "CURRENT" : "ACTIVE"
        case .banked: return "STAYED"
        case .busted: return "BUSTED"
        case .frozen: return "HELD"
        }
    }

    private var statusColor: Color {
        switch player.currentRound.state {
        case .inRound: return color
        case .banked: return DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
        case .busted: return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        case .frozen: return DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
        }
    }
}

private struct DealerStage: View {
    let game: Game
    let session: LiveSession
    let eligibleTargets: [Player]
    let riskMode: RiskInsightsMode
    let centersContent: Bool
    let onChooseTarget: (UUID) -> Void
    let onShowRisk: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.xs) {
                Label("\(session.drawPile.count)", systemImage: "rectangle.stack.fill")
                    .pillBadge(.info)
                Label("\(session.discardPile.count)", systemImage: "tray.full.fill")
                    .pillBadge(.neutral)
                if session.shuffleCount > 1 {
                    Label("\(session.shuffleCount)", systemImage: "shuffle")
                        .pillBadge(.warning)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(session.drawPile.count) cards in draw pile, \(session.discardPile.count) discarded, \(session.shuffleCount) shuffles")

            VStack(spacing: 5) {
                Text(taskEyebrow)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme))
                Text(taskInstruction)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
            }
            .frame(minHeight: 50)

            if case .chooseTarget? = session.currentTask {
                DealerTargetChooser(
                    players: eligibleTargets,
                    game: game,
                    onChoose: onChooseTarget
                )
            } else {
                DealerCardFace(card: session.lastReveal?.card)
                    .id(session.lastReveal?.card.id)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.94)))
                    .animation(reduceMotion ? nil : DesignMotion.animation(.normal), value: session.lastReveal?.card.id)
            }

            if let playerID = session.currentTask?.focusPlayerID {
                DealerHandStrip(cards: session.cards(for: playerID))

                if riskMode != .off,
                   session.currentTask?.riskPlayerID != nil,
                   let insight = ProbabilityService.exactDigitalRisk(for: playerID, in: game) {
                    RiskPillButton(insight: insight, mode: riskMode, action: onShowRisk)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: centersContent ? .center : .top
        )
        .padding(DesignSpacing.md)
        .cardSurface(cornerRadius: 24)
    }

    private var taskEyebrow: String {
        guard let task = session.currentTask else { return "DEALER" }
        switch task {
        case .openingDraw: return "OPENING DEAL"
        case .awaitDecision: return "PUSH OR STAY"
        case .forcedDraw(_, _, let drawNumber, let total): return "FORCED DRAW \(drawNumber) OF \(total)"
        case .chooseTarget(let prompt): return prompt.action.displayName.uppercased()
        case .roundComplete: return "ROUND COMPLETE"
        case .completeForced, .beginTurns, .advanceTurn: return "DEALER"
        }
    }

    private var taskInstruction: String {
        guard let task = session.currentTask else { return "Dealer paused" }
        switch task {
        case .openingDraw(let playerID):
            return "Deal to \(name(playerID))"
        case .awaitDecision(let playerID):
            return "\(name(playerID)), draw or stay?"
        case .forcedDraw(_, let playerID, _, _):
            return "Continue for \(name(playerID))"
        case .chooseTarget(let prompt):
            return "\(name(prompt.sourcePlayerID)), choose a player"
        case .roundComplete(let reason):
            if reason.kind == .sevenCards, let playerID = reason.playerID {
                return "\(name(playerID)) reached seven"
            }
            return "Review scores"
        case .completeForced, .beginTurns, .advanceTurn:
            return "Preparing next action"
        }
    }

    private func name(_ playerID: UUID) -> String {
        game.players.first(where: { $0.id == playerID })?.name ?? "Player"
    }
}

private struct DealerCardFace: View {
    let card: LiveCardInstance?
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(DesignColor.color(.surfacePrimary, theme: visualTheme, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(accent.opacity(0.75), lineWidth: 4)
                )
                .shadow(color: accent.opacity(0.18), radius: 18, y: 10)

            if let card {
                VStack(spacing: 10) {
                    Image(systemName: icon(for: card.content))
                        .font(.system(size: card.content.isNumber ? 24 : 32, weight: .bold))
                    Text(card.content.shortLabel)
                        .font(.system(size: card.content.isNumber ? 64 : 29, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.65)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(accent)
                .padding(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(card.content.accessibilityLabel)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 42, weight: .bold))
                    Text("READY")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(1.4)
                }
                .foregroundStyle(accent)
                .accessibilityLabel("Dealer ready")
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(minHeight: 160, maxHeight: 240)
    }

    private var accent: Color {
        guard let content = card?.content else {
            return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
        }
        switch content {
        case .number:
            return DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
        case .addModifier, .multiplier:
            return DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme)
        case .action(.hold):
            return DesignColor.color(.stateWarning, theme: visualTheme, colorScheme: colorScheme)
        case .action(.drawThree):
            return DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
        case .action(.shield):
            return DesignColor.color(.stateSuccess, theme: visualTheme, colorScheme: colorScheme)
        }
    }

    private func icon(for content: LiveCardContent) -> String {
        switch content {
        case .number: return "number"
        case .addModifier: return "plus"
        case .multiplier: return "multiply"
        case .action(let action): return action.icon
        }
    }
}

private struct DealerTargetChooser: View {
    let players: [Player]
    let game: Game
    let onChoose: (UUID) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: DesignSpacing.xs)], spacing: DesignSpacing.xs) {
                ForEach(players) { player in
                    Button(action: { onChoose(player.id) }) {
                        VStack(spacing: 5) {
                            Text(player.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Text("\(ScoreEngine.calculateRoundScore(round: player.currentRound, rules: game.scoringRules)) this round")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SelectionCardButtonStyle(isSelected: false))
                    .accessibilityIdentifier("dealer.target.\(player.id.uuidString)")
                }
            }
        }
        .frame(maxHeight: 250)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Eligible targets")
    }
}

private struct DealerHandStrip: View {
    let cards: [LiveCardInstance]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                if cards.isEmpty {
                    Text("No cards yet")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(cards) { card in
                        Text(card.content.shortLabel)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                            .accessibilityLabel(card.content.accessibilityLabel)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(minHeight: 29)
    }
}

private struct DealerActionBar: View {
    let game: Game
    let task: LiveTask?
    let canUndo: Bool
    let canRedo: Bool
    let onDraw: () -> Void
    let onStay: () -> Void
    let onRoundComplete: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignSpacing.sm) {
            historyButton("arrow.uturn.backward.circle.fill", enabled: canUndo, action: onUndo)

            switch task {
            case .awaitDecision:
                Button("Stay", action: onStay)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 116)
                    .accessibilityIdentifier("dealer.stay")
                primaryButton(title: primaryTitle, action: onDraw)

            case .openingDraw, .forcedDraw:
                primaryButton(title: primaryTitle, action: onDraw)

            case .roundComplete:
                primaryButton(title: game.previewHasUniqueWinner ? "Finish Game" : "Start Next Round", action: onRoundComplete)

            case .chooseTarget:
                Text("Choose a player above")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    .frame(maxWidth: .infinity)

            case .none, .completeForced, .beginTurns, .advanceTurn:
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            historyButton("arrow.uturn.forward.circle.fill", enabled: canRedo, action: onRedo)
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.top, DesignSpacing.sm)
        .padding(.bottom, 10)
        .background(
            DesignColor.color(.surfaceRaised, theme: visualTheme, colorScheme: colorScheme)
                .opacity(0.98)
                .shadow(color: AppBrandPalette.ink.opacity(0.10), radius: 16, y: -5)
        )
    }

    private var primaryTitle: String {
        guard let task else { return "Draw" }
        switch task {
        case .openingDraw(let playerID):
            return "Deal to \(name(playerID))"
        case .awaitDecision(let playerID):
            return "Draw for \(name(playerID))"
        case .forcedDraw(_, let playerID, let number, let total):
            return "Draw \(number) of \(total) for \(name(playerID))"
        default:
            return "Continue"
        }
    }

    private func name(_ playerID: UUID) -> String {
        game.players.first(where: { $0.id == playerID })?.name ?? "Player"
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("dealer.primaryAction")
    }

    private func historyButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 25))
                .foregroundStyle(
                    enabled
                        ? DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
                        : Color(.systemGray4)
                )
                .frame(width: 36, height: 44)
        }
        .disabled(!enabled)
    }
}

private struct DealerTableLogView: View {
    let events: [LiveEvent]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(events.reversed()) { event in
                HStack(alignment: .top, spacing: DesignSpacing.sm) {
                    Image(systemName: icon(event.kind))
                        .foregroundStyle(tone(event.kind))
                        .frame(width: 24)
                    Text(event.message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .padding(.vertical, 3)
            }
            .navigationTitle("Table Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func icon(_ kind: LiveEventKind) -> String {
        switch kind {
        case .shuffled: return "shuffle"
        case .revealed: return "rectangle.portrait"
        case .protected: return "shield.fill"
        case .busted: return "exclamationmark.triangle.fill"
        case .stayed: return "hand.raised.fill"
        case .held: return "pause.fill"
        case .action: return "bolt.fill"
        case .round: return "flag.fill"
        }
    }

    private func tone(_ kind: LiveEventKind) -> Color {
        switch kind {
        case .busted: return AppBrandPalette.copper
        case .shuffled, .round: return AppBrandPalette.goldDeep
        default: return AppBrandPalette.brandBlue
        }
    }
}

private struct DealerHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("At the table") {
                    Label("Use the large bottom action for every deal and draw.", systemImage: "hand.tap.fill")
                    Label("The named player chooses whether to draw or stay.", systemImage: "person.fill.questionmark")
                    Label("When an action appears, that player chooses an eligible target.", systemImage: "scope")
                }
                Section("Deck trust") {
                    Label("The complete order is created once, saved locally, and survives relaunch, undo, and rotation.", systemImage: "checkmark.seal.fill")
                    Label("Completed-round cards stay discarded until the draw pile runs out.", systemImage: "tray.full.fill")
                    Label("A reshuffle never includes cards still on the table.", systemImage: "shuffle")
                }
                Section("Original action labels") {
                    Label("Hold makes an active player stay immediately.", systemImage: "pause.fill")
                    Label("Draw 3 gives an active player three forced cards.", systemImage: "square.stack.3d.up.fill")
                    Label("Shield cancels one duplicate number, then is discarded.", systemImage: "shield.fill")
                }
                Section {
                    Text(AppBrand.independenceNotice)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("How Dealer Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private extension LiveTask {
    var focusPlayerID: UUID? {
        switch self {
        case .openingDraw(let playerID), .awaitDecision(let playerID):
            return playerID
        case .forcedDraw(_, let playerID, _, _), .completeForced(_, let playerID):
            return playerID
        case .chooseTarget(let prompt):
            return prompt.sourcePlayerID
        case .roundComplete(let reason):
            return reason.playerID
        case .beginTurns(let playerID), .advanceTurn(let playerID):
            return playerID
        }
    }

    var riskPlayerID: UUID? {
        switch self {
        case .openingDraw(let playerID), .awaitDecision(let playerID), .forcedDraw(_, let playerID, _, _):
            return playerID
        default:
            return nil
        }
    }
}
