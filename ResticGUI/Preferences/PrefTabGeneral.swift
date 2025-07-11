//
//  PrefTabGeneral.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox

class PrefTabGeneral: NSViewController {
	@IBOutlet weak var binLocationSelector: NSPopUpButton!
	@IBOutlet weak var binPath: NSPathControl!
	@IBOutlet weak var binPathSIL: NSButton!
	@IBOutlet weak var backupQoS: NSPopUpButton!
	
	lazy var appDel = NSApplication.shared.delegate as! AppDelegate
	lazy var resticController = ResticController.default
	
	var popover: NSPopover?
	
	/// Sets the Pop-Up selector to the user's preferences.
	private func setSelectorUserPref() {
		var userPref: String = UserDefaults.standard.string(forKey: DefaultsKeys.resticLocation) ?? "Automatic"
		if userPref != "Automatic" && userPref != "MacPorts" && userPref != "Homebrew" {
			userPref = "Custom..."
		}
		binLocationSelector.selectItem(withTitle: userPref)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setSelectorUserPref()
		checkBinPath()
		if let pref = UserDefaults.standard.string(forKey: DefaultsKeys.backupQoS) {
			if pref == "userInitiated" {
				backupQoS.selectItem(at: 0)
			} else if pref == "utility" {
				backupQoS.selectItem(at: 2)
			} else if pref == "background" {
				backupQoS.selectItem(at: 3)
			}
		}
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
	}
	
	/// Checks to see if the selected path is valid. If not, displays an error message to the user. Otherwise, displays where the selected binary is.
	func checkBinPath() {
		resticController.dq.async {
			do {
				let vers = try self.resticController.getVersionInfo()
				if vers == ResticController.supportedRV {
					DispatchQueue.main.async {
						self.createSILMessage("\(vers.version) (\(vers.go_arch))")
						self.setBinPath(self.resticController.resticLocation!, NSImage.statusAvailableName)
					}
				} else {
					let archMsg = {
						if vers.go_arch != ResticController.supportedRV.go_arch {
							return "Restic is the wrong architecture (\(vers.go_arch)) for your system (\(ResticController.supportedRV.go_arch))."
						} else {
							return "(\(vers.go_arch))"
						}
					}()
					let versMsg = {
						if vers.version != ResticController.supportedRV.version {
							return "This version of Restic (\(vers.version)) may not be fully compatible with ResticGUI (\(ResticController.supportedRV.version))."
						} else {
							return vers.version
						}
					}()
					DispatchQueue.main.async {
						self.createSILMessage("\(versMsg)\n \(archMsg)")
						self.setBinPath(self.resticController.resticLocation!, NSImage.statusPartiallyAvailableName)
					}
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
	
	@IBAction func backupQoSDidChange(_ sender: NSPopUpButton) {
		UserDefaults.standard.set(sender.selectedItem?.identifier, forKey: DefaultsKeys.backupQoS)
	}
	
}
