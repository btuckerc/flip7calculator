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
    
    @AppStorage("playerPalette") private var playerPaletteRaw: String = PlayerPalette.classic.rawValue
    
    private var selectedPalette: PlayerPalette {
        PlayerPalette(rawValue: playerPaletteRaw) ?? PlayerPalette.fromLegacyRawValue(playerPaletteRaw)
    }
    
    private var playerColors: [Color] {
        PlayerColorResolver.colors(count: playerRows.count, palette: selectedPalette)
    }
    
    private var hasActiveGame: Bool {
        viewModel.game != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Preview section - card style matching main menu
                if !playerRows.isEmpty {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Preview")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        // Preview grid
                        PlayerPreviewGrid(
                            playerRows: playerRows,
                            playerColors: playerColors
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Players editor card - using shared component
                PlayersEditorCard(
                    playerRows: $playerRows,
                    focusCoordinator: focusCoordinator,
                    onPersist: saveChanges
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusCoordinator.clearFocus()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Manage Players")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadRoster()
        }
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
