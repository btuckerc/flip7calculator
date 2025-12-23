//
//  ScoreEngineTests.swift
//  flip7calculatorTests
//
//  Created by Tucker Craig on 12/16/25.
//

import Testing
@testable import flip7calculator

struct ScoreEngineTests {
    
    // MARK: - Basic Scoring Tests
    
    @Test func testBasicNumberCardScoring() {
        let hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 15) // 1+2+3+4+5 = 15
    }
    
    @Test func testZeroCard() {
        let hand = RoundHand(selectedNumbers: [0, 1, 2])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 3) // 0+1+2 = 3
    }
    
    @Test func testHighValueCards() {
        let hand = RoundHand(selectedNumbers: [10, 11, 12])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 33) // 10+11+12 = 33
    }
    
    // MARK: - Bust Tests
    
    @Test func testBustedPlayerScoresZero() {
        let hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .busted)
        #expect(score == 0) // Busted players always score 0
    }
    
    @Test func testBustedPlayerWithModifiersScoresZero() {
        var hand = RoundHand(selectedNumbers: [1, 2, 3])
        hand.addModifier(10)
        hand.addX2()
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .busted)
        #expect(score == 0) // Even with modifiers, busted = 0
    }
    
    // MARK: - Multiplier Tests
    
    @Test func testSingleX2Multiplier() {
        var hand = RoundHand(selectedNumbers: [5, 6, 7])
        hand.addX2()
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 36) // (5+6+7) * 2 = 36
    }
    
    @Test func testMultipleX2Multipliers() {
        var hand = RoundHand(selectedNumbers: [2, 3, 4])
        hand.addX2()
        hand.addX2()
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 36) // (2+3+4) * 2^2 = 9 * 4 = 36
    }
    
    @Test func testX2OnlyAffectsNumberSum() {
        var hand = RoundHand(selectedNumbers: [5, 6])
        hand.addX2()
        hand.addModifier(10)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        // (5+6) * 2 + 10 = 22 + 10 = 32
        // x2 should NOT double the modifier
        #expect(score == 32)
    }
    
    // MARK: - Modifier Tests
    
    @Test func testSingleAdditiveModifier() {
        var hand = RoundHand(selectedNumbers: [3, 4, 5])
        hand.addModifier(2)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 14) // (3+4+5) + 2 = 12 + 2 = 14
    }
    
    @Test func testMultipleAdditiveModifiers() {
        var hand = RoundHand(selectedNumbers: [1, 2])
        hand.addModifier(4)
        hand.addModifier(6)
        hand.addModifier(8)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 21) // (1+2) + 4 + 6 + 8 = 3 + 18 = 21
    }
    
    @Test func testMultipleOfSameModifier() {
        var hand = RoundHand(selectedNumbers: [5])
        hand.addModifier(2)
        hand.addModifier(2)
        hand.addModifier(2)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 11) // 5 + (2*3) = 5 + 6 = 11
    }
    
    // MARK: - Flip 7 Bonus Tests
    
    @Test func testFlip7Bonus() {
        let hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 43) // (1+2+3+4+5+6+7) + 15 = 28 + 15 = 43
    }
    
    @Test func testFlip7BonusWithMoreThan7Cards() {
        let hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 60) // (1+2+3+4+5+6+7+8+9) + 15 = 45 + 15 = 60
    }
    
    @Test func testNoFlip7BonusWith6Cards() {
        let hand = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 21) // 1+2+3+4+5+6 = 21 (no bonus)
    }
    
    // MARK: - Complex Scoring Tests
    
    @Test func testComplexHandWithAllComponents() {
        var hand = RoundHand(selectedNumbers: [3, 4, 5, 6, 7, 8, 9])
        hand.addX2()
        hand.addModifier(4)
        hand.addModifier(6)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        // (3+4+5+6+7+8+9) * 2 + 4 + 6 + 15 = 42 * 2 + 10 + 15 = 84 + 25 = 109
        #expect(score == 109)
    }
    
    @Test func testMultipleX2WithModifiers() {
        var hand = RoundHand(selectedNumbers: [2, 3, 4])
        hand.addX2()
        hand.addX2()
        hand.addModifier(10)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        // (2+3+4) * 2^2 + 10 = 9 * 4 + 10 = 36 + 10 = 46
        #expect(score == 46)
    }
    
    @Test func testEmptyHand() {
        let hand = RoundHand()
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 0)
    }
    
    @Test func testHandWithOnlyModifiers() {
        var hand = RoundHand()
        hand.addModifier(10)
        hand.addModifier(8)
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 18) // 0 + 10 + 8 = 18
    }
    
    // MARK: - State Tests
    
    @Test func testInRoundState() {
        let hand = RoundHand(selectedNumbers: [5, 6, 7])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .inRound)
        #expect(score == 18) // States other than busted work normally
    }
    
    @Test func testBankedState() {
        let hand = RoundHand(selectedNumbers: [5, 6, 7])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .banked)
        #expect(score == 18)
    }
    
    @Test func testFrozenState() {
        let hand = RoundHand(selectedNumbers: [5, 6, 7])
        let score = ScoreEngine.calculateRoundScore(hand: hand, state: .frozen)
        #expect(score == 18) // Frozen is like banked for scoring
    }
    
    // MARK: - RoundHand Tests
    
    @Test func testAddNumberReturnsDuplicate() {
        var hand = RoundHand()
        let isDuplicate1 = hand.addNumber(5)
        let isDuplicate2 = hand.addNumber(5)
        #expect(isDuplicate1 == false)
        #expect(isDuplicate2 == true)
        #expect(hand.selectedNumbers.contains(5))
    }
    
    @Test func testRemoveNumber() {
        var hand = RoundHand(selectedNumbers: [1, 2, 3])
        hand.removeNumber(2)
        #expect(hand.selectedNumbers.contains(2) == false)
        #expect(hand.selectedNumbers.contains(1))
        #expect(hand.selectedNumbers.contains(3))
    }
    
    @Test func testAddModifier() {
        var hand = RoundHand()
        hand.addModifier(4)
        hand.addModifier(4)
        #expect(hand.addMods[4] == 2)
    }
    
    @Test func testRemoveModifier() {
        var hand = RoundHand()
        hand.addModifier(6)
        hand.addModifier(6)
        hand.removeModifier(6)
        #expect(hand.addMods[6] == 1)
        hand.removeModifier(6)
        #expect(hand.addMods[6] == nil)
    }
    
    @Test func testX2Count() {
        var hand = RoundHand()
        hand.addX2()
        hand.addX2()
        #expect(hand.x2Count == 2)
        hand.removeX2()
        #expect(hand.x2Count == 1)
        hand.removeX2()
        #expect(hand.x2Count == 0)
        hand.removeX2() // Should not go negative
        #expect(hand.x2Count == 0)
    }
    
    @Test func testHasFlip7Bonus() {
        let hand6 = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6])
        let hand7 = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7])
        let hand8 = RoundHand(selectedNumbers: [1, 2, 3, 4, 5, 6, 7, 8])
        
        #expect(hand6.hasFlip7Bonus == false)
        #expect(hand7.hasFlip7Bonus == true)
        #expect(hand8.hasFlip7Bonus == true)
    }
    
    @Test func testNumberSum() {
        let hand = RoundHand(selectedNumbers: [0, 5, 10, 12])
        #expect(hand.numberSum == 27)
    }
    
    @Test func testModifierSum() {
        var hand = RoundHand()
        hand.addModifier(2)
        hand.addModifier(2)
        hand.addModifier(4)
        hand.addModifier(10)
        #expect(hand.modifierSum == 18) // 2*2 + 4 + 10 = 18
    }
}



