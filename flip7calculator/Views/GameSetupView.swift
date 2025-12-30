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
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content - scrollable (includes title)
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero title section
                        VStack(spacing: 10) {
                            Flip7TitleView()
                            
                            // How to Play button
                            Button(action: { showingRules = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("How to Play")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusCoordinator.clearFocus()
                        }
                        
                        // Players card - using shared component
                        PlayersEditorCard(
                            playerRows: $playerRows,
                            focusCoordinator: focusCoordinator,
                            onPersist: persistRosterOrder
                        )
                        
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
                        
                        // Reset to 200 link
                        if targetScore != 200 {
                            Button(action: { targetScore = 200 }) {
                                Text("Reset to 200")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.top, 4)
                        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingTargetScoreEditor) {
                TargetScoreEditorSheet(targetScore: $targetScore) { newScore in
                    targetScore = newScore
                }
                .preferredColorScheme(selectedTheme.colorScheme)
                .tint(selectedTheme.accentColor)
                .id(appTheme)
            }
            .sheet(isPresented: $showingRules) {
                RulesView()
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(selectedTheme.accentColor)
                    .id(appTheme)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
                    .preferredColorScheme(selectedTheme.colorScheme)
                    .tint(selectedTheme.accentColor)
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
