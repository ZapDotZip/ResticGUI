//
//  BackupController.swift
//  ResticGUI
//

import Foundation

class BackupController {
	
	let rc: ResticController
	let vc: ViewController
	var errOut: Data
	var didRecieveErrors = false
	var backupInProgress = false
	var lastBackupSummary: backupSummary?
	
	init(resticController: ResticController, viewController: ViewController) {
		rc = resticController
		vc = viewController
		errOut = Data()
	}
	
	func backup(profile: Profile, repo: Repo) {
		backupInProgress = true
		rc.dq.async {
			// setup
			var args: [String] = ["--json", "-r", repo.path, "backup", "--tag", profile.name]
			for i in profile.tags {
				args.append(contentsOf: ["--tag", i])
			}
			
			args.append(contentsOf: profile.paths)
			var env = repo.env ?? [String : String]()
			env["HOME"] = ProcessInfo.processInfo.environment["HOME"]
			env["RESTIC_PASSWORD"] = repo.password
			let globalExlcusions = UserDefaults.standard.string(forKey: "GlobalExclusions")
			do {
				if let exclusions = profile.exclusions {
					let exclusionsFile = FileManager.default.temporaryDirectory.appendingPathComponent("restic-exclusions-\(profile.name).txt")
					try exclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
					if profile.exclusionsCS {
						args.append("--exclude-file=\(exclusionsFile.path)")
					} else {
						args.append("--iexclude-file=\(exclusionsFile.path)")
					}
				}
				if let exclusions = globalExlcusions {
					let exclusionsFile = FileManager.default.temporaryDirectory.appendingPathComponent("restic-exclusions-global.txt")
					try exclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
					if UserDefaults.standard.bool(forKey: "GlobalExclusionsCaseSensitive") {
						args.append("--exclude-file=\(exclusionsFile.path)")
					} else {
						args.append("--iexclude-file=\(exclusionsFile.path)")
					}
				}
			} catch {
				DispatchQueue.main.sync {
					let res = Alert(title: "An error occured trying to create the exclusions file.", message: "Couldn't create the exclusions file.\n\n\(error.localizedDescription)", style: .critical, buttons: ["Continue Anyways", "Cancel"])
					if res == .alertSecondButtonReturn {
						return // cancel
					}
				}
			}
			
			
			
			// run
			do {
				try self.rc.launch(args: args, env: env, stdoutHandler: self.progressHandler(_:), stderrHandler: self.stderrHandler(_:), terminationHandler: self.terminationHandler(_:))
			} catch {
				NSLog(error.localizedDescription)
			}
		}
	}
	
	func progressHandler(_ data: Data) {
		if let progress = try? rc.jsonDecoder.decode(backupProgress.self, from: data) {
			DispatchQueue.main.async {
				self.vc.displayProgress(progress.current_files?.first, progress.percent_done)
			}
		} else if let error = try? rc.jsonDecoder.decode(backupError.self, from: data) {
			print(error.message_type)
			Alert(title: "An error occured while backing up.", message: "Restic:\n\n\(getStderr())", style: .critical, buttons: ["Ok"])
		} else if let summary = try? rc.jsonDecoder.decode(backupSummary.self, from: data) {
			var sum: String = ""
			dump(summary, to: &sum)
			ResticLogger.default.log(sum)
			lastBackupSummary = summary
		} else {
			let str: String = String(data: data, encoding: .utf8) ?? "Error decoding output."
			let errMsg: String = {
				if str.count != 0 {
					ResticLogger.default.stdout(str)
					return str
				} else {
					return getStderr()
				}
			}()
			DispatchQueue.main.async {
				Alert(title: "An unkown error occured trying to back up.", message: "Recieved this error from restic:\n\n\(errMsg)", style: .critical, buttons: ["Ok"])
			}
		}
	}
	
	func stderrHandler(_ data: Data) {
		errOut.append(data)
		didRecieveErrors = true
	}
	
	func getStderr() -> String {
		return String.init(data: errOut, encoding: .utf8) ?? "Error decoding output."
	}
	
	func terminationHandler(_ exitCode: Int32) {
		DispatchQueue.main.async {
			self.vc.completedBackup(self.lastBackupSummary)
		}
		backupInProgress = false
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

struct backupSummary: Decodable {
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
	let total_duration: Double
	let snapshot_id: String
}
