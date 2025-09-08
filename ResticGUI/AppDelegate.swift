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
	
	let appVersion: String
	
	public static let appSupportDirectory: URL = {
		#if DEBUG
		if CommandLine.arguments.contains("--test") {
			return FileManager.default.temporaryDirectory
				.appending(path: UUID().uuidString, isDirectory: true)
				.appending(path: "ResticGUI", isDirectory: true)
		} else {
			return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "ResticGUI", isDirectory: true)
		}
		#else
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "ResticGUI", isDirectory: true)
		#endif
	}()
	
	override init() {
		appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
		super.init()
		let lastLaunchVersion = UserDefaults.standard.string(forKey: "Version")
		if lastLaunchVersion == nil {
			UserDefaults.standard.set(appVersion, forKey: "Version")
		}
		
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
			STBAlerts.alert(title: "An error occured.", message: "Could not trash the profiles directory: \(error.localizedDescription)\n\nThe file is located at \(ProfileManager.profileDir.relativePath).", style: .warning)
		}
		do {
			try FileManager.default.trashItem(at: ReposManager.repolistFile, resultingItemURL: nil)
			STBAlerts.alert(title: "Repositories Reset", message: "The repository list has been put in your trash.\n\nIf you want to delete passwords as well, open up Keychain Access and delete application passwords with the name \(Bundle.main.bundleIdentifier ?? "").", style: .informational)
		} catch {
			NSLog("error deleting app data: \(error)")
			STBAlerts.alert(title: "An error occured.", message: "Could not trash the repository list: \(error.localizedDescription)\n\nThe file is located at \(ReposManager.repolistFile.relativePath).", style: .warning)
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
		backupController = BackupController.init(display: vc)
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		viewCon.saveQuit()
		if backupController.state != .idle {
			if !STBAlerts.destructiveAlert(title: "Are you sure you want to quit?", message: "A backup is in progress. If you choose to quit, the backup will be stopped.", style: .informational, destructiveButtonText: "Quit") {
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

extension Notification.Name {
	static let EnvTableDidChange = Notification.Name("EnvTableDidChange")
}
