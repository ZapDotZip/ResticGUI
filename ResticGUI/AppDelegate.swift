//
//  AppDelegate.swift
//  ResticGUI
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private var viewCon: ViewController!
	@IBOutlet weak var resticController: ResticController!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
		// Insert code here to initialize your application
	}
	
	func viewFinishedLoading(vc: ViewController) {
		viewCon = vc
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		viewCon.saveQuit()
		return .terminateNow
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
}

@discardableResult
func Alert(title: String, message: String, style: NSAlert.Style, buttons: [String]) -> NSApplication.ModalResponse {
	let alert = NSAlert()
	alert.messageText = title
	alert.informativeText = message
	alert.alertStyle = .critical
	for btn in buttons {
		alert.addButton(withTitle: btn)
	}
	return alert.runModal()
}
