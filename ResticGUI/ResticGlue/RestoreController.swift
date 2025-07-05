//
//  RestoreController.swift
//  ResticGUI
//

import Foundation

struct RestorePlan {
	enum restoreSourceType {
		case entireSnapshot
		case selectedFiles(files: [String])
	}
	enum restoreDestinationType {
		case originalSource(overwrite: Bool)
		case newLocation(path: URL)
	}
	
	let snapshot: ResticResponse.Snapshot
	let restoreSource: restoreSourceType
	let restoreDestination: restoreDestinationType
	
}

class RestoreController {
	private static let rc = ResticController.default
	private var plan: RestorePlan
	
	init(plan: RestorePlan) {
		self.plan = plan
	}
	
	func restore() {
		
	}
	
}
