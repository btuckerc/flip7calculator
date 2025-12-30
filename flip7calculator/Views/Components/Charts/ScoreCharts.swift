//
//  ScoreCharts.swift
//  flip7calculator
//
//  Swift Charts components for game-over stats visualization.
//

import SwiftUI
import Charts

// MARK: - Cumulative Score Line Chart

/// Multi-line chart showing cumulative scores over rounds
struct CumulativeScoreChart: View {
    let dataPoints: [RoundDataPoint]
    let players: [Player]
    let playerColors: [Color]
    
    private var maxRound: Int {
        dataPoints.map { $0.roundNumber }.max() ?? 1
    }
    
    private var maxScore: Int {
        dataPoints.map { $0.score }.max() ?? 100
    }
    
    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Round", point.roundNumber),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Player", point.playerName))
            .symbol(by: .value("Player", point.playerName))
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Round", point.roundNumber),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Player", point.playerName))
            .symbolSize(point.roundNumber == maxRound ? 60 : 30)
        }
        .chartForegroundStyleScale(domain: players.map { $0.name }, range: playerColors)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(maxRound + 1, 8))) { value in
                if let round = value.as(Int.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(round == 0 ? "Start" : "R\(round)")
                            .font(.system(size: 10, design: .rounded))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisTick()
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.system(size: 10, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(playerColors[safe: index] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(player.name)
                            .font(.system(size: 11, design: .rounded))
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(maxScore + 20))
    }
}

// MARK: - Round Score Bar Chart

/// Bar chart showing a single player's scores per round
struct RoundScoreBarChart: View {
    let dataPoints: [RoundDataPoint]
    let playerColor: Color
    
    private var maxScore: Int {
        max(dataPoints.map { $0.score }.max() ?? 50, 20)
    }
    
    var body: some View {
        Chart(dataPoints) { point in
            BarMark(
                x: .value("Round", "R\(point.roundNumber)"),
                y: .value("Score", point.score)
            )
            .foregroundStyle(point.score == 0 ? Color.red.opacity(0.6) : playerColor)
            .cornerRadius(4)
            .annotation(position: .top, spacing: 2) {
                if point.score > 0 {
                    Text("\(point.score)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.system(size: 10, design: .rounded))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.system(size: 10, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartYScale(domain: 0...(maxScore + 10))
    }
}

// MARK: - Compact Sparkline

/// A minimal sparkline for inline display
struct ScoreSparkline: View {
    let scores: [Int]
    let color: Color
    let height: CGFloat
    
    private var maxScore: Int {
        max(scores.max() ?? 1, 1)
    }
    
    var body: some View {
        Chart(Array(scores.enumerated()), id: \.offset) { index, score in
            LineMark(
                x: .value("Round", index),
                y: .value("Score", score)
            )
            .foregroundStyle(color.gradient)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Round", index),
                y: .value("Score", score)
            )
            .foregroundStyle(color.opacity(0.15).gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(maxScore + 5))
        .frame(height: height)
    }
}

// MARK: - Score Distribution Mini Chart

/// Small horizontal bar showing score breakdown components
struct ScoreBreakdownBar: View {
    let numberPoints: Int
    let modifierPoints: Int
    let multiplierEffect: Int
    let flip7Bonus: Int
    
    private var total: Int {
        max(numberPoints + modifierPoints + multiplierEffect + flip7Bonus, 1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                // Numbers (base)
                if numberPoints > 0 {
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: segmentWidth(for: numberPoints, in: geometry.size.width))
                }
                
                // Multiplier effect
                if multiplierEffect > 0 {
                    Rectangle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: segmentWidth(for: multiplierEffect, in: geometry.size.width))
                }
                
                // Modifiers
                if modifierPoints > 0 {
                    Rectangle()
                        .fill(Color.orange.opacity(0.7))
                        .frame(width: segmentWidth(for: modifierPoints, in: geometry.size.width))
                }
                
                // Flip7 bonus
                if flip7Bonus > 0 {
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: segmentWidth(for: flip7Bonus, in: geometry.size.width))
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
        )
    }
    
    private func segmentWidth(for value: Int, in totalWidth: CGFloat) -> CGFloat {
        CGFloat(value) / CGFloat(total) * totalWidth
    }
}

// MARK: - Previews

#Preview("Cumulative Chart") {
    let players = [
        Player(name: "Alice"),
        Player(name: "Bob"),
        Player(name: "Charlie")
    ]
    
    let dataPoints = [
        RoundDataPoint(roundNumber: 0, score: 0, playerName: "Alice", playerId: players[0].id),
        RoundDataPoint(roundNumber: 0, score: 0, playerName: "Bob", playerId: players[1].id),
        RoundDataPoint(roundNumber: 0, score: 0, playerName: "Charlie", playerId: players[2].id),
        RoundDataPoint(roundNumber: 1, score: 45, playerName: "Alice", playerId: players[0].id),
        RoundDataPoint(roundNumber: 1, score: 32, playerName: "Bob", playerId: players[1].id),
        RoundDataPoint(roundNumber: 1, score: 0, playerName: "Charlie", playerId: players[2].id),
        RoundDataPoint(roundNumber: 2, score: 45, playerName: "Alice", playerId: players[0].id),
        RoundDataPoint(roundNumber: 2, score: 90, playerName: "Bob", playerId: players[1].id),
        RoundDataPoint(roundNumber: 2, score: 41, playerName: "Charlie", playerId: players[2].id),
        RoundDataPoint(roundNumber: 3, score: 112, playerName: "Alice", playerId: players[0].id),
        RoundDataPoint(roundNumber: 3, score: 115, playerName: "Bob", playerId: players[1].id),
        RoundDataPoint(roundNumber: 3, score: 79, playerName: "Charlie", playerId: players[2].id),
    ]
    
    let colors = PlayerColorResolver.colors(count: 3, palette: .classic)
    
    return CumulativeScoreChart(dataPoints: dataPoints, players: players, playerColors: colors)
        .frame(height: 200)
        .padding()
}

#Preview("Bar Chart") {
    let playerId = UUID()
    let dataPoints = [
        RoundDataPoint(roundNumber: 1, score: 45, playerName: "Alice", playerId: playerId),
        RoundDataPoint(roundNumber: 2, score: 0, playerName: "Alice", playerId: playerId),
        RoundDataPoint(roundNumber: 3, score: 67, playerName: "Alice", playerId: playerId),
        RoundDataPoint(roundNumber: 4, score: 32, playerName: "Alice", playerId: playerId),
        RoundDataPoint(roundNumber: 5, score: 58, playerName: "Alice", playerId: playerId),
    ]
    
    return RoundScoreBarChart(dataPoints: dataPoints, playerColor: .orange)
        .frame(height: 150)
        .padding()
}

#Preview("Sparkline") {
    ScoreSparkline(scores: [45, 0, 67, 32, 58, 41, 0, 73], color: .blue, height: 40)
        .padding()
}

#Preview("Breakdown Bar") {
    VStack(spacing: 20) {
        ScoreBreakdownBar(numberPoints: 45, modifierPoints: 10, multiplierEffect: 45, flip7Bonus: 15)
            .frame(width: 200)
        
        ScoreBreakdownBar(numberPoints: 30, modifierPoints: 0, multiplierEffect: 0, flip7Bonus: 0)
            .frame(width: 200)
    }
    .padding()
}

