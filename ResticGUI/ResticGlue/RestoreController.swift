//
//  RestoreController.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController

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

class RestoreController {
	private static let rc = ResticController.default
	private var plan: RestorePlan
	private var display: ProgressDisplayer
	
	init(plan: RestorePlan, reportingTo display: ProgressDisplayer) {
		self.plan = plan
		self.display = display
	}
	
	func argsFromPlan() -> [String] {
		var args = ["restore", plan.snapshot.id, "--target"]
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
		
		return args
	}
	
	func restore() {
		do {
			let pr = try ProcessControllerTyped<ResticResponse.RestoreProgress>.init(executableURL: ResticController.default.getResticURL(), stdoutHandler: progressHandler(_:), stderrHandler: stderrHandler(_:), terminationHandler: exitHandler(_:), decoderType: .JSON)
			pr.env = try plan.repo.getEnv()
			try pr.launch(args: argsFromPlan())
		} catch {
			display.displayError(error, isFatal: true)
		}
	}
	
	func progressHandler(_ response: StreamingProcessResult<ResticResponse.RestoreProgress>) {
		switch response {
			case .object(output: let output):
				if let progress = output.percent_done {
					display.updateProgress(to: progress, infoText: output.progressReport)
				}
			case .error(rawData: let rawData, decodingError: _):
				if let rErr = try? JSONDecoder().decode(ResticResponse.error.self, from: rawData) {
					display.displayError(ResticError.init(from: rErr), isFatal: false)
				}
		}
	}
	
	func stderrHandler(_ err: Data) {
		
	}
	
	func exitHandler(_ exitCode: Int32) {
		display.finish(summary: "", with: nil)
	}
	
}

/// Protocol for communicating between an async progress task and a user interface to display determinate progress from a running task.
protocol ProgressDisplayer {
	
	/// Called when the task first starts or when the max progress value changes.
	/// - Parameters:
	///   - value: The current progress value.
	///   - max: The maximum value for the progress.
	func setProgressBar(to value: Double, max: Double)
	
	/// Indicates that the process is currently running with indeterminate progress.
	/// - Parameter isIndeterminate: Whether or not the process's progress is indeterminate.
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
	
	/// Called when the task ends. If the process returns an error
	/// - Parameter summary: A summary of the task.
	/// - Parameter error: The error the process finished with, if any.
	func finish(summary: String?, with error: Error?)
	
}
