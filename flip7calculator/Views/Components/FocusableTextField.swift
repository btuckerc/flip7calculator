//
//  FocusableTextField.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/17/25.
//

import SwiftUI
import UIKit
import Combine

/// A TextField wrapper that prevents keyboard dismissal when moving between fields.
/// Uses UIKit's responder chain for smooth focus transitions.
struct FocusableTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let returnKeyType: UIReturnKeyType
    let onReturn: () -> Void
    
    // Coordinator to store focus callback
    var focusCoordinator: FocusCoordinator?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.delegate = context.coordinator
        textField.returnKeyType = returnKeyType
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.borderStyle = .none
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Register with coordinator for focus management
        if let coordinator = focusCoordinator {
            coordinator.register(textField: textField)
        }
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.returnKeyType = returnKeyType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onReturn: onReturn)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onReturn: () -> Void
        
        init(text: Binding<String>, onReturn: @escaping () -> Void) {
            _text = text
            self.onReturn = onReturn
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Call the onReturn callback - this will handle focus transition
            onReturn()
            // Return false to prevent default behavior (keyboard dismissal)
            // The onReturn callback will handle moving focus
            return false
        }
    }
}

/// Manages focus across multiple FocusableTextFields
class FocusCoordinator: ObservableObject {
    private var textFields: [UUID: UITextField] = [:]
    private var order: [UUID] = []
    @Published var focusedId: UUID?
    
    func register(id: UUID, textField: UITextField) {
        textFields[id] = textField
        if !order.contains(id) {
            order.append(id)
        }
    }
    
    func register(textField: UITextField) {
        // This is called during UIView creation, actual registration happens via setOrder
    }
    
    func setOrder(_ ids: [UUID]) {
        order = ids
    }
    
    func focus(_ id: UUID?) {
        // Resign current first responder if different
        if let currentId = focusedId, currentId != id, let currentField = textFields[currentId] {
            currentField.resignFirstResponder()
        }
        
        focusedId = id
        
        if let id = id, let textField = textFields[id] {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
    }
    
    func focusNext(after id: UUID) {
        guard let currentIndex = order.firstIndex(of: id) else {
            focus(nil)
            return
        }
        
        if currentIndex < order.count - 1 {
            let nextId = order[currentIndex + 1]
            if let nextField = textFields[nextId] {
                // Directly transfer focus without dismissing keyboard
                nextField.becomeFirstResponder()
                focusedId = nextId
            }
        } else {
            // Last field - dismiss keyboard
            if let currentField = textFields[id] {
                currentField.resignFirstResponder()
            }
            focusedId = nil
        }
    }
    
    func clearFocus() {
        if let currentId = focusedId, let currentField = textFields[currentId] {
            currentField.resignFirstResponder()
        }
        focusedId = nil
    }
}

/// A view that manages a FocusableTextField with coordinator-based focus
struct ManagedTextField: View {
    let id: UUID
    let placeholder: String
    @Binding var text: String
    let isLast: Bool
    @ObservedObject var coordinator: FocusCoordinator
    
    var body: some View {
        FocusableTextFieldRepresentable(
            id: id,
            placeholder: placeholder,
            text: $text,
            isLast: isLast,
            coordinator: coordinator
        )
    }
}

struct FocusableTextFieldRepresentable: UIViewRepresentable {
    let id: UUID
    let placeholder: String
    @Binding var text: String
    let isLast: Bool
    @ObservedObject var coordinator: FocusCoordinator
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.rounded(ofSize: 17, weight: .regular)
        textField.delegate = context.coordinator
        textField.returnKeyType = isLast ? .done : .next
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.borderStyle = .none
        // Allow text field to shrink and not push container width
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        // Register with coordinator
        coordinator.register(id: id, textField: textField)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.returnKeyType = isLast ? .done : .next
        uiView.placeholder = placeholder
        
        // Update registration in case view was recycled
        coordinator.register(id: id, textField: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(id: id, text: $text, focusCoordinator: coordinator)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let id: UUID
        @Binding var text: String
        let focusCoordinator: FocusCoordinator
        
        init(id: UUID, text: Binding<String>, focusCoordinator: FocusCoordinator) {
            self.id = id
            _text = text
            self.focusCoordinator = focusCoordinator
        }
        
        static let maxNameLength = 20
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            var newText = textField.text ?? ""
            // Enforce character limit
            if newText.count > Self.maxNameLength {
                newText = String(newText.prefix(Self.maxNameLength))
                textField.text = newText
            }
            text = newText
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            focusCoordinator.focusedId = id
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            focusCoordinator.focusNext(after: id)
            return false
        }
    }
}

// Extension to create rounded system font
extension UIFont {
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}

