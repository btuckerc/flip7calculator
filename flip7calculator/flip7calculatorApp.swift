//
//  flip7calculatorApp.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

@main
struct flip7calculatorApp: App {
    init() {
        FontRegistrar.registerAppFontsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root View (with splash overlay)

struct RootView: View {
    @AppStorage("showOpeningAnimation") private var showOpeningAnimation: Bool = true
    @State private var showSplash: Bool = true
    
    var body: some View {
        ZStack {
            // Main app content (renders immediately for fast startup)
            ContentView()
            
            // Splash overlay
            if showSplash && showOpeningAnimation {
                OpeningSplashView(isPresented: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // If animation is disabled, skip splash immediately
            if !showOpeningAnimation {
                showSplash = false
            }
        }
    }
}
