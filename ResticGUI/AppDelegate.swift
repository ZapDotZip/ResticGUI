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
			"Global Repo Selection" : false,
			"Backup QoS" : "default"
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


/// Creates an Open/Save Dialogue panel for the user.
/// - Parameters:
/// - Returns: The panel itself, to get URLs from, and the response from the user.
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

func savePanel(title: String, message: String, nameFieldLabel: String, nameField: String, currentDirectory: URL?, canCreateDirectories: Bool, canSelectHiddenExtension: Bool) -> (URL?, NSApplication.ModalResponse) {
	let panel = NSSavePanel()
	panel.title = title
	panel.message = message
	panel.nameFieldLabel = nameFieldLabel
	panel.nameFieldStringValue = nameField
	if currentDirectory != nil {
		panel.directoryURL = currentDirectory
	}
	panel.canCreateDirectories = canCreateDirectories
	panel.canSelectHiddenExtension = canSelectHiddenExtension
	
	let res = panel.runModal()
	return (panel.url, res)
}

func savePanel(for window: NSWindow, message: String, nameFieldLabel: String, nameField: String, currentDirectory: URL?, canCreateDirectories: Bool, canSelectHiddenExtension: Bool, isExtensionHidden: Bool, completionHandler handler: @escaping (NSApplication.ModalResponse, URL?) -> Void) {
	let panel = NSSavePanel()
	panel.message = message
	panel.nameFieldLabel = nameFieldLabel
	panel.nameFieldStringValue = nameField
	if currentDirectory != nil {
		panel.directoryURL = currentDirectory
	}
	panel.canCreateDirectories = canCreateDirectories
	panel.canSelectHiddenExtension = canSelectHiddenExtension
	panel.isExtensionHidden = isExtensionHidden
	
	panel.beginSheetModal(for: window, completionHandler: { response in
		handler(response, panel.url)
	})
}
