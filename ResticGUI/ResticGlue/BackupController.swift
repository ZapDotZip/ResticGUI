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
	var lastBackupSummary: ResticResponse.backupSummary?
	
	init(resticController: ResticController, viewController: ViewController) {
		rc = resticController
		vc = viewController
		errOut = Data()
	}
	
	private func getQoS() -> QualityOfService {
		var qos: QualityOfService = .default
		if let pref = UserDefaults.standard.string(forKey: "Backup QoS") {
			if pref == "userInitiated" {
				qos = .userInitiated
			} else if pref == "utility" {
				qos = .utility
			} else if pref == "background" {
				qos = .background
			}
		}
		if #available(macOS 12.0, *) {
			if UserDefaults.standard.bool(forKey: "QoS Background on Low Power") && ProcessInfo.processInfo.isLowPowerModeEnabled {
				qos = .background
			}
		}
		if UserDefaults.standard.bool(forKey: "QoS Background on Battery") && isOnBattery() {
			qos = .background
		}
		return qos
	}
	
	func backup(profile: Profile, repo: Repo, scanAhead: Bool = true) {
		backupInProgress = true
		rc.dq.async {
			let qos = self.getQoS()
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
				var exclusions = ""
				if let e = profile.exclusions {
					exclusions.append(e)
				}
				if profile.excludesTMUser {
					exclusions.append(self.getTMUserExclusions().joined(separator: "\n"))
				}
				if profile.excludesTMDefault {
					exclusions.append(self.getTMDefaultTMExclusions().joined(separator: "\n"))
				}
				if exclusions.count != 0 {
					let exclusionsFile = FileManager.default.temporaryDirectory.appendingPathComponent("restic-exclusions-\(profile.name).txt")
					try exclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
					if profile.exclusionsCS {
						args.append("--exclude-file=\(exclusionsFile.path)")
					} else {
						args.append("--iexclude-file=\(exclusionsFile.path)")
					}
				}
				if let globalExclusions = UserDefaults.standard.string(forKey: "GlobalExclusions") {
					let exclusionsFile = FileManager.default.temporaryDirectory.appendingPathComponent("restic-exclusions-global.txt")
					try globalExclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
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
				if qos == .background && UserDefaults.standard.bool(forKey: "Limit Background Core Count"), let eCores = getDifferentialCoreCount()?.0, eCores < readConcurrency {
					args.append("--read-concurrency=\(eCores)")
				} else {
					args.append("--read-concurrency=\(readConcurrency)")
				}
			}
			
			if let packSize = profile.packSize {
				args.append("--pack-size=\(packSize)")
			}
			
			if let excludeMaxFilesize = profile.excludeMaxFilesize {
				args.append("--exclude-larger-than=\(excludeMaxFilesize)")
			}
			
			do {
				try self.rc.launch(args: args, env: repo.getEnv(), stdoutHandler: self.progressHandler(_:), stderrHandler: self.stderrHandler(_:), terminationHandler: self.terminationHandler(_:), qos: qos)
			} catch {
				NSLog(error.localizedDescription)
			}
		}
	}
	
	func progressHandler(_ data: Data) {
		if let progress = try? rc.jsonDecoder.decode(ResticResponse.backupProgress.self, from: data) {
			DispatchQueue.main.async {
				self.vc.displayProgress(progress.current_files?.first, progress.percent_done)
			}
		} else if let error = try? rc.jsonDecoder.decode(ResticResponse.backupError.self, from: data) {
			print(error.message_type)
			Alert(title: "An error occured while backing up.", message: "Restic:\n\n\(getStderr())", style: .critical, buttons: ["Ok"])
		} else if let summary = try? rc.jsonDecoder.decode(ResticResponse.backupSummary.self, from: data) {
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
	
	private struct TMPrefs: Decodable {
		let ExcludeByPath: [String]
		let SkipPaths: [String]
	}
	private let decoder = PropertyListDecoder.init()
	private func getTMUserExclusions() -> [String] {
		do {
			let tmPrefs = try decoder.decode(TMPrefs.self, from: Data.init(contentsOf: URL(fileURLWithPath: "/Library/Preferences/com.apple.TimeMachine.plist")))
			return tmPrefs.ExcludeByPath + tmPrefs.SkipPaths
		} catch {
			NSLog("Error getting TM User Exclusions: \(error)")
		}
		return []
	}
	
	private struct TMDefault: Decodable {
		let standardExclusionPaths: [String]
	}
	private func getTMDefaultTMExclusions() -> [String] {
		do {
			if let plist = Bundle.main.path(forResource: "DefaultTimeMachineExclusions", ofType: "plist") {
				let tmexcl = try decoder.decode(TMDefault.self, from: Data.init(contentsOf: URL(fileURLWithPath: plist)))
				return tmexcl.standardExclusionPaths
			}
		} catch {
			NSLog("Error getting TM User Exclusions: \(error)")
		}
		return []
	}
	
}
