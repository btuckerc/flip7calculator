//
//  flip7calculatorUITests.swift
//  flip7calculatorUITests
//
//  Created by Tucker Craig on 12/16/25.
//

import XCTest

final class flip7calculatorUITests: XCTestCase {

    private let layoutAuditPlayerNames = [
        "Peter", "Ned", "Mary", "Gwen", "Miles", "May", "Ben", "Felicia"
    ]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testVengeanceLayoutForFourThroughEightPlayers() throws {
        for playerCount in 4...8 {
            let app = XCUIApplication()
            app.launchArguments = [
                "-appStoreCapture", "layout-audit",
                "-capturePlayerCount", "\(playerCount)"
            ]
            app.launch()

            let expectedNames = Array(layoutAuditPlayerNames.prefix(playerCount))
            XCTAssertTrue(app.buttons[expectedNames[0]].waitForExistence(timeout: 2))
            for name in expectedNames.dropFirst() {
                XCTAssertTrue(app.buttons[name].exists, "Missing \(name) at \(playerCount) players")
            }

            let lastPlayer = app.buttons[expectedNames.last!]
            if !lastPlayer.isHittable {
                let playerGridScrollView = app.scrollViews.firstMatch
                XCTAssertTrue(playerGridScrollView.exists, "The compact player grid should scroll at \(playerCount) players")
                playerGridScrollView.swipeUp()
            }
            XCTAssertTrue(lastPlayer.isHittable, "The last player should be reachable at \(playerCount) players")
            lastPlayer.tap()

            XCTAssertTrue(app.staticTexts["VENGEANCE"].waitForExistence(timeout: 1))
            XCTAssertTrue(app.buttons["Stay"].isHittable)
            XCTAssertTrue(app.buttons["Bust"].isHittable)
            XCTAssertTrue(app.buttons["Forced Stay"].exists)
            XCTAssertTrue(app.buttons["Lucky 13"].isHittable)
            XCTAssertTrue(app.buttons["Continue"].isHittable)

            let windowFrame = app.windows.firstMatch.frame
            for element in [
                app.buttons[expectedNames.last!],
                app.buttons["Stay"],
                app.buttons["Forced Stay"],
                app.buttons["Lucky 13"],
                app.buttons["Continue"]
            ] {
                XCTAssertTrue(
                    windowFrame.insetBy(dx: -1, dy: -1).contains(element.frame),
                    "\(element) is clipped at \(playerCount) players"
                )
            }

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Vengeance - \(playerCount) Players"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.terminate()
        }
    }

    @MainActor
    func testGameModeCopyAndEqualWidthLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "setup"]
        app.launch()

        let classic = app.buttons["Classic"]
        let vengeance = app.buttons["Vengeance"]
        let setupScrollView = app.scrollViews.firstMatch

        XCTAssertTrue(classic.waitForExistence(timeout: 2))
        for _ in 0..<3 where !classic.isHittable {
            XCTAssertTrue(setupScrollView.exists)
            setupScrollView.swipeUp()
        }
        XCTAssertTrue(classic.isHittable)

        XCTAssertTrue(
            app.staticTexts[
                "Start here. Flip unique numbers and try to reach seven cards before a duplicate makes you bust."
            ].exists
        )
        XCTAssertEqual(classic.frame.width, vengeance.frame.width, accuracy: 1)
        XCTAssertEqual(
            classic.frame.minX,
            app.windows.firstMatch.frame.width - vengeance.frame.maxX,
            accuracy: 1
        )

        vengeance.tap()
        setupScrollView.swipeUp()
        XCTAssertTrue(
            app.staticTexts[
                "NOTE: Requires additional cards. Please be sure to use the 'With a Vengeance' expansion pack for this mode."
            ].waitForExistence(timeout: 1)
        )
        XCTAssertTrue(
            app.staticTexts[
                "More twists: special numbers, take-that actions, and negative modifiers."
            ].waitForExistence(timeout: 1)
        )
        let brutalMode = app.switches["Brutal Mode"]
        XCTAssertTrue(brutalMode.exists)
        for _ in 0..<2 where !brutalMode.isHittable {
            setupScrollView.swipeUp()
        }
        XCTAssertTrue(brutalMode.isHittable)
        XCTAssertEqual(brutalMode.value as? String, "0")
        XCTAssertTrue(
            app.staticTexts[
                "Optional cutthroat variant: negative rounds and redirected 7-card bonuses."
            ].exists
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Game Mode Selector"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testRunningGameCanSwitchModesWithoutLeavingTheGame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "live"]
        app.launch()

        XCTAssertTrue(app.buttons["Peter"].waitForExistence(timeout: 2), "The live-game fixture did not load")
        app.buttons["Settings"].tap()
        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 2),
            "The Settings sheet did not open"
        )

        let vengeance = app.buttons["Vengeance"]
        for _ in 0..<4 where !vengeance.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(vengeance.isHittable, "The Vengeance mode chip was not reachable in Settings")
        vengeance.tap()
        app.buttons["Done"].tap()

        app.buttons["Peter"].tap()
        XCTAssertTrue(
            app.staticTexts["VENGEANCE"].waitForExistence(timeout: 1),
            "The live calculator did not update to Vengeance"
        )
        XCTAssertTrue(app.buttons["Peter"].exists, "The running game was replaced instead of preserved")
    }
}
