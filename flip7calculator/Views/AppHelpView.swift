//
//  AppHelpView.swift
//  flip7calculator
//
//  Generic help and scoring guide for the rebranded app.
//

import SwiftUI

struct AppHelpView: View {
    @Environment(\.dismiss) private var dismiss

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
                            "Use Bank, Bust, or Hold to lock in each player's state.",
                            "Tap Continue to move through the table, then finish the round."
                        ]
                    )

                    HelpSection(
                        title: "Scoring Profile",
                        icon: "plus.forwardslash.minus",
                        color: AppBrandPalette.gold,
                        bullets: [
                            "Unique number cards add to the round total.",
                            "Each ×2 doubles the number total only.",
                            "Add-on cards are applied after multipliers.",
                            "Seven unique numbers earns a +\(AppBrand.sevenCardBonusValue) bonus.",
                            "A duplicate number busts the round and scores 0."
                        ]
                    )

                    HelpSection(
                        title: "Player States",
                        icon: "person.crop.circle.badge.checkmark",
                        color: AppBrandPalette.brandBlueSky,
                        bullets: [
                            "Bank locks in a player's current round score.",
                            "Bust zeros the round, even if modifiers were added.",
                            "Hold marks a player who was forced to stop drawing."
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
                }
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

    private var hero: some View {
        VStack(spacing: 14) {
            BrandMarkView(animated: false)
                .frame(height: 90)

            VStack(spacing: 6) {
                Text(AppBrand.appName)
                    .font(.custom("Nunito-Black", size: 30))
                    .foregroundStyle(.primary)

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
