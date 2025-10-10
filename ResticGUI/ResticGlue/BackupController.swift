//
//  BackupController.swift
//  ResticGUI
//

import Foundation
import SwiftToolbox
import SwiftProcessController

class BackupController: InteractiveResticBase<ResticResponse.backupProgress, ResticResponse.backupSummary>, SPCDecoderDelegate {
	
	private var errOut = Data()
	
	private var QoS: QualityOfService {
		get {
			if #available(macOS 12.0, *) {
				if ProcessInfo.processInfo.isLowPowerModeEnabled && UserDefaults.standard.bool(forKey: DefaultsKeys.lowPowerQoS) {
					return .background
				}
			}
			if STBMachine.isOnBattery() && UserDefaults.standard.bool(forKey: DefaultsKeys.batteryQoS) {
				return .background
			}
			if let pref = UserDefaults.standard.string(forKey: DefaultsKeys.backupQoS) {
				switch pref {
				case "userInitiated": return .userInitiated
				case "utility": return .utility
				case "background": return .background
				default: return .default
				}
			}
			return .default
		}
	}
	
	private func arguments(from profile: Profile, and repo: Repo, scanAhead: Bool) throws -> [String] {
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
				exclusions.append(try self.getTMUserExclusions().joined(separator: "\n"))
			}
			if profile.excludesTMDefault {
				exclusions.append(self.getTMDefaultTMExclusions().joined(separator: "\n"))
			}
			if exclusions.count != 0 {
				let exclusionsFile = FileManager.default.temporaryDirectory.appending(path: "restic-exclusions-\(profile.name).txt")
				try exclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
				if profile.exclusionsCS {
					args.append("--exclude-file=\(exclusionsFile.path)")
				} else {
					args.append("--iexclude-file=\(exclusionsFile.path)")
				}
			}
			if let globalExclusions = UserDefaults.standard.string(forKey: DefaultsKeys.globalExclusions) {
				let exclusionsFile = FileManager.default.temporaryDirectory.appending(path: "restic-exclusions-global.txt")
				try globalExclusions.write(to: exclusionsFile, atomically: true, encoding: .utf8)
				if UserDefaults.standard.bool(forKey: DefaultsKeys.isGlobalExclusionsCaseSensitive) {
					args.append("--exclude-file=\(exclusionsFile.path)")
				} else {
					args.append("--iexclude-file=\(exclusionsFile.path)")
				}
			}
		} catch {
			NSLog("Error creating exclusion file: \(error)")
			throw RGError(from: error, message: "An error occured trying to create the exclusions file")
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
			if QoS == .background && UserDefaults.standard.bool(forKey: DefaultsKeys.limitBackgroundCoreCount), let eCores = STBMachine.getDifferentialCoreCount()?.0, eCores < readConcurrency {
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
		return args
	}
	
	func backup(profile: Profile, repo: Repo, scanAhead: Bool = true) throws {
		willStart()
		do {
			let args = try arguments(from: profile, and: repo, scanAhead: scanAhead)
			let p = try SPCControllerDecoder(executableURL: ResticController.default.getResticURL(), delegate: self, decoderType: .JSON)
			p.env = try repo.getEnv()
			RGLogger.default.run(process: p, args: args)
			p.qualityOfService = QoS
			try p.launch(args: args)
			process = p
		} catch {
			NSLog("Failed to start backup: \(error)")
			throw error
		}
	}
	
	func stdoutHandler(_ output: SwiftProcessController.SPCDecodedResult<ResticResponse.backupProgress>) {
		switch output {
			case .object(let progress):
				self.display.updateProgress(to: progress.percent_done, infoText: progress.current_files?.first)
			case .error(let rawData, _):
				if let newSummary = try? AppDelegate.jsonDecoder.decode(ResticResponse.backupSummary.self, from: rawData) {
					summary = newSummary
				} else if let error = try? AppDelegate.jsonDecoder.decode(ResticResponse.error.self, from: rawData) {
					DispatchQueue.main.async {
						STBAlerts.alert(title: "An error occured while backing up.", message: nil, error: error as! Error)
					}
				} else {
					let errMsg: String = {
						let str: String = String(data: rawData, encoding: .utf8) ?? "Error decoding output."
						if str.count != 0 {
							RGLogger.default.stdout(str)
							return str
						} else {
							return getStderr()
						}
					}()
					DispatchQueue.main.async {
						STBAlerts.alert(title: "An unkown error occured trying to back up.", message: "Recieved this error from restic:\n\n\(errMsg)", style: .critical)
					}
				}
		}
	}
	
	func getStderr() -> String {
		return String.init(data: errOut, encoding: .utf8) ?? "Error decoding output."
	}
	
	override func terminationHandler(exitCode: Int32) {
		process = nil
		if let summary {
			var sum: String = ""
			dump(summary, to: &sum)
			RGLogger.default.log(sum)
		} else {
			RGLogger.default.log("No summary available.")
		}
		DispatchQueue.main.async {
			self.display.finish(summary: self.summary, with: nil)
		}
	}
	
	private struct TMPrefs: Decodable {
		let ExcludeByPath: [String]
		let SkipPaths: [String]
	}
	private let decoder = PropertyListDecoder.init()
	private func getTMUserExclusions() throws -> [String] {
		do {
			let tmPrefs = try decoder.decode(TMPrefs.self, from: Data.init(contentsOf: URL(localPath: "/Library/Preferences/com.apple.TimeMachine.plist")))
			return tmPrefs.ExcludeByPath + tmPrefs.SkipPaths
		} catch {
			NSLog("Error getting TM User Exclusions: \(error)")
			throw RGError(from: error, message: "Could not load Time Machine User Exclusions.")
		}
	}
	
	private struct TMDefault: Decodable {
		let standardExclusionPaths: [String]
	}
	private func getTMDefaultTMExclusions() -> [String] {
		do {
			if let plist = Bundle.main.path(forResource: "DefaultTimeMachineExclusions", ofType: "plist") {
				let tmexcl = try decoder.decode(TMDefault.self, from: Data.init(contentsOf: URL(localPath: plist)))
				return tmexcl.standardExclusionPaths
			}
		} catch {
			NSLog("Error getting TM User Exclusions: \(error)")
		}
		return []
	}
	
}
