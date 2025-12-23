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
    
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.vibrant.rawValue
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? .vibrant
    }
    
    private var playerColors: [Color] {
        guard let game = viewModel.game else { return [] }
        return PlayerColorResolver.colors(count: game.players.count, palette: selectedPalette)
    }
    
    var body: some View {
        if let game = viewModel.game {
            NavigationStack {
                VStack(spacing: 0) {
                    // Player grid at top
                    PlayerGrid(
                        players: game.players,
                        playerColors: playerColors,
                        selectedPlayerId: selectedPlayerId,
                        onSelect: { id in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlayerId = id
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Selected player input section - anchored to bottom
                    if let selectedId = selectedPlayerId,
                       let player = game.players.first(where: { $0.id == selectedId }),
                       let playerIndex = game.players.firstIndex(where: { $0.id == selectedId }) {
                        
                        VStack(spacing: 8) {
                            // Player header with Flip 7 bonus
                            HStack {
                                Text(player.name)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(playerColors[safe: playerIndex] ?? .blue)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                // Flip 7 bonus indicator
                                if player.currentRound.hand.hasFlip7Bonus {
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.yellow)
                                            .symbolEffect(.bounce, value: player.currentRound.hand.hasFlip7Bonus)
                                        Text("+15")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.yellow)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.yellow.opacity(0.2))
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Action buttons based on state
                            if player.currentRound.state == .inRound {
                                // In Round: Bank, Bust, Freeze
                                HStack(spacing: 6) {
                                    ActionPillButton(
                                        title: "Bank",
                                        icon: "checkmark.circle.fill",
                                        color: .green,
                                        action: {
                                            HapticFeedback.success()
                                            viewModel.bankPlayer(selectedId)
                                        }
                                    )
                                    
                                    ActionPillButton(
                                        title: "Bust",
                                        icon: "xmark.circle.fill",
                                        color: .red,
                                        action: {
                                            HapticFeedback.error()
                                            viewModel.bustPlayer(selectedId)
                                        }
                                    )
                                    
                                    ActionPillButton(
                                        title: "Freeze",
                                        icon: "snowflake",
                                        color: .purple,
                                        action: {
                                            HapticFeedback.medium()
                                            viewModel.freezePlayer(selectedId)
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            } else if player.currentRound.state == .busted {
                                // Busted: Un-bust option
                                HStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.red)
                                        Text("BUSTED")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.red)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    ActionPillButton(
                                        title: "Un-bust",
                                        icon: "arrow.uturn.backward.circle.fill",
                                        color: .orange,
                                        action: {
                                            HapticFeedback.success()
                                            viewModel.setPlayerState(selectedId, state: .inRound)
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            } else if player.currentRound.state == .banked {
                                // Banked: Un-bank option
                                HStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.green)
                                        Text("BANKED")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.green)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    ActionPillButton(
                                        title: "Un-bank",
                                        icon: "arrow.uturn.backward.circle.fill",
                                        color: .orange,
                                        action: {
                                            HapticFeedback.medium()
                                            viewModel.setPlayerState(selectedId, state: .inRound)
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            } else if player.currentRound.state == .frozen {
                                // Frozen: Un-freeze option
                                HStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "snowflake")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.purple)
                                        Text("FROZEN")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.purple)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    ActionPillButton(
                                        title: "Un-freeze",
                                        icon: "arrow.uturn.backward.circle.fill",
                                        color: .orange,
                                        action: {
                                            HapticFeedback.medium()
                                            viewModel.setPlayerState(selectedId, state: .inRound)
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            }
                            
                            // Card picker - compute availability outside to help compiler
                            let x2Enabled = player.currentRound.hand.x2Count > 0 || viewModel.canAddX2()
                            
                            QuickCardPicker(
                                player: player,
                                onTapNumber: { number in
                                    handleNumberTap(playerId: selectedId, number: number)
                                },
                                onIncrementModifier: { value in
                                    viewModel.addModifierToPlayer(selectedId, value: value)
                                },
                                onDecrementModifier: { value in
                                    viewModel.removeModifierFromPlayer(selectedId, value: value)
                                },
                                onIncrementX2: {
                                    viewModel.addX2ToPlayer(selectedId)
                                },
                                onDecrementX2: {
                                    viewModel.removeX2FromPlayer(selectedId)
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
                                    // Allow if player already has it (can remove) or if available in deck
                                    if player.currentRound.hand.selectedNumbers.contains(number) {
                                        return true // Can always remove
                                    }
                                    return viewModel.canAddNumber(number, toPlayer: selectedId)
                                },
                                isModifierEnabled: { value in
                                    // Allow if player already has it (can remove) or if available in deck
                                    if (player.currentRound.hand.addMods[value] ?? 0) > 0 {
                                        return true // Can always remove
                                    }
                                    return viewModel.canAddModifier(value)
                                },
                                isX2Enabled: x2Enabled
                            )
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Bottom bar
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            // Winner indicator (left side)
                            if game.hasWinner {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.yellow)
                                    Text(game.winners.map { $0.name }.joined(separator: ", "))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.yellow)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                            
                            // Undo/Redo (centered)
                            HStack(spacing: 12) {
                                Button(action: {
                                    HapticFeedback.light()
                                    viewModel.undo()
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(viewModel.canUndo ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(!viewModel.canUndo)
                                
                                Button(action: {
                                    HapticFeedback.light()
                                    viewModel.redo()
                                }) {
                                    Image(systemName: "arrow.uturn.forward.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(viewModel.canRedo ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(!viewModel.canRedo)
                            }
                            
                            // Next Round button (right side)
                            Button(action: {
                                activeConfirmation = .newRound
                            }) {
                                HStack(spacing: 6) {
                                    Text("Next")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.blue)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                    }
                }
                .navigationTitle("Round \(game.currentRoundNumber)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Next Round", action: { activeConfirmation = .newRound })
                            Divider()
                            Button("New Game", role: .destructive, action: { activeConfirmation = .newGame })
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(viewModel: viewModel)
                }
                .overlay {
                    if let confirmation = activeConfirmation {
                        ConfirmationOverlay(
                            title: confirmation == .newRound ? "Finish Round?" : "New Game",
                            message: confirmation == .newRound ? nextRoundConfirmationMessage(game: game) : "This will end the current game and return to setup.",
                            primaryActionTitle: confirmation == .newRound ? "Next Round" : "Start New Game",
                            primaryActionRole: confirmation == .newGame ? .destructive : nil,
                            onPrimary: {
                                if confirmation == .newRound {
                                    HapticFeedback.success()
                                    viewModel.startNewRound()
                                    selectedPlayerId = nil
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
                }
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Helpers
    
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
            let score = ScoreEngine.calculateRoundScore(hand: player.currentRound.hand, state: player.currentRound.state)
            return score > 0
        }
        
        if !scoringPlayers.isEmpty {
            let names = scoringPlayers.map { "\($0.name) (+\(ScoreEngine.calculateRoundScore(hand: $0.currentRound.hand, state: $0.currentRound.state)))" }
            parts.append("Banking: \(names.joined(separator: ", "))")
        }
        
        if !bustedPlayers.isEmpty {
            let names = bustedPlayers.map { $0.name }
            parts.append("Busted (0 pts): \(names.joined(separator: ", "))")
        }
        
        if !inRoundPlayers.isEmpty {
            let inRoundWithCards = inRoundPlayers.filter { !$0.currentRound.hand.selectedNumbers.isEmpty }
            let inRoundNoCards = inRoundPlayers.filter { $0.currentRound.hand.selectedNumbers.isEmpty }
            
            if !inRoundWithCards.isEmpty {
                let names = inRoundWithCards.map { "\($0.name) (+\(ScoreEngine.calculateRoundScore(hand: $0.currentRound.hand, state: $0.currentRound.state)))" }
                parts.append("Still in round (will bank): \(names.joined(separator: ", "))")
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

// MARK: - Action Pill Button

struct ActionPillButton: View {
    let title: String
    let icon: String
    let color: Color
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
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
