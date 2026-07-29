//
//  AppTitleView.swift
//  flip7calculator
//
//  Shared Flipping Seven Calculator wordmark and card mark.
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
        VStack(spacing: 12) {
            BrandMarkView(animated: shouldAnimate)
                .frame(height: 104)

            BrandWordmarkView(showDescriptor: true)

            if showTagline {
                Text(AppBrand.tagline)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme)
                    )
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppBrand.appName)
        .accessibilityValue(showTagline ? AppBrand.tagline : "")
    }
}

struct BrandWordmarkView: View {
    var showDescriptor: Bool
    var compact: Bool = false

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: compact ? 1 : 3) {
            HStack(alignment: .firstTextBaseline, spacing: compact ? 5 : 7) {
                Text(AppBrand.wordmarkLead)
                    .foregroundStyle(
                        DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme)
                    )

                Text(AppBrand.wordmarkSeven)
                    .foregroundStyle(AppBrandPalette.gold)
                    .shadow(color: AppBrandPalette.brandBlueDeep.opacity(0.22), radius: 0, x: 1, y: 2)
            }
            .font(.custom("Nunito-Black", size: compact ? 24 : 29))
            .tracking(compact ? 0.6 : 1.0)
            .minimumScaleFactor(0.78)
            .lineLimit(1)

            if showDescriptor {
                Text(AppBrand.wordmarkDescriptor)
                    .font(.system(size: compact ? 9 : 11, weight: .bold, design: .rounded))
                    .tracking(compact ? 2.2 : 3.2)
                    .foregroundStyle(
                        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppBrand.appName)
    }
}

struct BrandMarkView: View {
    let animated: Bool

    @State private var dealtCards = Array(repeating: true, count: 7)
    @State private var faceUpCards = Array(repeating: true, count: 7)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            AppBrandPalette.brandBlueSky.opacity(0.18),
                            AppBrandPalette.gold.opacity(0.14),
                            AppBrandPalette.copper.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: AppBrandPalette.ink.opacity(0.10), radius: 22, y: 10)

            SevenCardFanView(
                dealtCards: dealtCards,
                faceUpCards: faceUpCards,
                cardSize: CGSize(width: 46, height: 68),
                horizontalSpread: 24,
                arcHeight: 10
            )
            .padding(.horizontal, 18)
        }
        .padding(.horizontal, 16)
        .task(id: animated) {
            guard animated else {
                dealtCards = Array(repeating: true, count: 7)
                faceUpCards = Array(repeating: true, count: 7)
                return
            }

            while !Task.isCancelled {
                faceUpCards = Array(repeating: false, count: 7)
                try? await Task.sleep(for: .milliseconds(450))

                for index in faceUpCards.indices {
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.34)) {
                        faceUpCards[index] = true
                    }
                    try? await Task.sleep(for: .milliseconds(135))
                }

                try? await Task.sleep(for: .seconds(2.4))
            }
        }
    }
}

struct SevenCardFanView: View {
    let dealtCards: [Bool]
    let faceUpCards: [Bool]
    let cardSize: CGSize
    let horizontalSpread: CGFloat
    let arcHeight: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                let distanceFromCenter = CGFloat(index - 3)

                BrandPlayingCard(
                    number: index + 1,
                    isFaceUp: value(in: faceUpCards, at: index, fallback: true),
                    size: cardSize
                )
                .rotationEffect(.degrees(Double(distanceFromCenter) * 3.8))
                .offset(
                    x: distanceFromCenter * horizontalSpread,
                    y: abs(distanceFromCenter) * arcHeight / 3
                )
                .opacity(value(in: dealtCards, at: index, fallback: true) ? 1 : 0)
                .offset(y: value(in: dealtCards, at: index, fallback: true) ? 0 : -cardSize.height * 1.8)
                .zIndex(Double(index))
            }
        }
        .frame(
            width: cardSize.width + horizontalSpread * 6 + 12,
            height: cardSize.height + arcHeight + 12
        )
    }

    private func value(in values: [Bool], at index: Int, fallback: Bool) -> Bool {
        values.indices.contains(index) ? values[index] : fallback
    }
}

struct BrandPlayingCard: View {
    let number: Int
    let isFaceUp: Bool
    let size: CGSize

    private var isSeven: Bool { number == 7 }
    private var cornerRadius: CGFloat { max(7, size.width * 0.19) }

    var body: some View {
        ZStack {
            cardBack
                .opacity(isFaceUp ? 0 : 1)

            cardFront
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFaceUp ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
        .rotation3DEffect(
            .degrees(isFaceUp ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.58
        )
        .shadow(color: AppBrandPalette.ink.opacity(0.16), radius: 5, y: 3)
        .accessibilityHidden(true)
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [AppBrandPalette.brandBlue, AppBrandPalette.brandBlueDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius - 2)
                    .stroke(AppBrandPalette.card.opacity(0.88), lineWidth: max(1.5, size.width * 0.045))
                    .padding(max(3, size.width * 0.09))
            )
            .overlay {
                VStack(spacing: max(2, size.height * 0.045)) {
                    Capsule().fill(AppBrandPalette.gold).frame(width: size.width * 0.30, height: 3)
                    Capsule().fill(AppBrandPalette.card.opacity(0.92)).frame(width: size.width * 0.44, height: 3)
                    Capsule().fill(AppBrandPalette.copper).frame(width: size.width * 0.24, height: 3)
                }
            }
    }

    private var cardFront: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [AppBrandPalette.card, Color.white.opacity(0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSeven ? AppBrandPalette.gold : AppBrandPalette.brandBlue.opacity(0.72),
                        lineWidth: isSeven ? max(2, size.width * 0.055) : max(1.2, size.width * 0.035)
                    )
            )
            .overlay {
                Text("\(number)")
                    .font(.custom("Nunito-Black", size: size.height * (isSeven ? 0.48 : 0.40)))
                    .foregroundStyle(isSeven ? AppBrandPalette.gold : AppBrandPalette.brandBlue)
                    .shadow(
                        color: isSeven ? AppBrandPalette.brandBlueDeep.opacity(0.18) : .clear,
                        radius: 0,
                        x: 1,
                        y: 2
                    )
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(isSeven ? AppBrandPalette.copper : AppBrandPalette.brandBlueSky)
                    .frame(width: max(4, size.width * 0.12), height: max(4, size.width * 0.12))
                    .padding(max(4, size.width * 0.11))
            }
    }
}

#Preview {
    AppTitleView()
        .padding()
}
