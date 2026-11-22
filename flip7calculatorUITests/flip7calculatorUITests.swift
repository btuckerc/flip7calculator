//
//  flip7calculatorUITests.swift
//  flip7calculatorUITests
//
//  Created by Tucker Craig on 12/16/25.
//

import XCTest

final class flip7calculatorUITests: XCTestCase {

    private let layoutAuditPlayerNames = [
        "Miles", "Ned", "MJ", "Peter", "Gwen", "May", "Happy", "Felicia"
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
        let startButton = app.buttons["setup.startGame"]

        XCTAssertTrue(setupScrollView.waitForExistence(timeout: 2))
        for _ in 0..<4 where vengeance.frame.maxY >= startButton.frame.minY {
            setupScrollView.swipeUp()
        }
        XCTAssertTrue(classic.exists)
        XCTAssertTrue(classic.isHittable)
        XCTAssertLessThan(vengeance.frame.maxY, startButton.frame.minY)

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

        XCTAssertTrue(vengeance.isHittable)
        classic.tap() // Settles any final scroll deceleration without changing the mode.
        vengeance.tap()
        let expansionNote = app.staticTexts[
            "NOTE: Requires additional cards. Please be sure to use the 'With a Vengeance' expansion pack for this mode."
        ]
        if !expansionNote.waitForExistence(timeout: 1) {
            setupScrollView.swipeUp()
        }
        XCTAssertTrue(expansionNote.waitForExistence(timeout: 1))
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
    func testSetupKeepsCalculatorFirstClassAndCanStartDealer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "setup"]
        app.launch()

        let calculator = app.buttons["setup.entry.scoreCalculator"]
        let dealer = app.buttons["setup.entry.playWithDealer"]
        let start = app.buttons["setup.startGame"]

        XCTAssertTrue(calculator.waitForExistence(timeout: 2))
        XCTAssertEqual(calculator.value as? String, "Selected")
        XCTAssertEqual(dealer.value as? String, "Not selected")
        XCTAssertEqual(calculator.frame.height, dealer.frame.height, accuracy: 1)
        XCTAssertFalse(app.staticTexts["Dealer Preview"].exists)
        XCTAssertFalse(app.staticTexts["Use your physical cards. Enter cards or round scores."].exists)
        XCTAssertFalse(app.staticTexts["Draw and play from the deck on this device."].exists)
        XCTAssertTrue(start.exists)
        XCTAssertEqual(start.label, "Start Scoring")

        dealer.tap()
        XCTAssertEqual(dealer.value as? String, "Selected")
        XCTAssertEqual(dealer.label, "Simulator")
        XCTAssertEqual(start.label, "Start Simulator")
        start.tap()

        XCTAssertTrue(app.buttons["dealer.primaryAction"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Round 1 · Simulator"].exists)
        XCTAssertTrue(app.otherElements["simulator.card.faceDown"].exists)

        app.buttons["dealer.primaryAction"].tap()
        XCTAssertEqual(app.buttons["dealer.primaryAction"].label, "Hide Card & Continue")
        XCTAssertTrue(app.otherElements["simulator.card.revealed"].waitForExistence(timeout: 1))

        app.buttons["dealer.primaryAction"].tap()
        XCTAssertEqual(app.buttons["dealer.primaryAction"].label, "Deal to Ned")
        XCTAssertTrue(app.otherElements["simulator.card.faceDown"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.otherElements["simulator.card.revealed"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Dealer - Opening Deal"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testCalculatorPathStillStartsWithoutAnExtraStep() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "setup"]
        app.launch()

        let start = app.buttons["setup.startGame"]
        XCTAssertTrue(start.waitForExistence(timeout: 2))
        XCTAssertEqual(start.label, "Start Scoring")
        start.tap()

        XCTAssertTrue(app.buttons["Miles"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["dealer.primaryAction"].exists)
    }

    @MainActor
    func testDealerFixtureFitsTheVisibleWindow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "dealer"]
        app.launch()

        let primaryAction = app.buttons["dealer.primaryAction"]
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 2))
        XCTAssertTrue(primaryAction.isHittable)
        XCTAssertTrue(app.staticTexts["Miles, draw or stay?"].exists)
        XCTAssertTrue(app.staticTexts["88"].exists, "The draw-pile count should remain visible")
        XCTAssertFalse(app.staticTexts["Discard"].exists)
        XCTAssertTrue(app.otherElements["simulator.card.faceDown"].exists)
        let risk = app.buttons["Next-card bust risk"]
        XCTAssertTrue(risk.exists)
        XCTAssertEqual(risk.value as? String, "10% next-card risk · Exact")
        XCTAssertTrue(
            app.windows.firstMatch.frame.insetBy(dx: -1, dy: -1).contains(primaryAction.frame),
            "The primary Dealer action is clipped"
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Dealer - Active Turn"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let milesHand = app.buttons["dealer.hand.00000000-0000-0000-0000-000000000001"]
        XCTAssertTrue(milesHand.isHittable)
        milesHand.tap()
        XCTAssertTrue(app.navigationBars["Table Hands"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Miles"].exists)
        XCTAssertTrue(app.staticTexts["Ned"].exists)
        XCTAssertTrue(app.staticTexts["MJ"].exists)
        XCTAssertTrue(app.staticTexts["Peter"].exists)

        let handsScreenshot = XCTAttachment(screenshot: app.screenshot())
        handsScreenshot.name = "Dealer - Table Hands"
        handsScreenshot.lifetime = .keepAlways
        add(handsScreenshot)
    }

    @MainActor
    func testRunningGameCanSwitchModesWithoutLeavingTheGame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appStoreCapture", "live"]
        app.launch()

        XCTAssertTrue(app.buttons["Miles"].waitForExistence(timeout: 2), "The live-game fixture did not load")
        app.buttons["Settings"].tap()
        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 2),
            "The Settings sheet did not open"
        )

        let vengeance = app.buttons["Vengeance"]
        let settingsNavBar = app.navigationBars["Settings"]
        let settingsList = app.collectionViews.firstMatch
        for _ in 0..<6 {
            if vengeance.exists && vengeance.isHittable && vengeance.frame.minY > settingsNavBar.frame.maxY + 8 {
                break
            }
            if settingsList.exists {
                let start = settingsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                let end = settingsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
                start.press(forDuration: 0.01, thenDragTo: end)
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(vengeance.isHittable, "The Vengeance mode chip was not reachable in Settings")
        vengeance.tap()
        app.buttons["Done"].tap()

        app.buttons["Miles"].tap()
        XCTAssertTrue(
            app.staticTexts["VENGEANCE"].waitForExistence(timeout: 1),
            "The live calculator did not update to Vengeance"
        )
        XCTAssertTrue(app.buttons["Miles"].exists, "The running game was replaced instead of preserved")
    }
}
