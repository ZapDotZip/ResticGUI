//
//  AppDelegate.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private var viewCon: ViewController!
	private lazy var resticController = ResticController.default
	var backupController: BackupController!
	
	override init() {
		super.init()
		if NSEvent.modifierFlags.contains(.shift) {
			safeMode()
		}
		UserDefaults.standard.register(defaults: [
			DefaultsKeys.scanAhead : true,
			DefaultsKeys.globalRepoSelection : false,
			DefaultsKeys.backupQoS : "default",
			DefaultsKeys.limitBackgroundCoreCount : true,
			DefaultsKeys.batteryQoS : true,
			DefaultsKeys.lowPowerQoS : true,
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
			Alerts.Alert(title: "An error occured.", message: "Could not trash the profiles directory: \(error.localizedDescription)\n\nThe file is located at \(ProfileManager.profileDir.relativePath).", style: .warning)
		}
		do {
			try FileManager.default.trashItem(at: ReposManager.repolistFile, resultingItemURL: nil)
			Alerts.Alert(title: "Repositories Reset", message: "The repository list has been put in your trash.\n\nIf you want to delete passwords as well, open up Keychain Access and delete application passwords with the name \(Bundle.main.bundleIdentifier ?? "").", style: .informational)
		} catch {
			NSLog("error deleting app data: \(error)")
			Alerts.Alert(title: "An error occured.", message: "Could not trash the repository list: \(error.localizedDescription)\n\nThe file is located at \(ReposManager.repolistFile.relativePath).", style: .warning)
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
		if backupController.state != .idle {
			if !DestructiveAlert(title: "Are you sure you want to quit?", message: "A backup is in progress. If you choose to quit, the backup will be stopped.", style: .informational, destructiveButtonText: "Quit") {
				return .terminateCancel
			}
		}
		return .terminateNow
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	
	@IBAction func menuItemStartBackup(_ sender: NSMenuItem) {
		if viewCon.viewState == .noBackupInProgress {
			viewCon.runBackup(sender)
		}
	}
	
	@IBAction func menuItemStopBackup(_ sender: NSMenuItem) {
		if viewCon.viewState == .backupInProgress {
			viewCon.runBackup(sender)
		}
	}
	
	@IBAction func menuItemPauseBackup(_ sender: NSMenuItem) {
		if backupController.state == .inProgress {
			if backupController.pause() {
				sender.title = "Resume Backup"
				viewCon.viewState = .backupPaused
			}
		} else if backupController.state == .suspended {
			if backupController.resume() {
				sender.title = "Pause Backup"
				viewCon.viewState = .backupInProgress
			}
		}
	}
}


/// Creates and runs an alert for a destructive action
/// - Parameters:
///   - title: The title of the alert
///   - message: The message of the alert
///   - style: The alert style
/// - Returns: Whether or not the user has agreed to the destructive action.
@discardableResult
func DestructiveAlert(title: String, message: String, style: NSAlert.Style, destructiveButtonText: String) -> Bool {
	let alert = NSAlert()
	alert.messageText = title
	alert.informativeText = message
	alert.alertStyle = .critical
	alert.addButton(withTitle: destructiveButtonText)
	alert.addButton(withTitle: "Cancel")
	if #available(macOS 11.0, *) {
		alert.buttons[0].hasDestructiveAction = true
		alert.buttons[0].bezelColor = .red
	}
	return alert.runModal() == .alertFirstButtonReturn
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

extension Notification.Name {
	static let EnvTableDidChange = Notification.Name("EnvTableDidChange")
}
