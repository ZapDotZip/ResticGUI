//
//  ProfileOrHeader.swift
//  ResticGUI
//

/// This class is a wrapper for Profiles and the header found in the sidebar.
class ProfileOrHeader : Equatable {
	let isHeader: Bool
	var header: String?
	var profile: String?
	
	init(header: String) {
		self.isHeader = true
		self.header = header
	}
	
	init(profile: String) {
		self.isHeader = false
		self.profile = profile
	}
	
	static func == (lhs: ProfileOrHeader, rhs: ProfileOrHeader) -> Bool {
		guard lhs.isHeader == rhs.isHeader else { return false }
		if let lp = lhs.profile, let rp = rhs.profile {
			return lp == rp
		}
		if let lh = lhs.header, let rh = rhs.header {
			return lh == rh
		}
		return false
	}
	
}
