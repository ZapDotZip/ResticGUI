//
//  ProfilesDataSource.swift
//  ResticGUI
//

import Cocoa

class ProfilesDataSource: NSObject, NSOutlineViewDataSource {
	var profiles: [Profile] = []
	override init() {
		profiles.append(Profile.init(name: "Profiles", isHeader: true))
		profiles.append(Profile.init(name: "Test profile"))
		
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		profiles[index]
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		profiles.count
	}
	
}


class Profile {
	var name: String
	var isHeader: Bool
	init(name: String, isHeader: Bool = false) {
		self.name = name
		self.isHeader = isHeader
	}
	
}
