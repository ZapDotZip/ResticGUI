//
//  ProfilesDataSource.swift
//  ResticGUI
//

import Cocoa

class ProfilesManager {
	let profileDir: URL
	
	init() {
		profileDir = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Profiles", isDirectory: true)
	}
	
	func load() -> [Profile] {
		if !FileManager.default.fileExists(atPath: profileDir.path) {
			return []
		}
		
		var profiles: [Profile] = []
		if let enumerator = try? FileManager.default.contentsOfDirectory(at: profileDir, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
			for i in enumerator {
				if i.pathExtension == "plist" {
					let decoder = PropertyListDecoder.init()
					do {
						let data = try Data.init(contentsOf: i)
						let p = try decoder.decode(Profile.self, from: data)
						profiles.append(p)
					} catch {
						NSLog("Error loading profile: \(error)")
						let alert = NSAlert()
						alert.messageText = "An error occured trying to load a saved profile."
						alert.informativeText = "\(error.localizedDescription)"
						alert.alertStyle = .critical
						alert.addButton(withTitle: "Ok")
						alert.runModal()
					}
				}
			}
		}
		return profiles
	}
	
	
	func save(profile: Profile) {
		if !FileManager.default.fileExists(atPath: profileDir.path) {
			do {
				try FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true, attributes: nil)
			} catch {
				NSLog("Error creating Profiles directory: \(error)")
				let alert = NSAlert()
				alert.messageText = "An error occured trying to create the Profiles directory."
				alert.informativeText = "Unable to create the directory necessary for storing profile information.\n\n\(error.localizedDescription)"
				alert.alertStyle = .critical
				alert.addButton(withTitle: "Ok")
				alert.runModal()
				NSApplication.shared.terminate(nil)
			}
		}
		
		let profileFile = profileDir.appendingPathComponent("\(profile.name).plist")
		let encoder = PropertyListEncoder.init()
		do {
			let data = try encoder.encode(profile)
			try data.write(to: profileFile)
		} catch {
			NSLog("Error saving Profile: \(error)")
			let alert = NSAlert()
			alert.messageText = "An error occured trying to save the Profile \"\(profile.name)\"."
			alert.informativeText = "\(error.localizedDescription)"
			alert.alertStyle = .critical
			alert.addButton(withTitle: "Ok")
			alert.runModal()
		}
		
	}
}



class ProfileOrHeader {
	let isHeader: Bool
	var header: String?
	var profile: Profile?
	
	init(header: String) {
		self.isHeader = true
		self.header = header
	}
	
	init(profile: Profile) {
		self.isHeader = false
		self.profile = profile
	}
}


class Profile: Codable {
	var name: String
	var selectedRepo: String?
	var paths: [String] = []
	var exclusions: [String] = []
	var exclusionsCaseSensitive: Bool = true
	var excludeCacheDirs: Bool = false
	var excludeMaxFilesize: Int?
	var excludesTMDefault: Bool = false
	var excludesTMUser: Bool = false
	var compression: String?
	var readConcurrency: Int?
	var packSize: Int?
	init(name: String) {
		self.name = name
	}
	
}
