//
//  ProfilesDataSource.swift
//  ResticGUI
//

import Cocoa

/// Loads and saves profiles.
struct ProfileManager {
	private static let PROFILE_EXT = "plist"
	private static let PROFILE_EXT_DOT = ".plist"
	
	private static let profileDir: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Profiles", isDirectory: true)
	}()
	
	private static let encoder = PropertyListEncoder.init()
	private static let decoder = PropertyListDecoder.init()
	
	/// Loads all saved profiles and returns an array of Profiles.
	/// - Returns: an array of profiles, empty if there are none.
	static func load() -> [Profile] {
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
						Alert(title: "An error occured trying to load the saved profile \"\(i.lastPathComponent)\".", message: error.localizedDescription, style: .critical, buttons: ["Ok"])
					}
				}
			}
		}
		profiles.sort { $0.name < $1.name }
		return profiles
	}
	
	private static func getProfilePath(_ name: String) -> URL {
		return profileDir.appendingPathComponent(name + PROFILE_EXT_DOT)
	}
	
	/// Loads a single profile with the specified name, if it exists.
	/// - Parameter name: the name of the profile
	/// - Returns: the Profile if found, otherwise nil.
	static func load(name: String) -> Profile? {
		let filePath: URL = getProfilePath(name)
		if !FileManager.default.fileExists(atPath: filePath.path) {
			return nil
		}
		
		do {
			let data = try Data.init(contentsOf: filePath)
			let p = try decoder.decode(Profile.self, from: data)
			return p
		} catch {
			NSLog("Error loading single profile: \(error)")
			return nil
		}
	}

	/// Saves the provided profile to the Profiles directory, overwriting the existing profile if it exists.
	/// - Parameter profile: the profile to save
	static func save(_ profile: Profile) {
		if profile != load(name: profile.name) {
			if !FileManager.default.fileExists(atPath: profileDir.path) {
				do {
					try FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true, attributes: nil)
				} catch {
					NSLog("Error creating Profiles directory: \(error)")
					Alert(title: "An error occured trying to create the Profiles directory.", message: "Unable to create the directory necessary for storing profile information.\n\n\(error.localizedDescription)", style: .critical, buttons: ["Ok"])
				}
			}
			save(profile, to: getProfilePath(profile.name))
		} else {
			NSLog("Profile not saved because it was unmodified.")
		}
	}
	
	/// Saves the provided profile to the specified directory., overwriting the existing profile if it exists.
	/// - Parameter profile: the profile to save
	static func save(_ profile: Profile, to filePath: URL) {
		encoder.outputFormat = .xml
		do {
			let data = try encoder.encode(profile)
			try data.write(to: filePath)
		} catch {
			NSLog("Error saving Profile: \(error)")
			Alert(title: "An error occured trying to save the Profile \"\(profile.name)\".", message: error.localizedDescription, style: .critical, buttons: ["Ok"])
		}
	}
	
	static func delete(_ profile: Profile) {
		let filePath = getProfilePath(profile.name)
		if FileManager.default.fileExists(atPath: filePath.path) {
			do {
				try FileManager.default.trashItem(at: filePath, resultingItemURL: nil)
			} catch {
				NSLog("Error deleting profile: \(error)")
				let res = Alert(title: "Unable to delete profile.", message: "Couldn't delete the profile \(profile.name)\n\n\(error.localizedDescription)", style: .warning, buttons: ["Retry", "Cancel"])
				if res == .alertFirstButtonReturn {
					delete(profile)
				}
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
