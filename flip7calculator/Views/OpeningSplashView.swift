//
//  OpeningSplashView.swift
//  flip7calculator
//
//  Flipping Seven Calculator launch animation.
//

import SwiftUI

struct OpeningSplashView: View {
    @Binding var isPresented: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    @State private var dealtCards = Array(repeating: false, count: 7)
    @State private var faceUpCards = Array(repeating: false, count: 7)
    @State private var showWordmark = false
    @State private var showDescriptor = false
    @State private var exitOpacity = 1.0
    @State private var exitScale: CGFloat = 1.0

    private var shouldReduceMotion: Bool {
        accessibilityReduceMotion || reduceAnimations
    }

    var body: some View {
        ZStack {
            AppBrandPalette.screenGradient(colorScheme: colorScheme)
                .overlay {
                    RadialGradient(
                        colors: [
                            AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.20 : 0.16),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 20,
                        endRadius: 280
                    )
                }
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(AppBrandPalette.brandBlueSky.opacity(colorScheme == .dark ? 0.15 : 0.11))
                        .frame(width: 260, height: 260)
                        .blur(radius: 70)
                        .offset(x: -110, y: -90)
                }
                .ignoresSafeArea()

            VStack(spacing: 28) {
                SevenCardFanView(
                    dealtCards: dealtCards,
                    faceUpCards: faceUpCards,
                    cardSize: CGSize(width: 58, height: 86),
                    horizontalSpread: 33,
                    arcHeight: 15
                )
                .frame(height: 118)

                VStack(spacing: 8) {
                    BrandWordmarkView(showDescriptor: showDescriptor || shouldReduceMotion)
                        .opacity(showWordmark || shouldReduceMotion ? 1 : 0)
                        .offset(y: showWordmark || shouldReduceMotion ? 0 : 10)

                    Text(AppBrand.tagline)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? AppBrandPalette.mist
                                : AppBrandPalette.ink.opacity(0.72)
                        )
                        .multilineTextAlignment(.center)
                        .opacity(showDescriptor || shouldReduceMotion ? 1 : 0)
                }
            }
            .padding(.horizontal, 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppBrand.appName)
            .accessibilityValue(AppBrand.tagline)
        }
        .opacity(exitOpacity)
        .scaleEffect(exitScale)
        .task {
            await startAnimation()
        }
    }

    @MainActor
    private func startAnimation() async {
        if shouldReduceMotion {
            dealtCards = Array(repeating: true, count: 7)
            faceUpCards = Array(repeating: true, count: 7)
            showWordmark = true
            showDescriptor = true
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            isPresented = false
            return
        }

        for index in dealtCards.indices {
            guard !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.28, extraBounce: 0.04)) {
                dealtCards[index] = true
            }
            try? await Task.sleep(for: .milliseconds(90))
        }

        try? await Task.sleep(for: .milliseconds(180))

        for index in faceUpCards.indices {
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.34)) {
                faceUpCards[index] = true
            }
            try? await Task.sleep(for: .milliseconds(115))
        }

        withAnimation(.easeOut(duration: 0.30)) {
            showWordmark = true
        }

        try? await Task.sleep(for: .milliseconds(180))

        withAnimation(.easeOut(duration: 0.24)) {
            showDescriptor = true
        }

        try? await Task.sleep(for: .milliseconds(720))
        guard !Task.isCancelled else { return }
        closeSplash()
    }

    private func closeSplash() {
        withAnimation(.easeInOut(duration: 0.30)) {
            exitOpacity = 0
            exitScale = 1.025
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            isPresented = false
        }
    }
}

#Preview {
    OpeningSplashView(isPresented: .constant(true))
}
