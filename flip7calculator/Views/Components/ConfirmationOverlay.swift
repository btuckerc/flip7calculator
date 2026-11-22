//
//  ConfirmationOverlay.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct ConfirmationOverlay: View {
    let title: String
    let message: String
    let primaryActionTitle: String
    let primaryActionRole: ButtonRole?
    let secondaryActionTitle: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    let onDismiss: () -> Void

    @Environment(\.visualTheme) private var visualTheme
    @Environment(\.appAccentOverride) private var appAccentOverride
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations: Bool = false

    @State private var isPresented = false

    init(
        title: String,
        message: String,
        primaryActionTitle: String,
        primaryActionRole: ButtonRole? = nil,
        secondaryActionTitle: String = "Cancel",
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.primaryActionTitle = primaryActionTitle
        self.primaryActionRole = primaryActionRole
        self.secondaryActionTitle = secondaryActionTitle
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onDismiss = onDismiss
    }

    private var accentColor: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: colorScheme, accentOverride: appAccentOverride)
    }

    private var dangerColor: Color {
        DesignColor.color(.stateDanger, theme: visualTheme, colorScheme: colorScheme)
    }

    private var isReducedMotion: Bool {
        DesignMotion.shouldReduceMotion(
            reduceAnimations: reduceAnimations,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.52 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(DesignColor.color(.textPrimary, theme: visualTheme, colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                ViewThatFits(in: .vertical) {
                    messageContent
                    ScrollView {
                        messageContent
                    }
                    .frame(maxHeight: 240)
                }

                Divider()
                    .overlay(visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator))

                HStack(spacing: 0) {
                    Button(action: {
                        onSecondary()
                        onDismiss()
                    }) {
                        Text(secondaryActionTitle)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }

                    Divider()
                        .overlay(visualTheme == .v2 ? AppBrandPalette.cardBorder(colorScheme: colorScheme) : Color(.separator))
                        .frame(height: 52)

                    Button(action: {
                        onPrimary()
                        onDismiss()
                    }) {
                        Text(primaryActionTitle)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(primaryActionRole == .destructive ? dangerColor : accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }
                }
            }
            .cardSurface(cornerRadius: 20)
            .frame(maxWidth: 332)
            .padding(.horizontal, 32)
            .scaleEffect(isPresented || isReducedMotion ? 1.0 : 0.96)
            .offset(y: isPresented || isReducedMotion ? 0 : 8)
            .opacity(isPresented ? 1.0 : 0.0)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            withAnimation(DesignMotion.animation(.normal, reduced: isReducedMotion)) {
                isPresented = true
            }
        }
    }

    private var messageContent: some View {
        Text(message)
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(DesignColor.color(.textSecondary, theme: visualTheme, colorScheme: colorScheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
    }
}
