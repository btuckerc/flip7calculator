//
//  AppTitleView.swift
//  flip7calculator
//
//  Shared Lucky Ledger wordmark and glyph.
//

import SwiftUI

struct AppTitleView: View {
    var showTagline: Bool = true
    @AppStorage("animateMainMenuTitle") private var animateMainMenuTitle: Bool = true
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    private var shouldAnimate: Bool {
        animateMainMenuTitle && !DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            BrandMarkView(animated: shouldAnimate)
                .frame(height: 94)

            VStack(spacing: 6) {
                Text(AppBrand.appName)
                    .font(.custom("Nunito-Black", size: 34))
                    .tracking(0.3)
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))

                if showTagline {
                    Text(AppBrand.tagline)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct BrandMarkView: View {
    let animated: Bool

    @State private var liftLedger = false
    @State private var pulseDie = false
    @State private var swayCard = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            AppBrandPalette.gold.opacity(0.16),
                            AppBrandPalette.brandBlueSky.opacity(0.12),
                            AppBrandPalette.copper.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: AppBrandPalette.ink.opacity(0.10), radius: 22, y: 10)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppBrandPalette.brandBlueDeep)
                    .frame(width: 68, height: 82)
                    .rotationEffect(.degrees(animated && swayCard ? -13 : -9))
                    .offset(x: -24, y: animated && swayCard ? -5 : 2)
                    .overlay(alignment: .topTrailing) {
                        Triangle()
                            .fill(AppBrandPalette.card)
                            .frame(width: 18, height: 18)
                            .rotationEffect(.degrees(180))
                            .offset(x: -10, y: 10)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text("7")
                            .font(.custom("Nunito-Black", size: 30))
                            .foregroundStyle(AppBrandPalette.gold)
                            .offset(x: 12, y: -10)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [AppBrandPalette.card, Color.white.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 104)
                    .rotationEffect(.degrees(animated && liftLedger ? 2 : 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppBrandPalette.ink.opacity(0.14), lineWidth: 2)
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppBrandPalette.brandBlue)
                            .frame(width: 40, height: 24)
                            .overlay(
                                Text("LL")
                                    .font(.custom("Nunito-Black", size: 14))
                                    .tracking(0.6)
                                    .foregroundStyle(AppBrandPalette.card)
                            )
                            .offset(x: 12, y: 12)
                    }
                    .overlay {
                        VStack(alignment: .leading, spacing: 10) {
                            ledgerRow(dot: AppBrandPalette.brandBlue, width: 34)
                            ledgerRow(dot: AppBrandPalette.gold, width: 28)
                            ledgerRow(dot: AppBrandPalette.copper, width: 40)
                        }
                        .padding(.top, 18)
                        .padding(.horizontal, 14)
                    }
                    .overlay(alignment: .trailing) {
                        PencilAccentView()
                            .scaleEffect(1.22)
                            .rotationEffect(.degrees(18))
                            .offset(x: 8, y: -8)
                    }
                    .shadow(color: .black.opacity(0.10), radius: 14, y: 6)

                DiceBadgeView()
                    .scaleEffect(animated && pulseDie ? 1.06 : 1.0)
                    .offset(x: 34, y: 26)
                    .shadow(color: AppBrandPalette.gold.opacity(0.28), radius: 12, y: 4)
            }
            .offset(y: animated && liftLedger ? -1 : 2)
            .padding(.horizontal, 18)
        }
        .padding(.horizontal, 16)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                liftLedger = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseDie = true
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                swayCard = true
            }
        }
    }

    private func ledgerRow(dot: Color, width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dot)
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 5)
                .fill(AppBrandPalette.mist)
                .frame(width: width, height: 10)

            RoundedRectangle(cornerRadius: 5)
                .fill(dot.opacity(0.92))
                .frame(width: 18, height: 10)
        }
    }
}

struct DiceBadgeView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AppBrandPalette.gold)
            .frame(width: 34, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppBrandPalette.card.opacity(0.88), lineWidth: 2)
            )
            .overlay {
                ZStack {
                    pip(x: -8, y: -8)
                    pip(x: 8, y: -8)
                    pip(x: 0, y: 0)
                    pip(x: -8, y: 8)
                    pip(x: 8, y: 8)
                }
            }
    }

    private func pip(x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(AppBrandPalette.ink)
            .frame(width: 4.5, height: 4.5)
            .offset(x: x, y: y)
    }
}

struct PencilAccentView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(AppBrandPalette.brandBlue)
                .frame(width: 13, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(AppBrandPalette.card.opacity(0.92), lineWidth: 1.5)
                )

            Rectangle()
                .fill(AppBrandPalette.mist)
                .frame(width: 13, height: 8)
                .offset(y: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(AppBrandPalette.copper)
                .frame(width: 18, height: 12)
                .offset(y: 21)

            PencilTipShape()
                .fill(AppBrandPalette.gold)
                .frame(width: 13, height: 11)
                .offset(y: -24)

            PencilTipShape()
                .fill(AppBrandPalette.ink)
                .frame(width: 5, height: 4)
                .offset(y: -30)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PencilTipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    AppTitleView()
        .padding()
}
