//
//  OpeningSplashView.swift
//  flip7calculator
//
//  Crisp, skippable opening presentation for Flipping Seven Calculator.
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
    @State private var exitOpacity = 1.0
    @State private var isDismissing = false

    private var shouldReduceMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        ZStack {
            AppBrandPalette.screenBackground(colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                SevenCardFanView(
                    dealtCards: dealtCards,
                    faceUpCards: faceUpCards,
                    cardSize: CGSize(width: 54, height: 80),
                    horizontalSpread: 30,
                    arcHeight: 12
                )
                .frame(height: 108)

                BrandWordmarkView(showDescriptor: true)
                    .opacity(showWordmark || shouldReduceMotion ? 1 : 0)
                    .offset(y: showWordmark || shouldReduceMotion ? 0 : 6)
            }
            .padding(.horizontal, 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppBrand.appName)
        }
        .opacity(exitOpacity)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissImmediately()
        }
        .task {
            await runSequence()
        }
    }

    @MainActor
    private func runSequence() async {
        if shouldReduceMotion {
            dealtCards = Array(repeating: true, count: 7)
            faceUpCards = Array(repeating: true, count: 7)
            showWordmark = true
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            closeSplash(duration: 0.14)
            return
        }

        // Fast, cohesive fan reveal (~0.70s total, skippable on tap).
        dealtCards = Array(repeating: true, count: 7)
        withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
            showWordmark = true
        }

        for index in faceUpCards.indices {
            guard !Task.isCancelled, !isDismissing else { return }
            withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                faceUpCards[index] = true
            }
            try? await Task.sleep(for: .milliseconds(36))
        }

        try? await Task.sleep(for: .milliseconds(220))
        guard !Task.isCancelled, !isDismissing else { return }
        closeSplash(duration: 0.18)
    }

    @MainActor
    private func dismissImmediately() {
        guard !isDismissing else { return }
        isDismissing = true
        isPresented = false
    }

    @MainActor
    private func closeSplash(duration: Double) {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeOut(duration: duration)) {
            exitOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(duration * 1000) + 20))
            isPresented = false
        }
    }
}

#Preview {
    OpeningSplashView(isPresented: .constant(true))
}
