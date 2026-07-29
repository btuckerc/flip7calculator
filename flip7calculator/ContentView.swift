//
//  ContentView.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("visualThemeVersion") private var visualThemeVersion: String = VisualTheme.v2.rawValue
    @AppStorage("didMigrateLuckyLedgerThemeV2") private var didMigrateLuckyLedgerThemeV2: Bool = false
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
    }

    private var visualTheme: VisualTheme {
        VisualTheme(rawValue: visualThemeVersion) ?? .v2
    }

    private var rootTint: Color {
        switch visualTheme {
        case .legacy:
            return selectedTheme.accentColor
        case .v2:
            return DesignColor.color(.brandPrimary, theme: .v2, colorScheme: selectedTheme.colorScheme)
        }
    }
    
    var body: some View {
        Group {
            if viewModel.game == nil {
                GameSetupView(viewModel: $viewModel)
            } else {
                GameView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
        .tint(rootTint)
        .environment(\.visualTheme, visualTheme)
        .onAppear {
            if !didMigrateLuckyLedgerThemeV2 {
                visualThemeVersion = VisualTheme.v2.rawValue
                didMigrateLuckyLedgerThemeV2 = true
            }
        }
    }
}

#Preview {
    ContentView()
}
