//
//  ResticResponse.swift
//  ResticGUI
//

import Foundation

final class ResticResponse {
	
	struct ResticVersion: Decodable, Equatable {
		let version: String
		let go_arch: String
	}
	
	final class Snapshot: Codable {
		private static let df = {
			let df = DateFormatter()
			df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
			return df
		}()
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
		
		lazy var date: Date = ResticResponse.Snapshot.df.date(from: time) ?? Date.init(timeIntervalSince1970: 0)
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
	
	struct RepoConfig: Codable {
		let version: Int
		let id: String
		let chunker_polynomial: String
	}
	
	struct RepoInitResponse: Decodable {
		let message_type: String
		let id: String
		let repository: String
	}
	
}
