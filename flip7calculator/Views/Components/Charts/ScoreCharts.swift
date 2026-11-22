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
        max(dataPoints.map(\.roundNumber).max() ?? 1, 1)
    }

    private var maxScore: Int {
        max(dataPoints.map(\.score).max() ?? 100, 20)
    }

    private var minScore: Int {
        min(dataPoints.map(\.score).min() ?? 0, 0)
    }

    private var yDomain: ClosedRange<Int> {
        let lower = minScore < 0 ? minScore - 15 : 0
        return lower...(maxScore + 20)
    }

    private var xAxisRounds: [Int] {
        if maxRound <= 6 {
            return Array(0...maxRound)
        }
        let step = max(1, Int(ceil(Double(maxRound) / 5.0)))
        var values = Array(stride(from: 0, through: maxRound, by: step))
        if values.last != maxRound {
            values.append(maxRound)
        }
        return values
    }

    var body: some View {
        let playerIDDomain = players.map { $0.id.uuidString }
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Round", point.roundNumber),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Player", point.playerId.uuidString))
            .symbol(by: .value("Player", point.playerId.uuidString))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .accessibilityLabel(point.playerName)
            .accessibilityValue("Round \(point.roundNumber), \(point.score) points")

            PointMark(
                x: .value("Round", point.roundNumber),
                y: .value("Score", point.score)
            )
            .foregroundStyle(by: .value("Player", point.playerId.uuidString))
            .symbolSize(point.roundNumber == maxRound ? 64 : 28)
            .accessibilityLabel(point.playerName)
            .accessibilityValue("Round \(point.roundNumber), \(point.score) points")
        }
        .chartForegroundStyleScale(domain: playerIDDomain, range: playerColors)
        .chartXScale(domain: 0...maxRound, range: .plotDimension(padding: 16))
        .chartXAxis {
            AxisMarks(values: xAxisRounds) { value in
                if let round = value.as(Int.self) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                    AxisTick()
                    AxisValueLabel(
                        anchor: round == 0 ? .topLeading : (round == maxRound ? .topTrailing : .top)
                    ) {
                        Text(round == 0 ? "Start" : "R\(round)")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: 10) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 72), spacing: 10, alignment: .leading)],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(playerColors[safe: index] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(player.name)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .padding(.trailing, 10)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let ranked = players.sorted { $0.totalScore > $1.totalScore }
        let standings = ranked.map { "\($0.name) \($0.totalScore) points" }.joined(separator: ", ")
        return "Score progression across \(maxRound) rounds. Final standings: \(standings)."
    }
}

// MARK: - Round Score Bar Chart

/// Bar chart showing a single player's scores per round
struct RoundScoreBarChart: View {
    let dataPoints: [RoundDataPoint]
    let playerColor: Color

    private var maxScore: Int {
        max(dataPoints.map(\.score).max() ?? 50, 20)
    }

    private var minScore: Int {
        min(dataPoints.map(\.score).min() ?? 0, 0)
    }

    var body: some View {
        Chart(dataPoints) { point in
            BarMark(
                x: .value("Round", "R\(point.roundNumber)"),
                y: .value("Score", point.score)
            )
            .foregroundStyle(point.score <= 0 ? AppBrandPalette.copper.opacity(0.65) : playerColor)
            .cornerRadius(5)
            .annotation(position: point.score >= 0 ? .top : .bottom, spacing: 3) {
                if point.score != 0 {
                    Text("\(point.score)")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
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
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartYScale(domain: (minScore < 0 ? minScore - 12 : 0)...(maxScore + 12))
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let rounds = dataPoints.map { "Round \($0.roundNumber): \($0.score)" }.joined(separator: ", ")
        return "Round scores: \(rounds)"
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

    private var minScore: Int {
        min(scores.min() ?? 0, 0)
    }

    var body: some View {
        Chart(Array(scores.enumerated()), id: \.offset) { index, score in
            LineMark(
                x: .value("Round", index),
                y: .value("Score", score)
            )
            .foregroundStyle(color)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

            AreaMark(
                x: .value("Round", index),
                y: .value("Score", score)
            )
            .foregroundStyle(color.opacity(0.14))
            .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (minScore < 0 ? minScore - 5 : 0)...(maxScore + 5))
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Score Distribution Mini Chart

/// Small horizontal bar showing score breakdown components
struct ScoreBreakdownBar: View {
    let numberPoints: Int
    let modifierPoints: Int
    let multiplierEffect: Int
    let sevenCardBonus: Int

    private var total: Int {
        max(numberPoints + modifierPoints + multiplierEffect + sevenCardBonus, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1.5) {
                if numberPoints > 0 {
                    Rectangle()
                        .fill(AppBrandPalette.brandBlue.opacity(0.88))
                        .frame(width: segmentWidth(for: numberPoints, in: geometry.size.width))
                }
                if multiplierEffect > 0 {
                    Rectangle()
                        .fill(AppBrandPalette.brandBlueSky.opacity(0.88))
                        .frame(width: segmentWidth(for: multiplierEffect, in: geometry.size.width))
                }
                if modifierPoints > 0 {
                    Rectangle()
                        .fill(AppBrandPalette.copper.opacity(0.88))
                        .frame(width: segmentWidth(for: modifierPoints, in: geometry.size.width))
                }
                if sevenCardBonus > 0 {
                    Rectangle()
                        .fill(AppBrandPalette.gold.opacity(0.92))
                        .frame(width: segmentWidth(for: sevenCardBonus, in: geometry.size.width))
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppBrandPalette.mist.opacity(0.35))
        )
    }

    private func segmentWidth(for value: Int, in totalWidth: CGFloat) -> CGFloat {
        CGFloat(value) / CGFloat(total) * totalWidth
    }
}
