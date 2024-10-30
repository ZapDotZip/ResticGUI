//
//  ResticLogger.swift
//  ResticGUI
//

import Foundation

final class ResticLogger {
	let logfile: FileHandle
	let df: DateFormatter
	let noData: Data
		
	init() {
		df = DateFormatter.init()
		df.locale = .current
		df.dateFormat = "YYYY-MM-dd hh:mm:ss a"
		
		noData = "Error converting text to data".data(using: .utf8)!
		
		let loggingDir = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Logs", isDirectory: true).appendingPathComponent("ResticGUI", isDirectory: true)
		let loggingFile = loggingDir.appendingPathComponent("restic.log", isDirectory: false)
		
		do {
			if !FileManager.default.fileExists(atPath: loggingFile.path) {
				try FileManager.default.createDirectory(at: loggingDir, withIntermediateDirectories: true, attributes: nil)
				FileManager.default.createFile(atPath: loggingFile.path, contents: nil, attributes: nil)
			}
			logfile = try FileHandle.init(forUpdating: loggingFile)
		} catch {
			NSLog("Error creating log directory: \(error)")
			Alert(title: "An error occured trying to create the log file.", message: "ResticGUI will still run, but error information will not be recorded.\n\n\(error.localizedDescription)", style: .critical, buttons: ["Ok"])
			logfile = FileHandle.standardError // Just write the output to the app's stderr instead of failing the application.
		}
		logfile.truncateFile(atOffset: 0)
	}
	
	/// Writes the raw string directly to the log file.
	/// - Parameter str: The string to write.
	func write(_ str: String) {
		logfile.write(str.data(using: .utf8) ?? noData)
	}
	
	/// Returns the formatted current date.
	func date() -> String { return df.string(from: Date.init()) }
	
	/// Logs the string by prepending the date before it.
	/// - Parameter str: The string to write.
	func log(_ str: String) { write("\(date()): \(str)\n") }
	
	/// Logs the string by prepending the date before it.
	/// - Parameter str: The string to write.
	func runCmd(path: URL, args: [String]) { write("\(date()): \(path.path) \(args)\n") }
	
	/// Logs Standard Error from restic.
	/// - Parameter str: The string to write.
	func stderr(_ str: String) { write("\(date()): stderr: \(str)\n") }
	
	/// Logs Standard Output when it's not JSON.
	/// - Parameter str: The string to write.
	func stdout(_ str: String) { write("\(date()): stdout: \(str)\n") }

	
	deinit {
		logfile.closeFile()
	}
}
