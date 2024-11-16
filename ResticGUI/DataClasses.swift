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
			lhs.packSize == rhs.packSize &&
			lhs.tags == rhs.tags
	}
	
	func addPath(_ path: String) {
		// TODO: Check if path already exists.
		paths.append(path)
	}
	
}





final class Repo: Codable {
	var name: String?
	var path: String
	var password: String
	var cacheDir: String?
	var env: [String : String]?
	init(path: String, password: String) {
		self.path = path
		self.password = password
	}
	
	/// Returns an env dictionary with password.
	func getEnv() -> [String : String] {
		var newEnv = env ?? [String : String]()
		newEnv["HOME"] = ProcessInfo.processInfo.environment["HOME"]
		newEnv["RESTIC_PASSWORD"] = password
		return newEnv
	}

}

final class Snapshot: Codable {
	let time: Date
	let parent: String
	let tree: String
	let paths: [String]
	let hostname: String
	let username: String
	let uid: Int
	let gid: Int
	let tags: [String]
	let program_version: String
	let summary: backupSummary
	let id: String
	let short_id: String
}
