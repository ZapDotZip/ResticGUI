//
//  PreferencesViewController.swift
//  ResticGUI
//

import Cocoa

class PreferencesTabController: NSTabViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabViewItems[1].image = NSImage.init(byReferencingFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarDeleteIcon.icns")
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window!.title = "Preferences"
	}
	
}


class PrefTabGeneral: NSViewController {
	@IBOutlet weak var binLocationSelector: NSPopUpButton!
	@IBOutlet weak var binPath: NSPathControl!
	@IBOutlet weak var binPathSIL: NSButton!
	static let resticPathPrefName = "Restic Location"
	
	lazy var appDel = NSApplication.shared.delegate as! AppDelegate
	lazy var resticController = appDel.resticController!
	
	var popover: NSPopover?
	
	/// Sets the Pop-Up selector to the user's preferences.
	private func setSelectorUserPref() {
		var userPref: String = UserDefaults.standard.string(forKey: PrefTabGeneral.resticPathPrefName) ?? "Automatic"
		if userPref != "Automatic" && userPref != "MacPorts" && userPref != "Homebrew" {
			userPref = "Custom..."
		}
		binLocationSelector.selectItem(withTitle: userPref)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setSelectorUserPref()
		checkBinPath()
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
	}
	
	/// Checks to see if the selected path is valid. If not, displays an error message to the user. Otherwise, displays where the selected binary is.
	func checkBinPath() {
		resticController.dq.async {
			do {
				let vers = try self.resticController.getVersionInfo()
				DispatchQueue.main.async {
					self.createSILMessage("\(vers.version) (\(vers.go_arch))")
					self.setBinPath(self.resticController.resticLocation!, NSImage.statusAvailableName)
				}
			} catch {
				DispatchQueue.main.async {
					NSLog("Error: \(error)")
					var errtext = error.localizedDescription
					if error is DecodingError {
						errtext = "This version of Restic may be too old, or the binary is not Restic at all."
					}
					self.displaySILMessage(errtext, NSImage.statusUnavailableName)
					self.setBinPath(self.resticController.resticLocation!, nil)
				}
			}
		}

	}
	
	@IBAction func resticLocationSelectorDidChange(_ sender: NSPopUpButton) {
		if let selection = sender.selectedItem?.title {
			if selection != "Custom..." {
				UserDefaults.standard.set(selection, forKey: PrefTabGeneral.resticPathPrefName)
				resticController.dq.async {
					self.resticController.resticLocation = nil
					self.resticController.versionInfo = nil
				}
			} else {
				let (panel, response) = openPanel(message: "Select your Restic binary.", prompt: "Select", canChooseDirectories: false, canChooseFiles: true, allowsMultipleSelection: false, canCreateDirectories: false)
				if response == NSApplication.ModalResponse.OK, panel.urls.count != 0 {
					UserDefaults.standard.set(panel.urls[0], forKey: PrefTabGeneral.resticPathPrefName)
					resticController.dq.async {
						self.resticController.resticLocation = nil
						self.resticController.versionInfo = nil
					}
				} else {
					NSLog("Cancelled bin selection")
					setSelectorUserPref()
				}
			}
			checkBinPath()
		}
	}
	
	/// Displays a popover message along with changing the SIL.
	/// - Parameters:
	///   - text: The text for the popover.
	///   - status: The status for the SIL.
	func displaySILMessage(_ text: String, _ status: NSImage.Name?) {
		if let status = status {
			binPathSIL.image = NSImage(named: status)
		}
		createSILMessage(text)
		popover!.show(relativeTo: binPathSIL.bounds, of: binPathSIL, preferredEdge: .maxX)
	}
	
	@IBAction func displaySILMessage(_ sender: NSButton) {
		guard popover != nil else {
			return
		}
		popover!.show(relativeTo: binPathSIL.bounds, of: binPathSIL, preferredEdge: .maxX)
	}
	
	
	/// Sets the SIL message popover for this class without showing the popover.
	/// - Parameter text: The text for the popover.
	func createSILMessage(_ text: String) {
		popover = NSPopover()
		let label = NSTextField(wrappingLabelWithString: text)
		label.alignment = .center
		label.sizeToFit()
		let contentViewController = NSViewController()
		contentViewController.view = NSView(frame: label.frame)
		contentViewController.view.wantsLayer = true
		contentViewController.view.addSubview(label)
		popover!.contentViewController = contentViewController
		popover!.behavior = .transient
	}
	
	/// Sets the path control URL and sets the SIL status.
	/// - Parameters:
	///   - path: The URL for the path control.
	///   - status: The status for the SIL.
	func setBinPath(_ path: URL, _ status: NSImage.Name?) {
		binPath.url = path
		if status != nil {
			binPathSIL.image = NSImage(named: status!)
		}
	}
	
}
