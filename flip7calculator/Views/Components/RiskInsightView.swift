//
//  RiskInsightView.swift
//  flip7calculator
//

import SwiftUI

struct RiskPillButton: View {
    let insight: RiskInsight
    let mode: RiskInsightsMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .font(.system(size: 11, weight: .bold))
                Text(insight.compactLabel(mode: mode))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .pillBadge(tone)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(insight.accessibilityMetricLabel)
        .accessibilityValue(insight.compactLabel(mode: mode))
        .accessibilityHint("Shows how this risk was calculated")
    }

    private var tone: PillBadgeTone {
        switch insight.probability {
        case ..<0.10: return .info
        case ..<0.25: return .neutral
        case ..<0.40: return .warning
        default: return .danger
        }
    }
}

struct RiskInsightSheet: View {
    let insight: RiskInsight
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                    VStack(spacing: DesignSpacing.xs) {
                        Text("\(insight.percentage)%")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                        Text(metricExplanation)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSpacing.lg)
                    .cardSurface()

                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                        Label(insight.confidence.shortLabel, systemImage: confidenceIcon)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(confidenceExplanation)
                            .font(DesignTypography.font(.body))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                    }

                    VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                        Text("Dangerous numbers")
                            .font(.system(size: 17, weight: .bold, design: .rounded))

                        if insight.dangerousNumberCounts.isEmpty {
                            Text("No card in the current draw pool would immediately bust this player.")
                                .font(DesignTypography.font(.body))
                                .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                        } else {
                            ForEach(insight.dangerousNumberCounts.keys.sorted(), id: \.self) { number in
                                HStack {
                                    Text("Number \(number)")
                                    Spacer()
                                    Text("\(insight.dangerousNumberCounts[number] ?? 0) remaining")
                                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                                }
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                        }
                    }
                    .padding(DesignSpacing.md)
                    .cardSurface()

                    Text("\(insight.unsafeCardCount) \(countLabel) out of \(insight.totalCardCount). This is information, not a recommendation to draw or stay.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                }
                .padding(DesignSpacing.lg)
            }
            .navigationTitle("Next-Card Risk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .appChromeBackground()
        }
    }

    private var confidenceIcon: String {
        switch insight.confidence {
        case .exactDigitalDeck: return "checkmark.seal.fill"
        case .estimateCurrentTable: return "scope"
        }
    }

    private var confidenceExplanation: String {
        switch insight.confidence {
        case .exactDigitalDeck:
            return "Exact from the app-owned draw pile. Every revealed, discarded, and live table card is accounted for."
        case .estimateCurrentTable:
            return "Estimated from the configured deck and score-relevant cards currently entered. Earlier physical discards and action effects are unknown, so protection may change the outcome."
        }
    }

    private var metricExplanation: String {
        switch insight.confidence {
        case .exactDigitalDeck:
            return "chance the next card immediately busts this player"
        case .estimateCurrentTable:
            return "estimated chance the next card matches a number in this hand"
        }
    }

    private var countLabel: String {
        switch insight.confidence {
        case .exactDigitalDeck:
            return "unsafe card\(insight.unsafeCardCount == 1 ? "" : "s")"
        case .estimateCurrentTable:
            return "matching card\(insight.unsafeCardCount == 1 ? "" : "s")"
        }
    }
}
