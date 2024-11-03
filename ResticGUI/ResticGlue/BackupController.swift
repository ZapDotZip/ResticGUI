//
//  BackupController.swift
//  ResticGUI
//

import Foundation

class BackupController {
	
	let rc: ResticController
	
	init(rc: ResticController) {
		self.rc = rc
	}
	
	func backup(profile: Profile) {
		var args: [String] = []
		args.append("--json")
		
	}
	
	
}
