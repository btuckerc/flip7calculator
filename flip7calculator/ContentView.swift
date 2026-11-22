//
//  ContentView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct ContentView: View {
    var animateSetupTitle = true

    @State private var viewModel = GameViewModel()
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("visualThemeVersion") private var visualThemeVersion: String = VisualTheme.v2.rawValue
    @AppStorage("didMigrateFlippingSevenThemeV2") private var didMigrateFlippingSevenThemeV2: Bool = false
    @Environment(\.colorScheme) private var systemColorScheme

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var visualTheme: VisualTheme {
        VisualTheme(rawValue: visualThemeVersion) ?? .v2
    }

    private var effectiveColorScheme: ColorScheme {
        selectedTheme.colorScheme ?? systemColorScheme
    }

    private var accentOverride: Color? {
        selectedTheme.hasCustomAccent ? selectedTheme.accentColor : nil
    }

    private var rootTint: Color {
        DesignColor.color(.brandPrimary, theme: visualTheme, colorScheme: effectiveColorScheme, accentOverride: accentOverride)
    }

    var body: some View {
        ActiveGameRoot(viewModel: $viewModel, animateSetupTitle: animateSetupTitle)
            .preferredColorScheme(selectedTheme.colorScheme)
            .tint(rootTint)
            .environment(\.visualTheme, visualTheme)
            .environment(\.appAccentOverride, accentOverride)
            .onAppear {
                let resolved = VisualThemeMigration.migrateIfNeeded()
                if visualThemeVersion != resolved.rawValue {
                    visualThemeVersion = resolved.rawValue
                }
                didMigrateFlippingSevenThemeV2 = true
            }
    }
}

struct ActiveGameRoot: View {
    @Binding var viewModel: GameViewModel
    var animateSetupTitle = true

    var body: some View {
        Group {
            if viewModel.game == nil {
                GameSetupView(viewModel: $viewModel, animateTitle: animateSetupTitle)
            } else if viewModel.game?.playStyle == .digitalDealer {
                DealerGameView(viewModel: viewModel)
            } else {
                GameView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
