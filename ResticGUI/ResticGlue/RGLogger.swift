//
//  Logger.swift
//  ResticGUI
//

import Foundation
import SwiftToolbox
import SwiftProcessController

final class RGLogger {
	private let logfile: FileHandle
	private let df: DateFormatter
	private let dq: DispatchQueue
	static let `default` = RGLogger()
	
	private init() {
		df = DateFormatter.init()
		df.locale = .current
		df.dateFormat = "YYYY-MM-dd hh:mm:ss a"
		
		do {
			let loggingDir = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "Logs", isDirectory: true).appending(path: "ResticGUI", isDirectory: true)
			
			let logfilePath = loggingDir.appending(path: "restic.log", isDirectory: false)
			
			if !FileManager.default.fileExists(atPath: logfilePath.path) {
				try FileManager.default.createDirectory(at: loggingDir, withIntermediateDirectories: true, attributes: nil)
				FileManager.default.createFile(atPath: logfilePath.path, contents: nil, attributes: nil)
			}
			logfile = try FileHandle.init(forUpdating: logfilePath)
		} catch {
			NSLog("Error creating log directory: \(error)")
			STBAlerts.alert(title: "An error occured trying to create the log file.", message: "ResticGUI will still run, but error information will not be recorded.\n\n\(error.localizedDescription)", style: .critical)
			logfile = FileHandle.standardError // Just write the output to the app's stderr instead of failing the application.
		}
		dq = DispatchQueue(label: "LoggingQueue", qos: .background)
		
		dq.async {
			self.logfile.truncateFile(atOffset: 0)
		}
	}
	
	/// Writes the raw string directly to the log file.
	/// - Parameter str: The string to write.
	private func write(_ str: String) {
		#if DEBUG
			print(str)
		#endif
		dq.async {
			self.logfile.write(Data(str.utf8))
		}
	}
	
	/// Returns the formatted current date.
	private func date() -> String { return df.string(from: Date.init()) }
	
	/// Logs the string by prepending the date before it.
	/// - Parameter str: The string to write.
	public func log(_ str: String) {
		if str.count != 0 {
			write("\(date()): \(str)\n")
		}
	}
	
	public func log(_ rErr: RGError) {
		write("\(date()): \(rErr)\n")
	}
	
	/// Logs the string by prepending the date before it.
	/// - Parameter str: The string to write.
	public func runCmd(path: URL, args: [String]) {
		write("\(date()): Running \(path.path) \(args)\n")
	}
	
	public func run(process: SPCBase, args: [String]) {
		write("\(date()): Running \(process.executableURL.localPath) \(args)\n with env: \(process.env?.filter { !$0.key.lowercased().contains("password") } ?? [:])\n")
	}
	
	/// Logs Standard Error from restic.
	/// - Parameter str: The string to write.
	public func stderr(_ str: String?) {
		if str != nil, str?.count != 0 {
			write("\(date()): stderr: \(str!)\n")
		}
	}
	
	/// Logs Standard Output when it's not JSON.
	/// - Parameter str: The string to write.
	public func stdout(_ str: String) {
		if str.count != 0 {
			write("\(date()): stdout: \(str)\n")
		}
	}
	
}
