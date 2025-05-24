//
//  DataClasses.swift
//  ResticGUI
//

import Foundation


final class Profile: Codable, Equatable {
	var name: String
	var selectedRepo: String?
	var paths: [String] = []
	var tags: [String] = []
	var exclusions: String?
	var exclusionsCS: Bool = true
	var excludeCacheDirs: Bool = false
	var excludeMaxFilesize: String?
	var excludePatternFile: String?
	var excludePatternFileCS: Bool = true
	var excludesTMDefault: Bool = false
	var excludesTMUser: Bool = false
	var compression: String?
	var readConcurrency: UInt?
	var packSize: Int?
	
	var uuid: UUID
	var profileVersion: Int
	
	init(name: String) {
		self.name = name
		self.uuid = UUID()
		self.profileVersion = 1
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		selectedRepo = try container.decodeIfPresent(String.self, forKey: .selectedRepo)
		paths = try container.decode([String].self, forKey: .paths)
		tags = try container.decode([String].self, forKey: .tags)
		exclusions = try container.decodeIfPresent(String.self, forKey: .exclusions)
		exclusionsCS = try container.decode(Bool.self, forKey: .exclusionsCS)
		excludeCacheDirs = try container.decode(Bool.self, forKey: .excludeCacheDirs)
		excludeMaxFilesize = try container.decodeIfPresent(String.self, forKey: .excludeMaxFilesize)
		excludePatternFile = try container.decodeIfPresent(String.self, forKey: .excludePatternFile)
		excludePatternFileCS = try container.decode(Bool.self, forKey: .excludePatternFileCS)
		excludesTMDefault = try container.decode(Bool.self, forKey: .excludesTMDefault)
		excludesTMUser = try container.decode(Bool.self, forKey: .excludesTMUser)
		compression = try container.decodeIfPresent(String.self, forKey: .compression)
		readConcurrency = try container.decodeIfPresent(UInt.self, forKey: .readConcurrency)
		packSize = try container.decodeIfPresent(Int.self, forKey: .packSize)
		
		uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID()
		profileVersion = try container.decodeIfPresent(Int.self, forKey: .profileVersion) ?? 1
	}
	
	static func == (lhs: Profile, rhs: Profile) -> Bool {
		return lhs.uuid == rhs.uuid &&
			lhs.name == rhs.name &&
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
			lhs.packSize == rhs.packSize &&
			lhs.tags == rhs.tags
	}
	
	func addPath(_ path: String) {
		if !paths.contains(path) {
			paths.append(path)
		}
	}
	
}





/// Repository class.
final class Repo: Codable {
	var name: String?
	var path: String
	var cachedPassword: String?
	var cacheDir: String?
	var env: [String : String]?
	
	init(path: String, password: String) throws {
		self.path = path
		self.cachedPassword = password
		try KeychainInterface.add(path: path, password: password)
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
	
	func getPassword() throws(KeychainInterface.KeychainError) -> String {
		guard cachedPassword == nil else {
			return cachedPassword!
		}
		cachedPassword = try KeychainInterface.load(path: path)
		return cachedPassword!
	}
	
	/// Sets the password without adding it to the keychain.
	/// - Parameter newPass: The updated password.
	func setPassword(_ newPass: String) {
		cachedPassword = newPass
	}
	
	/// Sets the password and adds it to the keychain.
	/// - Parameter newPass: The updated password.
	func saveNewPassword(newPass: String) throws(KeychainInterface.KeychainError) {
		try KeychainInterface.add(path: path, password: newPass)
		cachedPassword = newPass
	}
	
	/// Sets the password and updates the keychain.
	/// - Parameter newPass: The updated password.
	func updatePassword(newPass: String) throws(KeychainInterface.KeychainError) {
		try KeychainInterface.updateOrAdd(path: path, password: newPass)
		cachedPassword = newPass
	}
	
	/// Updates the path and keychain.
	/// - Parameter newPath: The updated path.
	func updatePath(newPath: String) throws(KeychainInterface.KeychainError) {
		try KeychainInterface.update(path: newPath)
		path = newPath
	}
	
	func selfDeletePassword() throws(KeychainInterface.KeychainError) {
		// TODO: implement
	}
	
	/// Gets the "nickname" or the path.
	/// - Returns: The name to use in menus.
	func getName() -> String {
		return name ?? path
	}
	
	/// Returns a repo-configured env dictionary with password.
	func getEnv() throws(KeychainInterface.KeychainError) -> [String : String] {
		var newEnv = env ?? [String : String]()
		newEnv["HOME"] = ProcessInfo.processInfo.environment["HOME"]
		newEnv["RESTIC_PASSWORD"] = try getPassword()
		if let cd = cacheDir {
			newEnv["RESTIC_CACHE_DIR"] = cd
		}
		return newEnv
	}
	
	var id: String?
	/// Sets & returns the repository's ID, if it can.
	func loadID() -> String? {
		if id == nil {
			id = try? ResticController.default.run(args: ["--json", "-r", path, "cat", "config"], env: getEnv(), returning: ResticResponse.RepoConfig.self).0.id
			if id != nil {
				try? ReposManager.default.save()
			}
		}
		return id
	}

}
