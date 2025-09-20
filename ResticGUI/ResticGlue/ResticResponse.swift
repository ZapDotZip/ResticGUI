//
//  ResticResponse.swift
//  ResticGUI
//

import Foundation

final class ResticResponse {
	private static let bcf = ByteCountFormatter.init()
	private static let dcf = DateComponentsFormatter()
	private static let df = {
		let df = DateFormatter()
		df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
		return df
	}()
	
	
	struct Version: Decodable, Equatable {
		let version: String
		let go_arch: String
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
		
		lazy var date: Date = {
			let d = ResticResponse.df.date(from: time)
			if d == nil {
				RGLogger.default.log("Unable to convert restic-provided date: \(time)")
			}
			return d ?? Date.init(timeIntervalSince1970: 0)
		}()
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
	
	struct error: Decodable {
		let message_type: String
		let error: resticErrorMessage?
		let during: String?
		let item: String?
		let code: Int?
		let message: String?
		func getMessage() -> String? {
			return message ?? error?.message
		}
	}
	
	struct resticErrorMessage: Decodable {
		let message: String?
	}
	
	struct backupSummary: Codable, RGIRSummary {
		let message_type: String
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
	
	struct RestoreProgress: Decodable, RGIRSummary {
		let message_type: String
		let seconds_elapsed: Int?
		let percent_done: Double? // nil if backup complete
		let total_files: Int?
		let files_restored: Int?
		let files_skipped: Int?
		let files_deleted: Int?
		let total_bytes: Int64?
		let bytes_restored: Int64?
		let bytes_skipped: Int?
		
		private func bcfOrNil(_ val: Int64?) -> String {
			guard let val else { return "???" }
			return bcf.string(fromByteCount: val)
		}
		
		private func numOrNil(_ val: Int?) -> String {
			guard let val else { return "???" }
			return "\(val)"
		}
		
		func progressReport() -> String {
			return """
				\(bcf.string(fromByteCount: bytes_restored ?? 0))/\(bcfOrNil(total_bytes)) restored
				\(files_restored ?? 0)/\(numOrNil(total_files)) files restored
				\(numOrNil(seconds_elapsed)) seconds elapsed
			"""
		}
		
		func summaryReport() -> String {
			return "Restored \(numOrNil(total_files)) files, \(bcfOrNil(total_bytes)) in \(dcf.string(from: TimeInterval(seconds_elapsed ?? 0)) ?? "\(seconds_elapsed ?? 0) seconds")"
		}
		
	}
	
}
