//
//  RestoreCoordinator.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController
import SwiftToolbox

struct RestorePlan {
	enum restoreSourceType {
		case entireSnapshot
		case selectedFiles(files: [String])
	}
	enum restoreDestinationType {
		case originalSource(overwriteChangedOnly: Bool)
		case newLocation(path: URL)
	}
	
	let snapshot: ResticResponse.Snapshot
	let repo: Repo
	let restoreSource: restoreSourceType
	let restoreDestination: restoreDestinationType
	
}

class RestoreCoordinator {
	private static let rc = ResticController.default
	private var plan: RestorePlan
	private var display: ProgressDisplayer
	
	private let jsonDec = JSONDecoder()
	
	private var proc: ProcessControllerTyped<ResticResponse.RestoreProgress>?
	private var summary: ResticResponse.RestoreProgress?
	
	init(plan: RestorePlan, reportingTo display: ProgressDisplayer) {
		self.plan = plan
		self.display = display
	}
	
	func argsFromPlan() throws -> [String] {
		var args = ["-r", plan.repo.path, "restore", plan.snapshot.id, "--target"]
		
		switch plan.restoreDestination {
			case .originalSource(overwriteChangedOnly: let overwriteChangedOnly):
				args.append("/")
				args.append("--overwrite")
				if overwriteChangedOnly {
					args.append("if-changed")
				} else {
					args.append("always")
				}
			case .newLocation(path: let path):
				args.append(path.localPath)
		}
		
		switch plan.restoreSource {
			case .entireSnapshot:
				break
			case .selectedFiles(let files):
				let file = STB.temporaryFilename()
				try files.joined(separator: "\n").write(to: file, atomically: true, encoding: .utf8)
				args.append(contentsOf: ["--include-file", file.localPath])
		}
		
		return args
	}
	
	func restore() {
		do {
			proc = try ProcessControllerTyped<ResticResponse.RestoreProgress>.init(executableURL: ResticController.default.getResticURL(), stdoutHandler: progressHandler(_:), stderrHandler: stderrHandler(_:), terminationHandler: exitHandler(_:), decoderType: .JSON)
			proc!.env = try plan.repo.getEnv()
			let args: [String] = try argsFromPlan()
			Logger.default.run(process: proc!, args: args)
			try proc!.launch(args: args)
		} catch {
			display.displayError(error, isFatal: true)
		}
	}
	
	func progressHandler(_ response: StreamingProcessResult<ResticResponse.RestoreProgress>) {
		switch response {
			case .object(output: let output):
				if let progress = output.percent_done {
					display.updateProgress(to: progress, infoText: output.progressReport)
				} else {
					summary = output
				}
			case .error(rawData: let rawData, decodingError: _):
				if let rErr = try? jsonDec.decode(ResticResponse.error.self, from: rawData) {
					display.displayError(ResticError.init(from: rErr), isFatal: false)
				} else if let errStr = String.init(data: rawData, encoding: .utf8) {
					display.displayError(ResticError.couldNotDecodeJSON(rawStr: errStr, message: "Restic returned an unknown error message."), isFatal: false)
				} else {
					display.displayError(ResticError.unknownError(message: "Restic returned undecodable data."), isFatal: false)
				}
		}
	}
	
	func stderrHandler(_ errData: Data) {
		if let rErr = try? jsonDec.decode(ResticResponse.error.self, from: errData) {
			display.displayError(ResticError.init(from: rErr), isFatal: false)
		} else if let errStr = String.init(data: errData, encoding: .utf8) {
			Logger.default.stderr(errStr)
			display.displayError(ResticError.couldNotDecodeJSON(rawStr: errStr, message: "Restic returned unknown error message."), isFatal: false)
		} else {
			Logger.default.log("Undecodable stderr data received from Restic")
		}
	}
	
	func exitHandler(_ exitCode: Int32) {
		let exitError = ResticError(exitCode: exitCode)
		if let sum = summary?.summaryReport {
			display.finish(summary: sum, with: exitError)
		} else {
			display.finish(summary: "No summary available.", with: exitError)
		}
	}
	
	func stop() {
		proc?.terminate()
	}
	
	func pause() {
		_ = proc?.suspend()
	}
	
	func resume() {
		_ = proc?.resume()
	}
	
	var isSuspended: Bool {
		return proc?.processState == .suspended
	}
	
}

/// Protocol for communicating between an async progress task and a user interface to display determinate progress from a running task.
/// > Important: The implementing class is responsible for ensuring UI updates happen on the main thread.
protocol ProgressDisplayer {
	
	/// Called when the task first starts or when the max progress value changes.
	/// - Parameters:
	///   - value: The current progress value.
	///   - max: The maximum value for the progress.
	func setProgressBar(to value: Double, max: Double)
	
	/// Indicates that the task is currently running with indeterminate progress.
	/// - Parameter isIndeterminate: Whether or not the task's progress is indeterminate.
	func setIndeterminate(_ isIndeterminate: Bool)
	
	/// Called when the progress changes.
	/// - Parameters:
	///   - value: The updated progress value.
	///   - label: Progress text to display.
	func updateProgress(to value: Double, infoText: String?)
	
	/// Called when an error occurs during the task.
	/// - Parameter error: The error to display to the user.
	/// - Parameter isFatal: Whether or not the error was fatal.
	func displayError(_ error: Error, isFatal: Bool)
	
	/// Called when the task ends. If the task returns an error
	/// - Parameter summary: A summary of the task.
	/// - Parameter error: The error the task finished with, if any.
	func finish(summary: String?, with error: Error?)
	
}
