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
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .system
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
        .tint(selectedTheme.accentColor)
    }
}

#Preview {
    ContentView()
}
