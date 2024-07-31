//
//  AppDelegate.swift
//  ResticGUI
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var viewCon: ViewController {
		return NSApplication.shared.mainWindow?.contentViewController as! ViewController
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		if NSApplication.shared.mainWindow?.isDocumentEdited ?? false {
			viewCon.saveQuit()
		}
		return .terminateNow
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func save(_ sender: NSMenuItem) {
		viewCon.saveSelectedProfile()
	}
	
}

