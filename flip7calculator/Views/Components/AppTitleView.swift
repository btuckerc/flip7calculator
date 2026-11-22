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
                showsFaceUpWhenStatic: true
            )
            .frame(height: 98)

            BrandWordmarkView(showDescriptor: true)

            if showTagline {
                Text(AppBrand.tagline)
                    .font(DesignTypography.font(.caption))
                    .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
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
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: compact ? 1 : 3) {
            HStack(alignment: .firstTextBaseline, spacing: compact ? 5 : 7) {
                Text(AppBrand.wordmarkLead)
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))

                Text(AppBrand.wordmarkSeven)
                    .foregroundStyle(DesignColor.color(.brandSecondary, theme: visualTheme, colorScheme: colorScheme))
            }
            .font(.custom("Nunito-Black", size: compact ? 23 : 28, relativeTo: .title2))
            .tracking(compact ? 0.5 : 0.9)
            .minimumScaleFactor(0.76)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)

            if showDescriptor {
                Text(AppBrand.wordmarkDescriptor)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(compact ? 2.0 : 3.0)
                    .foregroundStyle(DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppBrand.appName)
    }
}

/// Seven-card fan mark that plays a single calm reveal on appearance and rests face-up
/// with zero background CPU/GPU drain. Users can tap the fan for an optional ripple.
struct BrandMarkView: View {
    let animated: Bool
    var showsFaceUpWhenStatic: Bool = true

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.colorScheme) private var colorScheme
    private let dealtCards = Array(repeating: true, count: 7)
    @State private var faceUpCards: [Bool]
    @State private var rippleTrigger = 0

    init(animated: Bool, showsFaceUpWhenStatic: Bool = true) {
        self.animated = animated
        self.showsFaceUpWhenStatic = showsFaceUpWhenStatic
        _faceUpCards = State(
            initialValue: Array(repeating: animated ? false : showsFaceUpWhenStatic, count: 7)
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignColor.color(.surfaceInteractive, theme: visualTheme, colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(DesignColor.border(theme: visualTheme, colorScheme: colorScheme), lineWidth: 1)
                )

            SevenCardFanView(
                dealtCards: dealtCards,
                faceUpCards: faceUpCards,
                cardSize: CGSize(width: 50, height: 72),
                horizontalSpread: 26,
                arcHeight: 8
            )
            .offset(y: -4)
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 12)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            guard animated else { return }
            HapticFeedback.selection()
            rippleTrigger &+= 1
        }
        .task(id: "\(animated)-\(showsFaceUpWhenStatic)-\(rippleTrigger)") {
            guard animated else {
                faceUpCards = Array(repeating: showsFaceUpWhenStatic, count: 7)
                return
            }

            if rippleTrigger > 0 {
                // Interactive tap ripple: quick flip face-down then back face-up once.
                for index in faceUpCards.indices {
                    guard !Task.isCancelled else { return }
                    withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                        faceUpCards[index] = false
                    }
                    try? await Task.sleep(for: .milliseconds(35))
                }
                try? await Task.sleep(for: .milliseconds(120))
            } else {
                faceUpCards = Array(repeating: false, count: 7)
                try? await Task.sleep(for: .milliseconds(120))
            }

            for index in faceUpCards.indices {
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.28)) {
                    faceUpCards[index] = true
                }
                try? await Task.sleep(for: .milliseconds(55))
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
                let normalizedDistance = distanceFromCenter / 3

                BrandPlayingCard(
                    number: index + 1,
                    isFaceUp: value(in: faceUpCards, at: index, fallback: true),
                    size: cardSize
                )
                .rotationEffect(.degrees(Double(distanceFromCenter) * 3.0 - 1.0))
                .offset(
                    x: distanceFromCenter * horizontalSpread,
                    y: normalizedDistance * normalizedDistance * arcHeight
                )
                .opacity(value(in: dealtCards, at: index, fallback: true) ? 1 : 0)
                .offset(y: value(in: dealtCards, at: index, fallback: true) ? 0 : -cardSize.height * 1.4)
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
        .shadow(color: AppBrandPalette.ink.opacity(0.14), radius: 3, y: 2)
        .accessibilityHidden(true)
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppBrandPalette.brandBlue)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                    .stroke(AppBrandPalette.card.opacity(0.84), lineWidth: max(1.4, size.width * 0.04))
                    .padding(max(3, size.width * 0.09))
            )
            .overlay {
                VStack(spacing: max(2, size.height * 0.045)) {
                    Capsule().fill(AppBrandPalette.gold).frame(width: size.width * 0.28, height: 2.5)
                    Capsule().fill(AppBrandPalette.card.opacity(0.9)).frame(width: size.width * 0.42, height: 2.5)
                    Capsule().fill(AppBrandPalette.copper).frame(width: size.width * 0.22, height: 2.5)
                }
            }
    }

    private var cardFront: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppBrandPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSeven ? AppBrandPalette.gold : AppBrandPalette.brandBlue.opacity(0.55),
                        lineWidth: isSeven ? max(2, size.width * 0.05) : max(1.2, size.width * 0.032)
                    )
            )
            .overlay {
                Text("\(number)")
                    .font(.custom("Nunito-Black", fixedSize: size.height * (isSeven ? 0.48 : 0.40)))
                    .foregroundStyle(numberColor)
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(isSeven ? AppBrandPalette.copper : AppBrandPalette.brandBlueSky)
                    .frame(width: max(4, size.width * 0.11), height: max(4, size.width * 0.11))
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
