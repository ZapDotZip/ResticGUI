//
//  Repo.swift
//  ResticGUI
//

import Foundation
import SwiftToolbox


final class Repo: Codable {
	var name: String?
	var path: String
	var cachedPassword: String?
	var cacheDir: String?
	var env: [String : String]?
	
	init(path: String, password: String) throws {
		self.path = path
		self.cachedPassword = password
		try STBKeychain.add(path: path, password: password)
	}
	
	/// Creates a Repo object without adding the password to the keychain.
	/// - Parameters:
	///   - path: The repository path
	///   - password: The password that will not be added to the keychain.
	init(path: String, noKeychain password: String) {
		self.path = path
		self.cachedPassword = password
	}
	
	enum CodingKeys: CodingKey {
		case name
		case path
		case cacheDir
		case env
		case id
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.name = try container.decodeIfPresent(String.self, forKey: .name)
		self.path = try container.decode(String.self, forKey: .path)
		self.cacheDir = try container.decodeIfPresent(String.self, forKey: .cacheDir)
		self.env = try container.decodeIfPresent([String : String].self, forKey: .env)
		self.id = try container.decodeIfPresent(String.self, forKey: .id)
	}
		
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeIfPresent(self.name, forKey: .name)
		try container.encode(self.path, forKey: .path)
		try container.encodeIfPresent(self.cacheDir, forKey: .cacheDir)
		try container.encodeIfPresent(self.env, forKey: .env)
		try container.encodeIfPresent(self.id, forKey: .id)
	}
	
	func getPassword() throws(STBKeychainError) -> String {
		guard cachedPassword == nil else {
			return cachedPassword!
		}
		cachedPassword = try STBKeychain.load(path: path)
		return cachedPassword!
	}
	
	/// Sets the password without adding it to the keychain.
	/// - Parameter newPass: The updated password.
	func setPassword(_ newPass: String) {
		cachedPassword = newPass
	}
	
	/// Sets the password and adds it to the keychain.
	/// - Parameter newPass: The updated password.
	func saveNewPassword(newPass: String) throws(STBKeychainError) {
		try STBKeychain.add(path: path, password: newPass)
		cachedPassword = newPass
	}
	
	/// Sets the password and updates the keychain.
	/// - Parameter newPass: The updated password.
	func updatePassword(newPass: String) throws(STBKeychainError) {
		try STBKeychain.updateOrAdd(path: path, password: newPass)
		cachedPassword = newPass
	}
	
	/// Updates the path and keychain.
	/// - Parameter newPath: The updated path.
	func updatePath(newPath: String) throws(STBKeychainError) {
		try STBKeychain.update(path: newPath)
		path = newPath
	}
	
	func selfDeletePassword() throws(STBKeychainError) {
		// TODO: implement
	}
	
	/// Gets the "nickname" or the path.
	/// - Returns: The name to use in menus.
	func getName() -> String {
		return name ?? path
	}
	
	/// Returns a repo-configured env dictionary with password.
	func getEnv() throws(STBKeychainError) -> [String : String] {
		var newEnv = env ?? [String : String]()
		newEnv["HOME"] = ProcessInfo.processInfo.environment["HOME"]
		newEnv["RESTIC_PASSWORD"] = try getPassword()
		newEnv["RESTIC_REPOSITORY"] = self.path
		if let cd = cacheDir {
			newEnv["RESTIC_CACHE_DIR"] = cd
		}
		return newEnv
	}
	
	var id: String?
	/// Sets & returns the repository's ID, if it can.
	func loadID() -> String? {
		if id == nil {
			id = try? ResticController.default.getConfig(of: self).id
			if id != nil {
				try? ReposManager.default.save()
			}
		}
		return id
	}

}
