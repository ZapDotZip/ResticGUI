//
//  ResticController.swift
//  ResticGUI
//

import Foundation


class ResticController: NSObject {
	#if arch(x86_64)
	static let supportedRV = resticVersion.init(version: "0.17.1", go_arch: "amd64")
	#elseif arch(arm64)
	static let supportedRV = resticVersion.init(version: "0.17.1", go_arch: "arm64")
	#endif
	static let autoURLs = [
		URL(fileURLWithPath: "/opt/local/bin/restic"),
		URL(fileURLWithPath: "/opt/homebrew/bin/restic"),
		URL(fileURLWithPath: "/usr/local/bin/restic")
	]
	
	/// The DispatchQueue that all Restic operations must be run from.
	var dq: DispatchQueue
	var resticLocation: URL?
	var versionInfo: resticVersion?

	override init() {
		dq = DispatchQueue.init(label: "ResticController", qos: .utility, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		super.init()
	}
	
	/// Configures ResticController based off of the user's preferences. Throws an error if Restic couldn't be found/run.
	func setupFromDefaults() throws {
		if let userSel = UserDefaults.standard.string(forKey: PreferencesViewController.resticPathPrefName) {
			NSLog("User configured default \(userSel)")
			if userSel == "MacPorts" {
				return try testVersion(ResticController.autoURLs[0])
			} else if userSel == "Homebrew" {
				return try homebrew()
			} else if userSel != "Automatic" {
				return try testVersion(URL(fileURLWithPath: userSel))
			}
		}
		return try automatic()
	}
	
	/// Tests to see if the path points to a valid Restic binary by checking its version.
	/// - Parameter path: The path to restic to set for the object.
	func testVersion(_ path: URL) throws {
		resticLocation = path
		let vers = try run(args: ["--json", "version"], returning: resticVersion.self)
		versionInfo = vers
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
		for u in ResticController.autoURLs[1...ResticController.autoURLs.count] {
			resticLocation = u
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		throw ResticError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic from Homebrew.")
	}
	
	
	/// Runs restic with the provided arguments and returns the output as raw data.
	/// - Parameter args: The list of arguments to use.
	func run(args: [String]) throws -> Data {
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
		
		try proc.run()
		//NSLog("ResticController: Restic stderr: \(stderr.fileHandleForReading.readDataToEndOfFile())")
		return stdout.fileHandleForReading.readDataToEndOfFile()
	}
	
	/// Runs restic with the provided arguments and returns the output as the provided Decodable class.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object to return.
	func run<T: Decodable>(args: [String], returning: T.Type) throws -> T {
		let data: Data = try run(args: args)
		let obj = try JSONDecoder().decode(T.self, from: data)
		return obj
	}
	
	/// Runs restic with the provided arguments and returns the output as a string.
	/// - Parameter args: The list of arguments to use.
	func run(args: [String]) throws -> String {
		let data: Data = try run(args: args)
		if let output = String.init(data: data, encoding: .utf8) {
			return output
		} else {
			throw ResticError.couldNotDecodeStringOutput
		}
	}

	
}

struct resticVersion: Decodable, Equatable {
	let version: String
	let go_arch: String
}


enum ResticError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON
	case noResticInstallationsFound(String)
}
