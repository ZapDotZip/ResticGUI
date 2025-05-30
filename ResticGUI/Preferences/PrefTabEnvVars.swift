//
//  PrefTabEnvVars.swift
//  ResticGUI
//

import AppKit

class PrefTabEnvVars: NSViewController {
	
	@IBOutlet var envTable: EnviormentTableView!
	
	override func viewDidLoad() {
		envTable.table.load(UserDefaults.standard.dictionary(forKey: "GlobalEnviormentTable") as! [String: String]?)
		NotificationCenter.addObserver(self, forKeyPath: Notification.Name.EnvTableDidChange.rawValue, context: nil)
		NotificationCenter.default.addObserver(forName: Notification.Name.EnvTableDidChange, object: envTable.table, queue: nil) { notif in
			UserDefaults.standard.set(self.envTable.table.save(), forKey: "GlobalEnviormentTable")
		}
	}

}
