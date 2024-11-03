//
//  ResticController.swift
//  ResticGUI
//

import Foundation


final class ResticController: NSObject {
	#if arch(x86_64)
	static let supportedRV = ResticVersion.init(version: "0.17.1", go_arch: "amd64")
	#elseif arch(arm64)
	static let supportedRV = ResticVersion.init(version: "0.17.1", go_arch: "arm64")
	#endif
	static let autoURLs = [
		URL(fileURLWithPath: "/opt/local/bin/restic"),
		URL(fileURLWithPath: "/opt/homebrew/bin/restic"),
		URL(fileURLWithPath: "/usr/local/bin/restic")
	]
	
	/// The DispatchQueue that all Restic operations must be run from.
	let dq: DispatchQueue
	lazy var logger: ResticLogger = ResticLogger.init()
	var resticLocation: URL?
	var versionInfo: ResticVersion?

	override init() {
		dq = DispatchQueue.init(label: "ResticController", qos: .utility, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		super.init()
	}
	
	/// Configures ResticController based off of the user's preferences. Throws an error if Restic couldn't be found/run.
	func setupFromDefaults() throws {
		if let userSel = UserDefaults.standard.string(forKey: PrefTabGeneral.resticPathPrefName) {
			NSLog("User configured default \(userSel)")
			if userSel == "MacPorts" {
				return try testVersion(ResticController.autoURLs[0])
			} else if userSel == "Homebrew" {
				return try homebrew()
			} else if userSel != "Automatic" {
				return try testVersion(URL(fileURLWithPath: (userSel as NSString).expandingTildeInPath))
			}
		}
		return try automatic()
	}
	
	/// Tests to see if the path points to a valid Restic binary by checking its version.
	/// - Parameter path: The path to restic to set for the object.
	func testVersion(_ path: URL) throws {
		resticLocation = path
		let vers = try run(args: ["--json", "version"], env: nil, returning: ResticVersion.self)
		(versionInfo, _) = vers
		NSLog("ResticController: Successfully initialized \(path) with version \(versionInfo!)")
	}
	
	/// Finds a restic install automatically. Prefers MacPorts over Homebrew and arm over x64.
	func automatic() throws {
		for u in ResticController.autoURLs {
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		NSLog("ResticController: Could not find a valid restic installation automatically.")
		throw ResticError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic on your computer.")
	}
		
	func homebrew() throws {
		for u in ResticController.autoURLs[1...ResticController.autoURLs.count-1] {
			resticLocation = u
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		throw ResticError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic from Homebrew.")
	}
	
	func getVersionInfo() throws -> ResticVersion {
		if versionInfo == nil {
			try setupFromDefaults()
		}
		return versionInfo!
	}
	
	
	/// Runs restic with the provided arguments and returns the output  as raw data and stderr as a String, if any.
	/// - Parameter args: The list of arguments to use.
	func run(args: [String], env: [String : String]?) throws -> (Data, String?) {
		if resticLocation == nil {
			do {
				try setupFromDefaults()
			} catch {
				resticLocation = nil
				throw error
			}
		}
		
		let proc = Process()
		let stdout = Pipe()
		let stderr = Pipe()
		proc.executableURL = resticLocation
		proc.standardOutput = stdout
		proc.standardError = stderr
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		logger.runCmd(path: resticLocation!, args: args)
		
		try proc.run()
		let stderrStr: String? = String.init(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
		logger.stderr(stderrStr)
		return (stdout.fileHandleForReading.readDataToEndOfFile(), stderrStr)
	}
	
	/// Runs restic with the provided arguments and returns the output as the provided Decodable class.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object to return.
	func run<T: Decodable>(args: [String], env: [String : String]?, returning: T.Type) throws -> (T, String?) {
		let (data, stderr): (Data, String?) = try run(args: args, env: env)
		do {
			let obj = try JSONDecoder().decode(T.self, from: data)
			return (obj, stderr)
		} catch let error as DecodingError {
			let rawStr: String = String.init(data: data, encoding: .utf8) ?? "Could not convert data to a string."
			logger.stdout(rawStr)
			NSLog("Error: \(error)")
			throw ResticError.couldNotDecodeJSON(rawStr, stderr ?? "Could not decode Restic error output.")
		} catch {
			logger.stdout(String.init(data: data, encoding: .utf8) ?? "Could not convert data to a string.")
			NSLog("Error: \(error)")
			throw error
		}
	}
	
	/// Runs restic with the provided arguments and returns the output as a string.
	/// - Parameter args: The list of arguments to use.
	func run(args: [String], env: [String : String]?) throws -> (String, String?) {
		NSLog("Running restic with args: \(args)")
		let (data, stderr): (Data, String?) = try run(args: args, env: env)
		if let output = String.init(data: data, encoding: .utf8) {
			return (output, stderr)
		} else {
			throw ResticError.couldNotDecodeStringOutput
		}
	}

	
}

struct ResticVersion: Decodable, Equatable {
	let version: String
	let go_arch: String
}


enum ResticError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON(String, String)
	case noResticInstallationsFound(String)
}
