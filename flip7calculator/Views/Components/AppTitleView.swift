//
//  AppTitleView.swift
//  flip7calculator
//
//  Shared Flipping Seven Calculator wordmark and card mark.
//

import SwiftUI

struct AppTitleView: View {
    var showTagline: Bool = true
    var allowsAnimation: Bool = true

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
        VStack(spacing: 8) {
            BrandMarkView(
                animated: allowsAnimation && shouldAnimate,
                showsFaceUpWhenStatic: allowsAnimation
            )
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
                    .foregroundStyle(
                        DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme)
                    )
                    .shadow(color: AppBrandPalette.brandBlueDeep.opacity(0.22), radius: 0, x: 1, y: 2)
            }
            .font(.custom("Nunito-Black", fixedSize: compact ? 24 : 29))
            .tracking(compact ? 0.6 : 1.0)
            .minimumScaleFactor(0.78)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)

            if showDescriptor {
                Text(AppBrand.wordmarkDescriptor)
                    .font(.system(size: compact ? 9 : 11, weight: .bold, design: .rounded))
                    .tracking(compact ? 2.2 : 3.2)
                    .foregroundStyle(
                        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppBrand.appName)
    }
}

struct BrandMarkView: View {
    let animated: Bool
    var showsFaceUpWhenStatic: Bool = true

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    private let dealtCards = Array(repeating: true, count: 7)
    @State private var faceUpCards: [Bool]

    private var animationTaskID: Int {
        (animated ? 2 : 0) + (showsFaceUpWhenStatic ? 1 : 0)
    }

    init(animated: Bool, showsFaceUpWhenStatic: Bool = true) {
        self.animated = animated
        self.showsFaceUpWhenStatic = showsFaceUpWhenStatic
        _faceUpCards = State(
            initialValue: Array(repeating: animated ? false : showsFaceUpWhenStatic, count: 7)
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    DesignColor.color(.surfaceInteractive, theme: visualTheme, colorScheme: colorScheme)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: AppBrandPalette.ink.opacity(0.10), radius: 22, y: 10)

            SevenCardFanView(
                dealtCards: dealtCards,
                faceUpCards: faceUpCards,
                cardSize: CGSize(width: 52, height: 76),
                horizontalSpread: 27,
                arcHeight: 9
            )
            .offset(y: -5)
            .padding(.horizontal, 18)
        }
        .padding(.horizontal, 16)
        .task(id: animationTaskID) {
            guard animated else {
                faceUpCards = Array(repeating: showsFaceUpWhenStatic, count: 7)
                return
            }

            faceUpCards = Array(repeating: false, count: 7)
            guard await pause(for: .milliseconds(320)) else { return }

            while !Task.isCancelled {
                guard await flipCards(faceUpCards.indices, faceUp: true) else { return }
                guard await pause(for: .seconds(2.0)) else { return }
                guard await flipCards(faceUpCards.indices.reversed(), faceUp: false) else { return }
                guard await pause(for: .milliseconds(900)) else { return }
            }
        }
    }

    @MainActor
    private func flipCards<S: Sequence>(_ indices: S, faceUp: Bool) async -> Bool where S.Element == Int {
        for index in indices {
            guard !Task.isCancelled else { return false }
            withAnimation(.smooth(duration: 0.38)) {
                faceUpCards[index] = faceUp
            }
            guard await pause(for: .milliseconds(110)) else { return false }
        }
        return true
    }

    private func pause(for duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
            return true
        } catch {
            return false
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
                let normalizedDistance = distanceFromCenter / 3

                BrandPlayingCard(
                    number: index + 1,
                    isFaceUp: value(in: faceUpCards, at: index, fallback: true),
                    size: cardSize
                )
                .rotationEffect(.degrees(Double(distanceFromCenter) * 3.2 - 1.2))
                .offset(
                    x: distanceFromCenter * horizontalSpread,
                    y: normalizedDistance * normalizedDistance * arcHeight
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
    private var numberColor: Color {
        isSeven ? AppBrandPalette.goldDeep : AppBrandPalette.brandBlue
    }

    var body: some View {
        FlippingCardFace(
            angle: isFaceUp ? 180 : 0,
            front: cardFront,
            back: cardBack
        )
        .frame(width: size.width, height: size.height)
        .shadow(color: AppBrandPalette.ink.opacity(0.16), radius: 5, y: 3)
        .accessibilityHidden(true)
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppBrandPalette.brandBlue)
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
            .fill(AppBrandPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSeven ? AppBrandPalette.gold : AppBrandPalette.brandBlue.opacity(0.72),
                        lineWidth: isSeven ? max(2, size.width * 0.055) : max(1.2, size.width * 0.035)
                    )
            )
            .overlay {
                Text("\(number)")
                    .font(.custom("Nunito-Black", fixedSize: size.height * (isSeven ? 0.48 : 0.40)))
                    .foregroundStyle(numberColor)
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

private struct FlippingCardFace<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        Group {
            if angle < 90 {
                back
            } else {
                front
                    .scaleEffect(x: -1)
            }
        }
        .compositingGroup()
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.58
        )
    }
}

#Preview {
    AppTitleView()
        .padding()
}
