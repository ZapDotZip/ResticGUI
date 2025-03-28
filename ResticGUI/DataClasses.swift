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
	
	/// Gets the "nickname" or the path.
	/// - Returns: The name to use in menus.
	func getName() -> String {
		return name ?? path
	}
	
	/// Returns a repo-configured env dictionary with password.
	func getEnv() -> [String : String] {
		var newEnv = env ?? [String : String]()
		newEnv["HOME"] = ProcessInfo.processInfo.environment["HOME"]
		newEnv["RESTIC_PASSWORD"] = password
		if let cd = cacheDir {
			newEnv["RESTIC_CACHE_DIR"] = cd
		}
		return newEnv
	}
	
	var id: String?
	/// Sets & returns the repository's ID, if it can.
	func loadID() -> String? {
		if id == nil {
			id = try? ResticController.default.run(args: ["--json", "-r", path, "cat", "config"], env: getEnv(), returning: repoConfig.self).0.id
			if id != nil {
				ReposManager.default.save()
			}
		}
		return id
	}

}

final class Snapshot: Codable {
	let time: String
	let parent: String?
	let tree: String
	let paths: [String]
	let hostname: String
	let username: String
	let uid: Int
	let gid: Int
	let tags: [String]?
	let program_version: String
	let summary: backupSummary
	let id: String
	let short_id: String
	
	var date: Date {
		let df = DateFormatter()
		df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
		return df.date(from: time) ?? Date.init(timeIntervalSince1970: 0)
	}
}

struct backupProgress: Decodable {
	let message_type: String
	let percent_done: Double
	let files_done: Int?
	let bytes_done: Int?
	let seconds_elapsed: Int?
	let total_files: Int?
	let total_bytes: Int?
	let seconds_remaining: Int?
	let error_count: Int?
	let current_files: [String]?
}

struct backupError: Decodable {
	let message_type: String
	let error: backupErrorMessage
	let during: String?
	let item: String?
}
struct backupErrorMessage: Decodable {
	let message: String?
}

struct backupSummary: Codable {
	let message_type: String?
	let files_new: Int
	let files_changed: Int
	let files_unmodified: Int
	let dirs_new: Int
	let dirs_changed: Int
	let dirs_unmodified: Int
	let data_blobs: Int
	let tree_blobs: Int
	let data_added: Int
	let data_added_packed: Int
	let total_files_processed: Int
	let total_bytes_processed: Int
	let total_duration: Double?
	let snapshot_id: String?
}

struct repoConfig: Codable {
	let version: Int
	let id: String
	let chunker_polynomial: String
}
