//
//  GameSetupView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct PlayerNameRow: Identifiable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String = "") {
        self.id = id
        self.name = name
    }
}

struct GameSetupView: View {
    @Binding var viewModel: GameViewModel
    @State private var playerRows: [PlayerNameRow] = [PlayerNameRow(), PlayerNameRow()]
    @State private var targetScore: Int = 200
    @StateObject private var focusCoordinator = FocusCoordinator()
    @State private var hasLoadedRoster = false
    @State private var showingTargetScoreEditor = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title section
                Text("Flip 7")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusCoordinator.clearFocus()
                    }
                
                // Main content - scrollable
                ScrollView {
                    VStack(spacing: 16) {
                        // Players card
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Players")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                Text("\(playerRows.count)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            
                            // Player rows
                            VStack(spacing: 0) {
                                ForEach($playerRows) { $row in
                                    let index = indexOfRow(row.id)
                                    
                                    PlayerInputRow(
                                        index: index,
                                        row: $row,
                                        isLast: index == playerRows.count - 1,
                                        canDelete: playerRows.count > 2,
                                        focusCoordinator: focusCoordinator,
                                        onDelete: { removePlayer(rowId: row.id) }
                                    )
                                    
                                    if index < playerRows.count - 1 {
                                        Divider()
                                            .padding(.leading, 52)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.25), value: playerRows.count)
                                
                                // Add player row
                                if playerRows.count < 8 {
                                    Divider()
                                        .padding(.leading, 52)
                                    
                                    Button(action: addPlayer) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.1))
                                                    .frame(width: 32, height: 32)
                                                
                                                Image(systemName: "plus")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.blue)
                                            }
                                            
                                            Text("Add Player")
                                                .font(.system(size: 17, weight: .regular))
                                                .foregroundStyle(.blue)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .onChange(of: playerRows.map { $0.id }) { _, newIds in
                            focusCoordinator.setOrder(newIds)
                        }
                        .onAppear {
                            focusCoordinator.setOrder(playerRows.map { $0.id })
                        }
                        
                        // Reset link
                        if playerRows.count > 2 || playerRows.contains(where: { !$0.name.isEmpty }) {
                            Button(action: clearPlayers) {
                                Text("Reset to Default")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Target Score card
                        VStack(spacing: 0) {
                            HStack {
                                Text("Target Score")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            
                            HStack {
                                Button(action: { targetScore = max(50, targetScore - 25) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(targetScore > 50 ? .blue : Color(.systemGray4))
                                }
                                .disabled(targetScore <= 50)
                                
                                Spacer()
                                
                                Button(action: { showingTargetScoreEditor = true }) {
                                    Text("\(targetScore)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .frame(minWidth: 80)
                                        .contentTransition(.numericText())
                                        .animation(.snappy(duration: 0.2), value: targetScore)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                Button(action: { targetScore = min(5000, targetScore + 25) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(targetScore < 5000 ? .blue : Color(.systemGray4))
                                }
                                .disabled(targetScore >= 5000)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Deck card
                        let deckCardCount = PersistedDeckProfile.load().deckProfile.totalCardCount
                        NavigationLink(destination: DeckManagementView(viewModel: viewModel)) {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Deck")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Spacer()
                                    
                                    Text("\(deckCardCount) cards")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                
                                HStack {
                                    Text("Customize deck composition")
                                        .font(.system(size: 17, weight: .regular, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for start button
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusCoordinator.clearFocus()
                }
                
                // Start button - fixed at bottom
                VStack(spacing: 0) {
                    Button(action: {
                        HapticFeedback.success()
                        startGame()
                    }) {
                        Text("Start Game")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(canStartGame ? .blue : Color(.systemGray4))
                            )
                    }
                    .disabled(!canStartGame)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .background(
                        Color(.systemGroupedBackground)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                            .ignoresSafeArea()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingTargetScoreEditor) {
                TargetScoreEditorSheet(targetScore: $targetScore) { newScore in
                    targetScore = newScore
                }
            }
            .onAppear {
                if !hasLoadedRoster {
                    loadPersistedRoster()
                    hasLoadedRoster = true
                }
            }
        }
    }
    
    private func loadPersistedRoster() {
        if let roster = PersistedRoster.load(), !roster.names.isEmpty {
            let names = Array(roster.names.prefix(8))
            playerRows = names.map { PlayerNameRow(name: $0) }
            focusCoordinator.setOrder(playerRows.map { $0.id })
        }
    }
    
    private var canStartGame: Bool {
        return playerRows.count >= 2 && playerRows.count <= 8
    }
    
    private func indexOfRow(_ id: UUID) -> Int {
        playerRows.firstIndex(where: { $0.id == id }) ?? 0
    }
    
    private func addPlayer() {
        guard playerRows.count < 8 else { return }
        HapticFeedback.light()
        let newRow = PlayerNameRow()
        playerRows.append(newRow)
        focusCoordinator.setOrder(playerRows.map { $0.id })
        focusCoordinator.clearFocus()
    }
    
    private func removePlayer(rowId: UUID) {
        guard playerRows.count > 2 else { return }
        HapticFeedback.light()
        
        guard let indexToRemove = playerRows.firstIndex(where: { $0.id == rowId }) else { return }
        
        let newFocusId: UUID?
        if focusCoordinator.focusedId == rowId {
            if indexToRemove > 0 {
                newFocusId = playerRows[indexToRemove - 1].id
            } else if playerRows.count > 1 {
                newFocusId = playerRows[1].id
            } else {
                newFocusId = nil
            }
        } else {
            newFocusId = focusCoordinator.focusedId
        }
        
        playerRows.remove(at: indexToRemove)
        focusCoordinator.setOrder(playerRows.map { $0.id })
        
        if let newFocusId = newFocusId {
            DispatchQueue.main.async {
                focusCoordinator.focus(newFocusId)
            }
        }
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
}

// MARK: - Player Input Row

struct PlayerInputRow: View {
    let index: Int
    @Binding var row: PlayerNameRow
    let isLast: Bool
    let canDelete: Bool
    let focusCoordinator: FocusCoordinator
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Player number badge
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                
                Text("\(index + 1)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Text field
            FocusableTextFieldRepresentable(
                id: row.id,
                placeholder: "Player \(index + 1)",
                text: $row.name,
                isLast: isLast,
                coordinator: focusCoordinator
            )
            .frame(height: 44)
            
            // Delete button (only when > 2 players)
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

