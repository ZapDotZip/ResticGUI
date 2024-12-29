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
	
	func backup(profile: Profile, repo: Repo, scanAhead: Bool = true) {
		backupInProgress = true
		rc.dq.async {
			// setup
			var args: [String] = ["--json", "-r", repo.path, "backup", "--tag", profile.name]
			for i in profile.tags {
				args.append(contentsOf: ["--tag", i])
			}
			if !scanAhead {
				args.append("--no-scan")
			}
			
			args.append(contentsOf: profile.paths)
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
				if let exclusions = UserDefaults.standard.string(forKey: "GlobalExclusions") {
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
			
			if let epf = profile.excludePatternFile {
				if profile.excludePatternFileCS {
					args.append("--exclude-file=\(epf)")
				} else {
					args.append("--iexclude-file=\(epf)")
				}
			}
			
			if profile.excludeCacheDirs {
				args.append("--exclude-caches=true")
			}
			
			if let compression = profile.compression {
				args.append("--compression=\(compression)")
			}
			
			if let readConcurrency = profile.readConcurrency {
				args.append("--read-concurrency=\(readConcurrency)")
			}
			
			if let packSize = profile.packSize {
				args.append("--pack-size=\(packSize)")
			}
			
			if let excludeMaxFilesize = profile.excludeMaxFilesize {
				args.append("--exclude-larger-than=\(excludeMaxFilesize)")
			}
			
			// run
			do {
				try self.rc.launch(args: args, env: repo.getEnv(), stdoutHandler: self.progressHandler(_:), stderrHandler: self.stderrHandler(_:), terminationHandler: self.terminationHandler(_:))
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
	
	func cancel() {
		if let p = rc.currentlyRunningProcess {
			p.interrupt()
		}
	}
	
	var isSuspended = false
	func pause() -> Bool {
		if !isSuspended, let p = rc.currentlyRunningProcess {
			isSuspended = p.suspend()
		}
		return isSuspended
	}
	func resume() -> Bool {
		if isSuspended, let p = rc.currentlyRunningProcess {
			isSuspended = !p.resume()
		}
		return !isSuspended
	}
}
