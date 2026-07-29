//
//  OpeningSplashView.swift
//  flip7calculator
//
//  Lucky Ledger launch animation.
//

import SwiftUI

struct OpeningSplashView: View {
    @Binding var isPresented: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    @State private var showLedger = false
    @State private var showDie = false
    @State private var showTitle = false
    @State private var exitOpacity = 1.0
    @State private var exitScale: CGFloat = 1.0

    private var shouldReduceMotion: Bool {
        reduceMotion || reduceAnimations
    }

    var body: some View {
        ZStack {
            AppBrandPalette.screenGradient(colorScheme: colorScheme)
                .overlay {
                    RadialGradient(
                        colors: [
                            AppBrandPalette.gold.opacity(colorScheme == .dark ? 0.18 : 0.12),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 24,
                        endRadius: 240
                    )
                }
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    splashCardCue
                        .rotationEffect(.degrees(-12))
                        .offset(x: showLedger ? -26 : -110, y: showLedger ? -4 : 90)

                    splashLedger
                        .rotationEffect(.degrees(showLedger ? 2 : 7))
                        .offset(y: showLedger ? 0 : 120)

                    if showDie || shouldReduceMotion {
                        DiceBadgeView()
                            .scaleEffect(showDie ? 1.14 : 0.72)
                            .opacity(showDie ? 1 : 0)
                            .offset(x: 46, y: 30)
                    }
                }
                .frame(height: 152)

                if showTitle || shouldReduceMotion {
                    VStack(spacing: 6) {
                        Text(AppBrand.appName)
                            .font(.custom("Nunito-Black", size: 34))
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? AppBrandPalette.parchment
                                    : AppBrandPalette.ink
                            )
                        Text(AppBrand.tagline)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .offset(y: 8)))
                }
            }
            .padding(.horizontal, 24)
        }
        .opacity(exitOpacity)
        .scaleEffect(exitScale)
        .onAppear {
            startAnimation()
        }
    }

    private var splashCardCue: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppBrandPalette.emeraldDeep)
            .frame(width: 110, height: 132)
            .overlay(alignment: .topTrailing) {
                Triangle()
                    .fill(AppBrandPalette.card)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(180))
                    .offset(x: -12, y: 12)
            }
            .overlay(alignment: .bottomLeading) {
                Text("7")
                    .font(.custom("Nunito-Black", size: 42))
                    .foregroundStyle(AppBrandPalette.gold)
                    .offset(x: 18, y: -14)
            }
            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
    }

    private var splashLedger: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    colors: [AppBrandPalette.card, Color.white.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 128, height: 148)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppBrandPalette.ink.opacity(0.16), lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppBrandPalette.emerald)
                    .frame(width: 52, height: 28)
                    .overlay(
                        Text("LL")
                            .font(.custom("Nunito-Black", size: 18))
                            .tracking(0.7)
                            .foregroundStyle(AppBrandPalette.card)
                    )
                    .offset(x: 16, y: 16)
            }
            .overlay {
                VStack(alignment: .leading, spacing: 12) {
                    splashLedgerRow(dot: AppBrandPalette.emerald, width: 50)
                    splashLedgerRow(dot: AppBrandPalette.gold, width: 42)
                    splashLedgerRow(dot: AppBrandPalette.copper, width: 58)
                }
                .padding(.top, 20)
                .padding(.horizontal, 18)
            }
            .overlay(alignment: .trailing) {
                PencilAccentView()
                    .scaleEffect(1.34)
                    .rotationEffect(.degrees(18))
                    .offset(x: 9, y: -12)
            }
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private func splashLedgerRow(dot: Color, width: CGFloat) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(dot)
                .frame(width: 12, height: 12)

            RoundedRectangle(cornerRadius: 6)
                .fill(AppBrandPalette.mist)
                .frame(width: width, height: 12)

            RoundedRectangle(cornerRadius: 6)
                .fill(dot.opacity(0.95))
                .frame(width: 22, height: 12)
        }
    }

    private func startAnimation() {
        if shouldReduceMotion {
            showLedger = true
            showDie = true
            showTitle = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                closeSplash()
            }
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            showLedger = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                showDie = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            withAnimation(.easeOut(duration: 0.25)) {
                showTitle = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            closeSplash()
        }
    }

    private func closeSplash() {
        withAnimation(.easeInOut(duration: 0.28)) {
            exitOpacity = 0
            exitScale = 1.03
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    OpeningSplashView(isPresented: .constant(true))
}
