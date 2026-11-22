//
//  FontRegistrar.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/30/25.
//

import CoreText
import Foundation

enum FontRegistrar {
    private static var didRegister = false

    /// Registers the bundled display font used by the brand wordmark and card numerals.
    static func registerAppFontsIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        guard let url = Bundle.main.url(forResource: "Nunito-Black", withExtension: "ttf") else {
            return
        }
        var errorRef: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
    }
}
