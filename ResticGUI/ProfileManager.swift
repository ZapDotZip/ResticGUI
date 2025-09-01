//
//  ProfilesDataSource.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox

/// Loads and saves profiles.
class ProfileManager {
	private static let PROFILE_EXT = "plist"
	private static let PROFILE_EXT_DOT = ".plist"
	
	static let profileDir: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			.appending(path: "ResticGUI", isDirectory: true)
			.appending(path: "Profiles", isDirectory: true)
	}()
	
	private static let encoder = {
		let ple = PropertyListEncoder.init()
		ple.outputFormat = .xml
		return ple
	}()
	private static let decoder = PropertyListDecoder.init()
	
	/// Loads all saved profiles and returns an array of Profiles.
	/// - Returns: an array of profiles, empty if there are none.
	static func getProfilesList() -> [String] {
		guard FileManager.default.fileExists(atPath: profileDir.path) else {
			return []
		}
		if let enumerator = try? FileManager.default.contentsOfDirectory(at: profileDir, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
			return enumerator.compactMap { url in
				if url.pathExtension == PROFILE_EXT {
					return url.deletingPathExtension().lastPathComponent
				} else {
					return nil
				}
			}.sorted { $0 < $1 }
		}
		return []
	}
	
	/// Loads a profile from the specified URL.
	/// - Returns: The profile, if it could be decoded.
	static func load(_ url: URL) -> Profile? {
		do {
			let data = try Data.init(contentsOf: url)
			let p = try decoder.decode(Profile.self, from: data)
			return p
		} catch {
			NSLog("Error loading profile: \(error)")
			STBAlerts.alert(title: "An error occured trying to load the profile \"\(url.lastPathComponent)\".", message: error.localizedDescription, style: .critical)
		}
		return nil
	}
	
	private static func getProfilePath(_ name: String) -> URL {
		return profileDir.appending(path: name + PROFILE_EXT_DOT, isDirectory: false)
	}
	
	/// Loads a single profile with the specified name, if it exists.
	/// - Parameter name: the name of the profile
	/// - Returns: the Profile if found, otherwise nil.
	static func load(named: String) throws -> Profile {
		let filePath: URL = getProfilePath(named)
		let data = try Data.init(contentsOf: filePath)
		let p = try decoder.decode(Profile.self, from: data)
		return p
	}

	/// Saves the provided profile to the Profiles directory, overwriting the existing profile if it exists.
	/// - Parameter profile: the profile to save
	static func save(_ profile: Profile) throws {
		guard profile == (try? load(named: profile.name)) else {
			NSLog("Profile not saved because it was unmodified.")
			return
		}
		if !FileManager.default.fileExists(atPath: profileDir.localPath) {
			try FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true, attributes: nil)
		}
		try save(profile, to: getProfilePath(profile.name))
	}
	
	/// Saves the provided profile to the specified directory., overwriting the existing profile if it exists.
	/// - Parameter profile: the profile to save
	static func save(_ profile: Profile, to filePath: URL) throws {
		let data = try encoder.encode(profile)
		try data.write(to: filePath)
	}
	
	static func delete(_ profileName: String) {
		let filePath = getProfilePath(profileName)
		if FileManager.default.fileExists(atPath: filePath.path) {
			do {
				try FileManager.default.trashItem(at: filePath, resultingItemURL: nil)
			} catch {
				NSLog("Error deleting profile: \(error)")
				let res = STBAlerts.alert(title: "Unable to delete profile.", message: "Couldn't delete the profile \(profileName)\n\n\(error.localizedDescription)", style: .warning, buttons: ["Retry", "Cancel"])
				if res == .alertFirstButtonReturn {
					delete(profileName)
				}
			}
			
		}
	}
	
	public static func rename(from oldName: String, to newName: String) throws {
		let profile = try load(named: oldName)
		profile.name = newName
		try save(profile)
		try FileManager.default.moveItem(at: getProfilePath(oldName), to: getProfilePath(newName))
	}
	
}



/// This class is a wrapper for Profiles and the header found in the sidebar.
class ProfileOrHeader {
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
}
