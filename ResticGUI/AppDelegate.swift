//
//  AppDelegate.swift
//  ResticGUI
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private var viewCon: ViewController!
	@IBOutlet weak var resticController: ResticController!
	var backupController: BackupController!
	
	override init() {
		super.init()
		#if DEBUG
			UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
		#endif
		UserDefaults.standard.register(defaults: [
			"Scan Ahead" : true,
		])
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
	
	func viewFinishedLoading(vc: ViewController) {
		viewCon = vc
		backupController = BackupController.init(resticController: resticController, viewController: vc)
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		viewCon.saveQuit()
		if backupController.backupInProgress {
			let res = Alert(title: "Are you sure you want to quit?", message: "A backup is in progress.", style: .informational, buttons: ["Quit", "Cancel"])
			if res == .alertSecondButtonReturn {
				return .terminateCancel
			}
		}
		return .terminateNow
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	
	@IBAction func menuItemStartBackup(_ sender: NSMenuItem) {
		viewCon.runBackup(sender)
	}
	
	@IBAction func menuItemStopBackup(_ sender: NSMenuItem) {
		viewCon.runBackup(sender)
	}
	
	@IBAction func menuItemPauseBackup(_ sender: NSMenuItem) {
		if !backupController.isSuspended {
			if backupController.pause() {
				sender.title = "Resume Backup"
			}
		} else {
			if backupController.resume() {
				sender.title = "Pause Backup"
			}
		}
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

func openPanel(message: String, prompt: String, canChooseDirectories: Bool, canChooseFiles: Bool, allowsMultipleSelection: Bool, canCreateDirectories: Bool) -> (NSOpenPanel, NSApplication.ModalResponse) {
	let openPanel = NSOpenPanel()
	openPanel.message = message
	openPanel.prompt = prompt
	openPanel.canChooseDirectories = canChooseDirectories
	openPanel.canChooseFiles = canChooseFiles
	openPanel.allowsMultipleSelection = allowsMultipleSelection
	openPanel.canCreateDirectories = canCreateDirectories
	return (openPanel, openPanel.runModal())
}
