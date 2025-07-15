//
//  ResticController.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController


final class ResticController: NSObject {
	#if arch(x86_64)
	static let supportedRV = ResticResponse.ResticVersion.init(version: "0.18.0", go_arch: "amd64")
	#elseif arch(arm64)
	static let supportedRV = ResticResponse.ResticVersion.init(version: "0.18.0", go_arch: "arm64")
	#endif
	static let autoURLs = [
		URL(localPath: "/opt/local/bin/restic"),
		URL(localPath: "/opt/homebrew/bin/restic"),
		URL(localPath: "/usr/local/bin/restic")
	]
// MARK: Setup
	let dq: DispatchQueue
	let jsonDecoder = JSONDecoder()
	private let logger: ResticLogger = ResticLogger.default
	var resticLocation: URL?
	var versionInfo: ResticResponse.ResticVersion?
	
	static var `default` = ResticController()
	private override init() {
		dq = DispatchQueue.init(label: "ResticController", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
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
		if let userSel = UserDefaults.standard.string(forKey: DefaultsKeys.resticLocation) {
			NSLog("User configured default \(userSel)")
			if userSel == "MacPorts" {
				return try testVersion(ResticController.autoURLs[0])
			} else if userSel == "Homebrew" {
				return try homebrew()
			} else if userSel != "Automatic" {
				return try testVersion(URL(localPath: (userSel as NSString).expandingTildeInPath))
			}
		}
		return try automatic()
	}
	
	/// Tests to see if the path points to a valid Restic binary by checking its version.
	/// - Parameter path: The path to restic, will be set if the command runs successfully.
	func testVersion(_ path: URL) throws {
		let vers = try ProcessRunner(executableURL: path).run(args: ["--json", "version"], returning: ResticResponse.ResticVersion.self)
		resticLocation = path
		versionInfo = vers.output
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
		for u in ResticController.autoURLs[1...] {
			resticLocation = u
			if let rv = try? testVersion(u) {
				return rv
			}
		}
		throw ResticError.noResticInstallationsFound("ResticGUI was unable to automatically find an install of Restic from Homebrew.")
	}
	
	func getVersionInfo() throws -> ResticResponse.ResticVersion {
		if versionInfo == nil {
			try setupFromDefaults()
		}
		return versionInfo!
	}
	
// MARK: Run
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
			let obj = try jsonDecoder.decode(T.self, from: data)
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
	
// MARK: launch
	typealias pipedDataHandler = (Data) -> Void
	typealias terminationHandler = (Int32) -> Void
	
	let newLine: UInt8 = "\n".data(using: .ascii)![0]
	var partial: Data = Data()
	var readHandler: pipedDataHandler!
	var errHandler: pipedDataHandler!
	var termHandler: terminationHandler!
	
	func read(_ data: Data) {
		partial.append(data)
		var splits = partial.split(separator: newLine)
		let last: Data? = splits.popLast()
		for i in splits {
			readHandler(i)
		}
		if last != nil {
			if JSONSerialization.isValidJSONObject(last as Any) {
				readHandler(last!)
				partial = Data()
			} else {
				partial = last!
				partial.append(newLine)
			}
		}
	}
	
	func exit(_ p: Process) {
		readHandler(partial)
		logger.log("Finished with exit code: \(p.terminationStatus)")
		termHandler(p.terminationStatus)
	}
	
	
	var currentlyRunningProcess: Process?
	/// Launches restic for monitoring.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	/// - Parameter stdoutHandler: Repeatedly called when new data is present in stdout.
	/// - Parameter stderrHandler: Repeatedly called when new data is present in stderr.
	/// - Parameter terminationHandler: Called when the process exits.
	func launch(args: [String], env: [String : String]?, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler, qos: QualityOfService) throws {
		partial = Data()
		if resticLocation == nil {
			do {
				try setupFromDefaults()
			} catch {
				resticLocation = nil
				throw error
			}
		}
		readHandler = stdoutHandler
		errHandler = stderrHandler
		termHandler = terminationHandler
		
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
		
		proc.qualityOfService = qos
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdout.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.read(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stderr.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			let data = handle.availableData
			self.logger.stderr(String(data: data, encoding: .utf8)!)
			stderrHandler(data)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		proc.terminationHandler = exit(_:)
		currentlyRunningProcess = proc
		try proc.run()
		stdout.fileHandleForReading.waitForDataInBackgroundAndNotify()
		stderr.fileHandleForReading.waitForDataInBackgroundAndNotify()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
	}
	
}

enum ResticError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON(String, String)
	case noResticInstallationsFound(String)
}
