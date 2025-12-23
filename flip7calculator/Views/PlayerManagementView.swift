//
//  PlayerManagementView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import SwiftUI

struct PlayerManagementView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var playerRows: [PlayerNameRow] = []
    @StateObject private var focusCoordinator = FocusCoordinator()
    
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.vibrant.rawValue
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? .vibrant
    }
    
    private var playerColors: [Color] {
        PlayerColorResolver.colors(count: playerRows.count, palette: selectedPalette)
    }
    
    private var hasActiveGame: Bool {
        viewModel.game != nil
    }
    
    var body: some View {
        List {
            // Preview section
            if !playerRows.isEmpty {
                Section {
                    PlayerPreviewGrid(
                        playerRows: playerRows,
                        playerColors: playerColors
                    )
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                } footer: {
                    Text("This is how players will appear in the game")
                }
            }
            
            // Edit section
            Section {
                ForEach($playerRows) { $row in
                    let index = indexOfRow(row.id)
                    HStack {
                        TextField("Player \(index + 1)", text: $row.name)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .onChange(of: row.name) { oldValue, newValue in
                                // Enforce character limit (same as FocusableTextField)
                                if newValue.count > 20 {
                                    row.name = String(newValue.prefix(20))
                                }
                                saveChanges()
                            }
                    }
                }
                .onMove { source, destination in
                    playerRows.move(fromOffsets: source, toOffset: destination)
                    focusCoordinator.setOrder(playerRows.map { $0.id })
                    saveChanges()
                }
                .onDelete { indexSet in
                    guard playerRows.count > 2 else { return }
                    playerRows.remove(atOffsets: indexSet)
                    focusCoordinator.setOrder(playerRows.map { $0.id })
                    saveChanges()
                }
                
                if playerRows.count < 8 {
                    Button(action: addPlayer) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Player")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } header: {
                Text("Players")
            } footer: {
                Text("Tap and hold to reorder. Minimum 2 players, maximum 8.")
            }
            
            Section {
                Button(role: .destructive, action: clearRoster) {
                    HStack {
                        Spacer()
                        Text("Clear Saved Roster")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Manage Players")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            loadRoster()
        }
    }
    
    private func indexOfRow(_ id: UUID) -> Int {
        playerRows.firstIndex(where: { $0.id == id }) ?? 0
    }
    
    private func loadRoster() {
        // If there's an active game, load from game; otherwise load from persisted roster
        if let game = viewModel.game {
            // Load from active game, preserving player IDs
            playerRows = game.players.map { player in
                PlayerNameRow(id: player.id, name: player.name)
            }
        } else if let roster = PersistedRoster.load(), !roster.names.isEmpty {
            let names = Array(roster.names.prefix(8))
            playerRows = names.map { PlayerNameRow(name: $0) }
        } else {
            playerRows = [PlayerNameRow(), PlayerNameRow()]
        }
        focusCoordinator.setOrder(playerRows.map { $0.id })
    }
    
    private func addPlayer() {
        guard playerRows.count < 8 else { return }
        HapticFeedback.light()
        let newRow = PlayerNameRow()
        playerRows.append(newRow)
        focusCoordinator.setOrder(playerRows.map { $0.id })
        saveChanges()
    }
    
    private func clearRoster() {
        HapticFeedback.light()
        playerRows = [PlayerNameRow(), PlayerNameRow()]
        focusCoordinator.setOrder(playerRows.map { $0.id })
        PersistedRoster.clear()
        // If there's an active game, we can't clear it - just clear the roster
    }
    
    private func saveChanges() {
        let names = playerRows.map { $0.name.trimmingCharacters(in: .whitespaces) }
        
        // Save to persisted roster
        PersistedRoster(names: names).save()
        
        // If there's an active game, update it
        if hasActiveGame {
            viewModel.updatePlayers(playerRows: playerRows)
        }
    }
}

// MARK: - Player Preview Grid

struct PlayerPreviewGrid: View {
    let playerRows: [PlayerNameRow]
    let playerColors: [Color]
    
    private var columns: [GridItem] {
        let count = playerRows.count <= 4 ? 2 : (playerRows.count <= 6 ? 3 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(playerRows.enumerated()), id: \.element.id) { index, row in
                PlayerPreviewTile(
                    name: row.name.isEmpty ? "Player \(index + 1)" : row.name,
                    color: playerColors[safe: index] ?? .blue
                )
            }
        }
    }
}

struct PlayerPreviewTile: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Status icon (always show circle for preview)
            Image(systemName: "circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.blue)
            
            // Player name
            Text(name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Placeholder score
            Text("0")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

