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
	
	private lazy var appDel = NSApplication.shared.delegate as! AppDelegate
	private lazy var resticController = ResticController.default
	
	private var popover: NSPopover?
	private var silMessage: String = "Unknown status."
	
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
						self.setRLUI(path: self.resticController.resticLocation!, status: NSImage.statusAvailableName, silText: "\(vers.version) (\(vers.go_arch))")
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
						self.setRLUI(path: self.resticController.resticLocation!, status: NSImage.statusPartiallyAvailableName, silText: "\(versMsg)\n \(archMsg)")
					}
				}
			} catch {
				DispatchQueue.main.async {
					NSLog("Error: \(error)")
					var errtext = error.localizedDescription
					if error is DecodingError {
						errtext = "This version of Restic may be too old, or the binary is not Restic at all."
					}
					let path = URL(fileURLWithPath: ((UserDefaults.standard.string(forKey: DefaultsKeys.resticLocation) ?? "") as NSString).expandingTildeInPath)
					self.setRLUI(path: path, status: NSImage.statusUnavailableName, silText: errtext)
					self.displaySILMessage(self)
				}
			}
		}
	}
	
	@IBAction func resticLocationSelectorDidChange(_ sender: NSPopUpButton) {
		if let selection = sender.selectedItem?.title {
			if selection != "Custom..." {
				UserDefaults.standard.set(selection, forKey: DefaultsKeys.resticLocation)
			} else {
				if let url = FileDialogues.openPanel(message: "Select your Restic binary.", prompt: "Select", canChooseDirectories: false, canChooseFiles: true, canSelectMultipleItems: false, canCreateDirectories: false)?.first {
					UserDefaults.standard.set(url, forKey: DefaultsKeys.resticLocation)
				} else {
					setSelectorUserPref()
				}
			}
			checkBinPath()
		}
	}
		
	/// Displays the popover message.
	@IBAction func displaySILMessage(_ sender: Any) {
		if let popover {
			popover.show(relativeTo: binPathSIL.bounds, of: binPathSIL, preferredEdge: .maxX)
		} else {
			popover = Alerts.PopoverTextAlert(text: silMessage, relativeTo: binPathSIL, preferredEdge: .maxX)
		}
	}
	
	/// Sets the path control URL and sets the SIL status.
	/// - Parameters:
	///   - path: The URL for the path control.
	///   - status: The status for the SIL.
	func setRLUI(path: URL, status: NSImage.Name, silText: String) {
		binPath.url = path
		binPathSIL.image = NSImage(named: status)
		silMessage = silText
		popover = nil
	}
	
	@IBAction func backupQoSDidChange(_ sender: NSPopUpButton) {
		UserDefaults.standard.set(sender.selectedItem?.identifier, forKey: DefaultsKeys.backupQoS)
	}
	
}
