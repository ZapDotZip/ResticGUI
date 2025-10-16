//
//  PrefTabPerformance.swift
//  ResticGUI
//

import AppKit

class PrefTabPerformance: NSViewController {
	@IBOutlet weak var backupQoS: NSPopUpButton!
	@IBOutlet weak var storageQoS: NSPopUpButton!
	
	override func viewDidLoad() {
		if let pref = UserDefaults.standard.string(forKey: DefaultsKeys.backupQoS) {
			switch pref {
			case "userInitiated": backupQoS.selectItem(at: 0)
			case "utility": backupQoS.selectItem(at: 2)
			case "background": backupQoS.selectItem(at: 3)
			default: break
			}
		}
		
		if let pref = UserDefaults.standard.string(forKey: DefaultsKeys.storageQoS) {
			switch pref {
			case "important": storageQoS.selectItem(at: 0)
			case "standard": storageQoS.selectItem(at: 1)
			case "utility": storageQoS.selectItem(at: 2)
			case "throttle": storageQoS.selectItem(at: 3)
			default: break
			}
		}
		
	}
	
	@IBAction func backupQoSDidChange(_ sender: NSPopUpButton) {
		UserDefaults.standard.set(sender.selectedItem?.identifier, forKey: DefaultsKeys.backupQoS)
	}
	
	@IBAction func storageQoSDidChange(_ sender: NSPopUpButton) {
		UserDefaults.standard.set(sender.selectedItem?.identifier, forKey: DefaultsKeys.storageQoS)
	}
	
}
