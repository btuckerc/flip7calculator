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
    
    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Centered card
            VStack(spacing: 0) {
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                
                // Message
                Text(message)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                Divider()
                
                // Buttons
                HStack(spacing: 0) {
                    // Secondary button (Cancel)
                    Button(action: {
                        onSecondary()
                        onDismiss()
                    }) {
                        Text(secondaryActionTitle)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    
                    if primaryActionRole == .destructive {
                        Divider()
                            .frame(height: 56)
                    }
                    
                    // Primary button
                    Button(action: {
                        onPrimary()
                        onDismiss()
                    }) {
                        Text(primaryActionTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryActionRole == .destructive ? .red : .blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
                    )
            )
            .frame(maxWidth: 320)
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1.0 : 0.9)
            .opacity(isPresented ? 1.0 : 0.0)
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPresented = true
            }
        }
    }
}

