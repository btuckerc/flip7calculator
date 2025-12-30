//
//  FontRegistrar.swift
//  flip7calculator
//
//  Created by Tucker Craig on 12/30/25.
//

import CoreText
import Foundation
import UIKit

enum FontRegistrar {
    private static var didRegister = false

    /// Manually register bundled fonts (fallback if Info.plist UIAppFonts doesn't work)
    static func registerAppFontsIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        // Try to register fonts from bundle root
        let fontNames = ["Nunito-Black", "Nunito-Bold"]
        for fontName in fontNames {
            if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                var errorRef: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
                #if DEBUG
                if !success {
                    print("FontRegistrar: Failed to register \(fontName)")
                }
                #endif
            } else {
                #if DEBUG
                print("FontRegistrar: \(fontName).ttf not found in bundle")
                #endif
            }
        }
        
        #if DEBUG
        // Log available Nunito fonts after registration
        let availableFonts = UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) }
            .filter { $0.lowercased().contains("nunito") }
        print("FontRegistrar: Available Nunito fonts: \(availableFonts)")
        #endif
    }
}


