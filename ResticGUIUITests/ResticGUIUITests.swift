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
	
	
	func testLaunchPerformance() {
		if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
			// This measures how long it takes to launch your application.
			measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
				XCUIApplication().launch()
			}
		}
	}
}
