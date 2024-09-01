//
//  ProfilesDataSource.swift
//  ResticGUI
//

import Cocoa

class ProfilesManager {
	let PROFILE_EXT = "plist"
	let PROFILE_EXT_DOT = ".plist"
	
	let profileDir: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Profiles", isDirectory: true)
	}()
	
	let encoder = PropertyListEncoder.init()
	let decoder = PropertyListDecoder.init()
	
	/// Loads all saved profiles and returns an array of Profiles.
	/// - Returns: an array of profiles, empty if there are none.
	func load() -> [Profile] {
		if !FileManager.default.fileExists(atPath: profileDir.path) {
			return []
		}
		
		var profiles: [Profile] = []
		if let enumerator = try? FileManager.default.contentsOfDirectory(at: profileDir, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
			for i in enumerator {
				if i.pathExtension == PROFILE_EXT {
					do {
						let data = try Data.init(contentsOf: i)
						let p = try decoder.decode(Profile.self, from: data)
						profiles.append(p)
					} catch {
						NSLog("Error loading profile: \(error)")
						let alert = NSAlert()
						alert.messageText = "An error occured trying to load the saved profile \"\(i.lastPathComponent)\"."
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
	
	/// Loads a single profile with the specified name, if it exists.
	/// - Parameter name: the name of the profile
	/// - Returns: the Profile if found, otherwise nil.
	func load(name: String) -> Profile? {
		let filePath = profileDir.appendingPathComponent(name + PROFILE_EXT_DOT).path
		if !FileManager.default.fileExists(atPath: filePath) {
			return nil
		}
		
		let decoder = PropertyListDecoder.init()
		do {
			let data = try Data.init(contentsOf: URL(string: filePath)!)
			let p = try decoder.decode(Profile.self, from: data)
			return p
		} catch {
			NSLog("Error loading single profile: \(error)")
			return nil
		}
	}

	/// Saves the provided profile, overwriting the existing profile if it exists.
	/// - Parameter profile: the profile to save
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
		
		if profile != load(name: profile.name) {
			let filePath = profileDir.appendingPathComponent(profile.name + PROFILE_EXT_DOT)
			do {
				let data = try encoder.encode(profile)
				try data.write(to: filePath)
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
	
}



/// This class is a wrapper for Profiles and the header found in the sidebar.
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


class Profile: Codable, Equatable {
	var name: String
	var selectedRepo: String?
	var paths: [String] = []
	var exclusions: [String] = []
	var exclusionsCS: Bool = true
	var excludeCacheDirs: Bool = false
	var excludeMaxFilesize: String?
	var excludePatternFile: String?
	var excludePatternFileCS: Bool = true
	var excludesTMDefault: Bool = false
	var excludesTMUser: Bool = false
	var compression: String?
	var readConcurrency: Int?
	var packSize: Int?
	
	init(name: String) {
		self.name = name
	}
	
	static func == (lhs: Profile, rhs: Profile) -> Bool {
		return lhs.name == rhs.name &&
			lhs.name == rhs.name &&
			lhs.selectedRepo == rhs.selectedRepo &&
			lhs.paths == rhs.paths &&
			lhs.exclusions == rhs.exclusions &&
			lhs.exclusionsCS == rhs.exclusionsCS &&
			lhs.excludeCacheDirs == rhs.excludeCacheDirs &&
			lhs.excludeMaxFilesize == rhs.excludeMaxFilesize &&
			lhs.excludePatternFile == rhs.excludePatternFile &&
			lhs.excludePatternFileCS == rhs.excludePatternFileCS &&
			lhs.excludesTMDefault == rhs.excludesTMDefault &&
			lhs.excludesTMUser == rhs.excludesTMUser &&
			lhs.compression == rhs.compression &&
			lhs.readConcurrency == rhs.readConcurrency &&
			lhs.packSize == rhs.packSize
	}
	
	func addPath(_ path: String) {
		// TODO: Check if path already exists.
		paths.append(path)
	}
	
}
