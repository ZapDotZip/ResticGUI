//
//  Profile.swift
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
	
	static func decodeFrom(_ url: URL) throws -> Self {
		return try AppDelegate.plistDecoder.decode(Self.self, from: .init(contentsOf: url))
	}
	
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

struct ExportedProfile: Codable {
	let profile: Profile
	let repo: Repo
	
	static func decodeFrom(_ url: URL) throws -> Self {
		return try AppDelegate.plistDecoder.decode(Self.self, from: .init(contentsOf: url))
	}
}
