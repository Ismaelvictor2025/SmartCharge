//
//  SmartChargeUITests.swift
//  SmartChargeUITests
//

import XCTest

final class SmartChargeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabNavigationAndCrossTabSync() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify Dashboard tab loads with core metrics
        XCTAssertTrue(app.navigationBars["Journey Dashboard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Polestar 2 Long Range"].exists)
        XCTAssertTrue(app.staticTexts["Theoretical Range"].exists)

        // Navigate to Planner Tab
        let plannerTab = app.tabBars.buttons["Planner"]
        XCTAssertTrue(plannerTab.exists)
        plannerTab.tap()

        XCTAssertTrue(app.navigationBars["Journey Planner"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Swap Origin & Destination"].exists)

        // Tap Swap button and verify it responds
        app.buttons["Swap Origin & Destination"].tap()

        // Navigate to Stations Tab
        let stationsTab = app.tabBars.buttons["Stations"]
        XCTAssertTrue(stationsTab.exists)
        stationsTab.tap()

        XCTAssertTrue(app.navigationBars["Station Finder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Along Route"].exists)
        XCTAssertTrue(app.buttons["All Stations"].exists)

        // Toggle All Stations
        app.buttons["All Stations"].tap()

        // Navigate to Recommend Tab
        let recommendTab = app.tabBars.buttons["Recommend"]
        XCTAssertTrue(recommendTab.exists)
        recommendTab.tap()

        XCTAssertTrue(app.navigationBars["Smart Recommendations"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["STRATEGY & BATTERY PARAMETERS"].exists)

        // Navigate to Analytics Tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.exists)
        analyticsTab.tap()

        XCTAssertTrue(app.navigationBars["Route Analytics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ROUTE RISK CLASSIFICATION"].exists)
        XCTAssertTrue(app.staticTexts["Range Buffer vs Driving Distance"].exists)

        // Return to Dashboard
        app.tabBars.buttons["Dashboard"].tap()
        XCTAssertTrue(app.navigationBars["Journey Dashboard"].exists)
    }

    @MainActor
    func testCapturePromotionalScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        let docsDir = "/Users/ivnr/Documents/Documents:iOSApps/SmartCharge/Docs/Screenshots"

        func saveScreen(named name: String) {
            let screenshot = XCUIScreen.main.screenshot()
            let path = "\(docsDir)/\(name).png"
            try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
        }

        XCTAssertTrue(app.navigationBars["Journey Dashboard"].waitForExistence(timeout: 5))
        saveScreen(named: "01_Dashboard_BatterySafety")

        app.tabBars.buttons["Planner"].tap()
        XCTAssertTrue(app.navigationBars["Journey Planner"].waitForExistence(timeout: 5))
        saveScreen(named: "02_JourneyPlanner")

        app.tabBars.buttons["Stations"].tap()
        XCTAssertTrue(app.navigationBars["Station Finder"].waitForExistence(timeout: 5))
        saveScreen(named: "03_StationFinder")

        app.tabBars.buttons["Recommend"].tap()
        XCTAssertTrue(app.navigationBars["Smart Recommendations"].waitForExistence(timeout: 5))
        saveScreen(named: "04_SmartRecommendations")

        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.navigationBars["Route Analytics"].waitForExistence(timeout: 5))
        saveScreen(named: "05_RouteAnalytics")
    }
}
