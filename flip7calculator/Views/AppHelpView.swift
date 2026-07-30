//
//  AppHelpView.swift
//  flip7calculator
//
//  App help and scoring guide.
//

import SwiftUI

struct AppHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultGameMode") private var defaultGameModeRaw: String = GameMode.classic.rawValue
    @AppStorage("defaultBrutalMode") private var defaultBrutalMode: Bool = ScoringRules.defaultBrutalMode
    let scoringRules: ScoringRules?

    init(scoringRules: ScoringRules? = nil) {
        self.scoringRules = scoringRules
    }

    private var rules: ScoringRules {
        scoringRules ?? ScoringRules(
            mode: GameMode(rawValue: defaultGameModeRaw) ?? .classic,
            brutalMode: defaultBrutalMode
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    HelpSection(
                        title: "Quick Start",
                        icon: "play.circle.fill",
                        color: AppBrandPalette.brandBlue,
                        bullets: [
                            "Add 2 to 8 players and set a target score.",
                            "Tap number cards as they appear during the round.",
                            "Use Bank, Bust, or Freeze to record each player's state.",
                            "Tap Continue to move through the table, then finish the round."
                        ]
                    )

                    scoringSection

                    if rules.mode == .vengeance {
                        vengeanceSpecialNumbersSection
                        vengeanceActionsSection
                    }

                    HelpSection(
                        title: "Player States",
                        icon: "person.crop.circle.badge.checkmark",
                        color: AppBrandPalette.brandBlueSky,
                        bullets: [
                            rules.mode == .vengeance
                                ? "Stay ends normal draws, but the hand remains editable when an Action changes it."
                                : "Bank locks in a player's current round score.",
                            rules.brutalMode
                                ? "A busted player can still receive negative modifiers and score below zero."
                                : "Bust scores zero for the round.",
                            rules.mode == .vengeance
                                ? "Forced Stay marks a player affected by Just One More."
                                : "Freeze marks a player who was forced to stop drawing."
                        ]
                    )

                    HelpSection(
                        title: "Useful Tools",
                        icon: "wand.and.stars",
                        color: AppBrandPalette.copper,
                        bullets: [
                            "Manual Score lets you override the automatic math for edge cases.",
                            "Undo and Redo work from the bottom action bar.",
                            "Deck Profile controls how many numbers, modifiers, and extras are available.",
                            "Game Stats summarizes trends, bonus rounds, busts, and score progression."
                        ]
                    )

                    Text(AppBrand.independenceNotice)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .appChromeBackground()
            .navigationTitle("Scoring Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var scoringSection: some View {
        HelpSection(
            title: "\(rules.mode.displayName) Scoring",
            icon: "plus.forwardslash.minus",
            color: AppBrandPalette.gold,
            bullets: rules.mode == .classic
                ? [
                    "Unique number cards add to the round total.",
                    "Each x2 doubles the number total only.",
                    "Positive modifiers are applied after multipliers.",
                    "Seven number cards earns a +\(AppBrand.sevenCardBonusValue) bonus.",
                    "A duplicate number busts the round and scores 0."
                ]
                : [
                    "Add number-card values first, then divide by 2 and round down.",
                    "Subtract -2 through -10 modifiers after division.",
                    rules.brutalMode
                        ? "Brutal mode allows the result to remain below zero."
                        : "The result cannot fall below zero.",
                    "Add the +\(AppBrand.sevenCardBonusValue) 7-card bonus last.",
                    rules.brutalMode
                        ? "The bonus may instead give one opponent -\(AppBrand.sevenCardBonusValue)."
                        : "A duplicate number busts the round and scores 0."
                ]
        )
    }

    private var vengeanceSpecialNumbersSection: some View {
        HelpSection(
            title: "Special Numbers",
            icon: "exclamationmark.square.fill",
            color: AppBrandPalette.copper,
            bullets: SpecialNumberCard.allCases.map { "\($0.displayName): \($0.effectSummary)." }
        )
    }

    private var vengeanceActionsSection: some View {
        HelpSection(
            title: "Action Results",
            icon: "arrow.left.arrow.right",
            color: AppBrandPalette.brandBlueSky,
            bullets: [
                "Just One More forces one draw and then a forced stay.",
                "Flip Four forces up to four draws, stopping on a bust or 7-card bonus.",
                "Swap and Steal move face-up cards between players; Discard removes one.",
                "Select each affected player and update their cards. Stayed hands remain editable.",
                "If an action creates a duplicate, mark every affected player as busted."
            ]
        )
    }

    private var hero: some View {
        VStack(spacing: 14) {
            BrandMarkView(animated: false)
                .frame(height: 90)

            VStack(spacing: 8) {
                BrandWordmarkView(showDescriptor: true, compact: true)

                Text("Fast, shared scorekeeping for push-your-luck card nights.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: 24)
    }
}

private struct HelpSection: View {
    let title: String
    let icon: String
    let color: Color
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            ForEach(bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(color.opacity(0.9))
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)

                    Text(bullet)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 20)
    }
}

#Preview {
    AppHelpView()
}
