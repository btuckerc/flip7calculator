//
//  GameViewModelUndoTests.swift
//  flip7calculatorTests
//
//  Created by Tucker Craig on 12/16/25.
//

import Testing
@testable import flip7calculator

struct GameViewModelUndoTests {
    
    @Test func testUndoRedoBasic() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist after startNewGame")
            return
        }
        
        let playerId = game.players[0].id
        
        // Perform an action
        viewModel.addCardToPlayer(playerId, number: 5)
        
        // Verify action occurred
        guard let gameAfter = viewModel.game else {
            Issue.record("Game should exist after action")
            return
        }
        #expect(gameAfter.players[0].currentRound.hand.selectedNumbers.contains(5))
        
        // Undo
        viewModel.undo()
        
        guard let gameAfterUndo = viewModel.game else {
            Issue.record("Game should exist after undo")
            return
        }
        #expect(!gameAfterUndo.players[0].currentRound.hand.selectedNumbers.contains(5))
        #expect(viewModel.canRedo)
        
        // Redo
        viewModel.redo()
        
        guard let gameAfterRedo = viewModel.game else {
            Issue.record("Game should exist after redo")
            return
        }
        #expect(gameAfterRedo.players[0].currentRound.hand.selectedNumbers.contains(5))
        #expect(!viewModel.canRedo)
    }
    
    @Test func testUndoRedoMultipleActions() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        let playerId = game.players[0].id
        
        // Perform multiple actions
        viewModel.addCardToPlayer(playerId, number: 3)
        viewModel.addCardToPlayer(playerId, number: 7)
        viewModel.addModifierToPlayer(playerId, value: 4)
        
        // Undo three times
        viewModel.undo()
        viewModel.undo()
        viewModel.undo()
        
        guard let gameAfterUndos = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        #expect(gameAfterUndos.players[0].currentRound.hand.selectedNumbers.isEmpty)
        #expect(gameAfterUndos.players[0].currentRound.hand.addMods.isEmpty)
        #expect(viewModel.canRedo)
    }
    
    @Test func testUndoClearsRedoStack() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        let playerId = game.players[0].id
        
        // Perform action and undo
        viewModel.addCardToPlayer(playerId, number: 5)
        viewModel.undo()
        
        #expect(viewModel.canRedo)
        
        // Perform new action - should clear redo stack
        viewModel.addCardToPlayer(playerId, number: 8)
        
        #expect(!viewModel.canRedo)
    }
    
    @Test func testUndoRedoPlayerStateChanges() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        let playerId = game.players[0].id
        
        // Change state
        viewModel.bankPlayer(playerId)
        
        guard let gameAfterBank = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterBank.players[0].currentRound.state == .banked)
        
        // Undo
        viewModel.undo()
        
        guard let gameAfterUndo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterUndo.players[0].currentRound.state == .inRound)
        
        // Redo
        viewModel.redo()
        
        guard let gameAfterRedo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterRedo.players[0].currentRound.state == .banked)
    }
    
    @Test func testUndoRedoModifierChanges() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        let playerId = game.players[0].id
        
        // Add modifier
        viewModel.addModifierToPlayer(playerId, value: 6)
        
        guard let gameAfterAdd = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterAdd.players[0].currentRound.hand.addMods[6] == 1)
        
        // Undo
        viewModel.undo()
        
        guard let gameAfterUndo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterUndo.players[0].currentRound.hand.addMods[6] == nil || gameAfterUndo.players[0].currentRound.hand.addMods[6] == 0)
        
        // Redo
        viewModel.redo()
        
        guard let gameAfterRedo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterRedo.players[0].currentRound.hand.addMods[6] == 1)
    }
    
    @Test func testUndoRedoX2Changes() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        
        let playerId = game.players[0].id
        
        // Add x2
        viewModel.addX2ToPlayer(playerId)
        viewModel.addX2ToPlayer(playerId)
        
        guard let gameAfterAdd = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterAdd.players[0].currentRound.hand.x2Count == 2)
        
        // Undo twice
        viewModel.undo()
        viewModel.undo()
        
        guard let gameAfterUndo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterUndo.players[0].currentRound.hand.x2Count == 0)
        
        // Redo twice
        viewModel.redo()
        viewModel.redo()
        
        guard let gameAfterRedo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterRedo.players[0].currentRound.hand.x2Count == 2)
    }
    
    @Test func testUndoRedoTargetScoreChanges() {
        let viewModel = GameViewModel()
        viewModel.startNewGame(players: ["Alice", "Bob"], targetScore: 200)
        
        guard let game = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(game.targetScore == 200)
        
        // Update target score
        viewModel.updateTargetScore(300)
        
        guard let gameAfterUpdate = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterUpdate.targetScore == 300)
        
        // Undo
        viewModel.undo()
        
        guard let gameAfterUndo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterUndo.targetScore == 200)
        #expect(viewModel.canRedo)
        
        // Redo
        viewModel.redo()
        
        guard let gameAfterRedo = viewModel.game else {
            Issue.record("Game should exist")
            return
        }
        #expect(gameAfterRedo.targetScore == 300)
        #expect(!viewModel.canRedo)
    }
}

