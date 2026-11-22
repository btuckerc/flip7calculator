//
//  HapticFeedback.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/16/25.
//

import UIKit

/// Low-latency haptic feedback using cached, pre-warmable UIKit generators.
enum HapticFeedback {
    @MainActor
    private final class Engine {
        static let shared = Engine()

        private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        private let selectionGenerator = UISelectionFeedbackGenerator()
        private let notificationGenerator = UINotificationFeedbackGenerator()

        private init() {}

        private var isEnabled: Bool {
            UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true
        }

        func prepareLight() {
            guard isEnabled else { return }
            lightGenerator.prepare()
        }

        func prepareSelection() {
            guard isEnabled else { return }
            selectionGenerator.prepare()
        }

        func light() {
            guard isEnabled else { return }
            lightGenerator.impactOccurred()
        }

        func medium() {
            guard isEnabled else { return }
            mediumGenerator.impactOccurred()
        }

        func heavy() {
            guard isEnabled else { return }
            heavyGenerator.impactOccurred()
        }

        func selection() {
            guard isEnabled else { return }
            selectionGenerator.selectionChanged()
        }

        func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            guard isEnabled else { return }
            notificationGenerator.notificationOccurred(type)
        }
    }

    @MainActor
    static func prepareLight() {
        Engine.shared.prepareLight()
    }

    @MainActor
    static func prepareSelection() {
        Engine.shared.prepareSelection()
    }

    @MainActor
    static func light() {
        Engine.shared.light()
    }

    @MainActor
    static func medium() {
        Engine.shared.medium()
    }

    @MainActor
    static func heavy() {
        Engine.shared.heavy()
    }

    @MainActor
    static func selection() {
        Engine.shared.selection()
    }

    @MainActor
    static func success() {
        Engine.shared.notification(.success)
    }

    @MainActor
    static func error() {
        Engine.shared.notification(.error)
    }

    @MainActor
    static func warning() {
        Engine.shared.notification(.warning)
    }
}
