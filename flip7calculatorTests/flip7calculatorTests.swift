//
//  flip7calculatorTests.swift
//  flip7calculatorTests
//
//  Created by Tucker Craig on 12/16/25.
//

import Testing
@testable import flip7calculator

struct flip7calculatorTests {

    @Test func publicBrandMatchesReleaseMetadata() {
        #expect(AppBrand.appName == "Flipping Seven Calculator")
        #expect(AppBrand.appName.count <= 30)
        #expect(AppBrand.wordmarkLead == "FLIPPING")
        #expect(AppBrand.wordmarkSeven == "SEVEN")
        #expect(AppBrand.wordmarkDescriptor == "CALCULATOR")
    }

    @Test func publicBrandDoesNotUseExactDisputedMark() {
        let publicCopy = [
            AppBrand.appName,
            AppBrand.tagline,
            AppBrand.shortDescription,
            AppBrand.independenceNotice
        ]
        .joined(separator: " ")
        .lowercased()

        #expect(!publicCopy.contains("flip 7"))
        #expect(!publicCopy.contains("flip7"))
    }

}
