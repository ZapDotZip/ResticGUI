//
//  ResticController.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController


final class ResticController: NSObject {
	#if arch(x86_64)
	static let supportedRV = ResticResponse.Version.init(version: "0.18.0", go_arch: "amd64")
	#elseif arch(arm64)
	static let supportedRV = ResticResponse.Version.init(version: "0.18.0", go_arch: "arm64")
	#endif
	static let autoURLs = [
		URL(localPath: "/opt/local/bin/restic"),
		URL(localPath: "/opt/homebrew/bin/restic"),
		URL(localPath: "/usr/local/bin/restic")
	]
// MARK: Setup
	let dq: DispatchQueue
	let jsonDecoder = JSONDecoder()
	var resticLocation: URL?
	var versionInfo: ResticResponse.Version?
	
	static var `default` = ResticController()
	private override init() {
		dq = DispatchQueue.init(label: "zap.zip.ResticGUI.ResticController", qos: .background)
		super.init()
		UserDefaults.standard.addObserver(self, forKeyPath: DefaultsKeys.resticLocation, options: .new, context: nil)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == DefaultsKeys.resticLocation {
			dq.async(qos: .background) {
				try? self.setupFromDefaults()
			}
		}
	}
	
	/// Configures ResticController based off of the user's preferences. Throws an error if Restic couldn't be found/run.
	func setupFromDefaults() throws {
		resticLocation = nil
		versionInfo = nil
		guard let userSel = UserDefaults.standard.string(forKey: DefaultsKeys.resticLocation) else {
			return try automatic()
		}
		switch userSel {
			case "MacPorts":
				return try testVersion(ResticController.autoURLs[0])
			case "Homebrew":
				return try homebrew()
			case "Automatic":
				return try automatic()
			default:
				return try testVersion(URL(localPathExpandingTilde: userSel))
		}
	}
	
	/// Tests to see if the path points to a valid Restic binary by checking its version.
	/// - Parameter path: The path to restic, will be set if the command runs successfully.
	func testVersion(_ path: URL) throws {
		let result = try SPCRunner(executableURL: path).run(args: ["--json", "version"], returning: ResticResponse.Version.self, decodingWith: .JSON)
		switch result.output {
			case .object(let output):
				versionInfo = output
				resticLocation = path
			case .error(let rawData, let decodingError):
				throw RGError(decodingError: decodingError, rawData: rawData, stderr: result.stdErrorString(), exitCode: result.exitStatus)
		}
		
	}
	
	/// Finds a restic install automatically. Prefers MacPorts over Homebrew and arm over x64.
	private func automatic() throws {
		for u in ResticController.autoURLs {
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		RGLogger.default.log("ResticController: Could not find a valid restic installation automatically.")
		throw RGError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic on your computer.")
	}
		
	private func homebrew() throws {
		for u in ResticController.autoURLs[1...] {
			resticLocation = u
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		throw RGError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic from Homebrew.")
	}
	
	func getVersionInfo() throws -> ResticResponse.Version {
		if versionInfo == nil {
			try setupFromDefaults()
		}
		return versionInfo!
	}
	
	func getResticURL() throws -> URL {
		if let resticLocation {
			return resticLocation
		} else {
			try setupFromDefaults()
			return resticLocation!
		}
	}
	
	func run<D: Decodable>(args: [String], env: [String : String], returning: D.Type, qos: QualityOfService = .userInitiated) throws -> D {
		let restic = SPCRunner(executableURL: try getResticURL())
		restic.env = env
		restic.qualityOfService = qos
		let result = try restic.run(args: args, returning: D.self, decodingWith: .JSON)
		switch result.output {
			case .object(let output):
				return output
			case .error(let rawData, let decodingError):
				throw RGError(decodingError: decodingError, rawData: rawData, stderr: result.stdErrorString(), exitCode: result.exitStatus)
		}
	}
	
	func create(repo: Repo) throws -> ResticResponse.RepoInitResponse {
		return try run(args: ["--json", "-r", repo.path, "init"], env: try repo.getEnv(), returning: ResticResponse.RepoInitResponse.self)
	}
	
	func getConfig(of repo: Repo) throws -> ResticResponse.RepoConfig {
		return try run(args: ["--json", "-r", repo.path, "cat", "config"], env: try repo.getEnv(), returning: ResticResponse.RepoConfig.self)
	}
	
	func getSnapshots(for repo: Repo) throws -> [ResticResponse.Snapshot] {
		return try run(args: ["-r", repo.path, "snapshots", "--json"], env: try repo.getEnv(), returning: [ResticResponse.Snapshot].self)
	}
	
}
