//
//  ResticGUIUITests.swift
//  ResticGUIUITests
//

import XCTest

class ResticGUIUITests: XCTestCase {
	
	var app: XCUIApplication! = nil

	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		app = XCUIApplication()
		app.launchArguments = ["--test"]
		app.activate()
		app.cells.containing(.staticText, identifier: "ProfilesHeader").firstMatch.typeText("testingprofile\r")
		
		continueAfterFailure = false
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	
	func testAddAndDeleteProfile() {
		app.buttons["addProfileButton"].click()
		app.cells.containing(.staticText, identifier: "ProfilesHeader").firstMatch.typeText("test\r")
		XCTAssert(app.cells.textFields["test"].exists)
		app.cells.textFields["test"].click()
		app.buttons["deleteProfileButton"].click()
		app.dialogs.buttons["Delete"].click()
		XCTAssertFalse(app.cells.textFields["test"].exists)
	}
	
	func testAddAndRemoveRepo() {
		app.groups.buttons["add"].click()
		let element = app.cells.containing(.staticText, identifier: "ProfilesHeader").firstMatch
		element.typeText("test repo")
		app.textFields["repoPath"].click()
		element.typeText("/test")
		app.secureTextFields["repoPassword"].click()
		element.typeText("password")
		app.sheets.buttons["repoSaveEditButton"].click()
		
		app.popUpButtons["repoPopUpList"].click()
		XCTAssert(app.menuItems["test repo"].exists)
		app.popUpButtons["repoPopUpList"].click()
		
		app.groups.buttons["remove"].click()
		app.dialogs.buttons["Delete"].click()
		
		app.popUpButtons["repoPopUpList"].click()
		XCTAssertFalse(app.menuItems["test repo"].exists)
	}
	
	func testPerformancePreferences() {
		// Open Preferences Window
		app.typeKey(",", modifierFlags:.command)
		app.toolbars.buttons["Performance"].click()
		
		// Store current values
		let initialQoS = app.popUpButtons["CPU QoS Selector"].value as! String
		let initialConcurrency = app.checkBoxes["Limit read concurrency when running on efficiency cores"].value as! Bool
		let initialBattery = app.checkBoxes["Always use efficiency cores on battery"].value as! Bool
		let initialLowPower = app.checkBoxes["Always use efficiency cores on Low Power mode"].value as! Bool
		
		// Change values
		app.popUpButtons["CPU QoS Selector"].click()
		if initialQoS != "Utility" {
			app.menuItems["Utility"].click()
		} else {
			app.menuItems["Default"].click()
		}
		app.checkBoxes["Limit read concurrency when running on efficiency cores"].click()
		app.checkBoxes["Always use efficiency cores on battery"].click()
		app.checkBoxes["Always use efficiency cores on Low Power mode"].click()
		
		// Close preferences window
		app.windows["PreferencesWindow"].typeKey("w", modifierFlags:.command)
		// Open Preferences Window
		app.typeKey(",", modifierFlags:.command)
		app.toolbars.buttons["Performance"].click()
		
		// Check if changes persisted
		XCTAssertNotEqual(initialQoS, app.popUpButtons["CPU QoS Selector"].value as! String)
		XCTAssertNotEqual(initialConcurrency, app.checkBoxes["Limit read concurrency when running on efficiency cores"].value as! Bool)
		XCTAssertNotEqual(initialBattery, app.checkBoxes["Always use efficiency cores on battery"].value as! Bool)
		XCTAssertNotEqual(initialLowPower, app.checkBoxes["Always use efficiency cores on Low Power mode"].value as! Bool)
		
		// Restore original settings
		app.popUpButtons["CPU QoS Selector"].click()
		app.menuItems[initialQoS].click()
		app.checkBoxes["Limit read concurrency when running on efficiency cores"].click()
		app.checkBoxes["Always use efficiency cores on battery"].click()
		app.checkBoxes["Always use efficiency cores on Low Power mode"].click()
	}
	
	
	func testLaunchPerformance() {
		if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
			// This measures how long it takes to launch your application.
			measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
				XCUIApplication().launch()
			}
		}
	}
}
