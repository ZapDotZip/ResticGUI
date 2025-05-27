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
		if NSEvent.modifierFlags.contains(.shift) {
			safeMode()
		}
		UserDefaults.standard.register(defaults: [
			"Scan Ahead" : true,
			"Global Repo Selection" : false,
			"Backup QoS" : "default",
			"Limit Background Core Count" : true,
			"QoS Background on Battery" : true,
			"QoS Background on Low Power" : true,
		])
	}
	
	private func safeMode() {
		let alert = NSAlert()
		alert.messageText = "Safe Mode"
		alert.informativeText = "Pressing the shift key while launching ResticGUI will enter reset mode.\n\nIf you choose to reset, all of your profiles and repositories will be put into your trash."
		alert.alertStyle = .critical
		alert.addButton(withTitle: "Continue Normally")
		alert.addButton(withTitle: "Reset Profiles and Repository list")
		alert.buttons[1].bezelColor = .red
		alert.addButton(withTitle: "Quit")
		
		alert.showsSuppressionButton = true
		alert.suppressionButton?.title = "Also reset app preferences"
		
		let res = alert.runModal()
		switch res {
			case .alertFirstButtonReturn: break
			case .alertSecondButtonReturn:
				if alert.suppressionButton?.state == .on {
					resetAppData(deletePrefs: true)
				} else {
					resetAppData()
				}
			case .alertThirdButtonReturn:
				NSApp.terminate(self)
			default:
				NSLog("unknown response to safe mode alert: \(res)")
		}
	}
	
	private func resetAppData(deletePrefs: Bool = false) {
		do {
			try FileManager.default.trashItem(at: ProfileManager.profileDir, resultingItemURL: nil)
		} catch {
			NSLog("error deleting app data: \(error)")
			Alert(title: "An error occured.", message: "Could not trash the profiles directory: \(error.localizedDescription)The file is located at \(ProfileManager.profileDir.relativePath).", style: .warning, buttons: [])
		}
		do {
			try FileManager.default.trashItem(at: ReposManager.repolistFile, resultingItemURL: nil)
			Alert(title: "Repositories Reset", message: "The repository list has been put in your trash.\n\nIf you want to delete passwords as well, open up Keychain Access and delete application passwords with the name \(Bundle.main.bundleIdentifier ?? "").", style: .informational, buttons: ["Ok"])
		} catch {
			NSLog("error deleting app data: \(error)")
			Alert(title: "An error occured.", message: "Could not trash the repository list: \(error.localizedDescription)\n\nThe file is located at \(ReposManager.repolistFile.relativePath).", style: .warning, buttons: [])
		}
		if deletePrefs {
			UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
		}
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
func openPanel(message: String, prompt: String, canChooseDirectories: Bool, canChooseFiles: Bool, allowsMultipleSelection: Bool, canCreateDirectories: Bool, allowedFileTypes: [String]? = nil) -> (NSOpenPanel, NSApplication.ModalResponse) {
	let openPanel = NSOpenPanel()
	openPanel.message = message
	openPanel.prompt = prompt
	openPanel.canChooseDirectories = canChooseDirectories
	openPanel.canChooseFiles = canChooseFiles
	openPanel.allowsMultipleSelection = allowsMultipleSelection
	openPanel.canCreateDirectories = canCreateDirectories
	if allowedFileTypes != nil {
		openPanel.allowedFileTypes = allowedFileTypes
	}
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

import IOKit.ps
func isOnBattery() -> Bool {
	let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
	let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array
	
	for i in list {
		if let desc = IOPSGetPowerSourceDescription(info, i).takeUnretainedValue() as? [String: Any],
		   let isCharging = (desc[kIOPSIsChargingKey] as? Bool) {
			return !isCharging
		}
	}
	return false
}

func sysctlInt(_ name: String) -> Int? {
	var size = 0
	guard sysctlbyname(name, nil, &size, nil, 0) == 0 else {
		return nil
	}
	var result = 0
	guard sysctlbyname(name, &result, &size, nil, 0) == 0 else {
		return nil
	}
	return result
}

func sysctlString(_ name: String) -> String? {
	var size = 0
	guard sysctlbyname(name, nil, &size, nil, 0) == 0 else {
		return nil
	}
	var result = [CChar](repeating: 0,  count: size)
	guard sysctlbyname(name, &result, &size, nil, 0) == 0 else {
		return nil
	}
	return String(utf8String: result)
}

/// Gets the core counts of the two different types of cores in the M-series CPUs, if possible.
/// - Returns: Efficiency core count, Performance core count.
func getDifferentialCoreCount() -> (Int, Int)? {
	guard sysctlString("hw.perflevel0.name") == "Performance" && sysctlString("hw.perflevel1.name") == "Efficiency" else {
		return nil
	}
	if let eCores = sysctlInt("hw.perflevel1.logicalcpu"), let pCores = sysctlInt("hw.perflevel0.logicalcpu") {
		return (eCores, pCores)
	}
	return nil
}
