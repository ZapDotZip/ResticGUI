//
//  InteractiveResticBase.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController

protocol RGIRSummary: Decodable {
	var message_type: String { get }
}

/// Holds implementation for both ``BackupController`` and ``RestoreCoordinator``.
/// P: The progress type that is decoded and displayed during the process.
/// S: The summary type that is displayed at the end of the process.
class InteractiveResticBase<P: Decodable, S: RGIRSummary> {

	let display: any ProgressDisplayer<S>
	
	var process: SPCControllerDecoder<P>?
	var isQuittingIntentionally = false
	var state: ProcessState {
		get {
			return process?.processState ?? .notRunning
		}
	}
	
	var summary: S?
	
	init(display: any ProgressDisplayer<S>) {
		self.display = display
	}
	
	func willStart() {
		isQuittingIntentionally = false
	}
	
	func stderrHandler(_ errData: Data) {
		if let rErr = try? AppDelegate.jsonDecoder.decode(ResticResponse.error.self, from: errData) {
			RGLogger.default.stderr("(decoded json): \(rErr)")
			guard !isQuittingIntentionally && rErr.message != "exit_error" else { return } // don't show an error message when the user cancels the task
			display.displayError(RGError.init(from: rErr), isFatal: false)
		} else if let errStr = String.init(data: errData, encoding: .utf8) {
			guard !errStr.isEmpty else { return } // ignore spurious EOF data
			RGLogger.default.stderr(errStr)
			guard !isQuittingIntentionally && !errStr.contains("received, cleaning up") else { return } // don't show an error message when the user cancels the task
			display.displayError(RGError.unknownError(message: errStr), isFatal: false)
		} else {
			RGLogger.default.log("Undecodable stderr data received from Restic")
		}
	}
	
	func terminate() {
		if let process {
			isQuittingIntentionally = true
			process.terminate()
		}
	}
	
	func cancel() {
		if let process {
			isQuittingIntentionally = true
			process.interrupt()
		}
	}
	
	func pause() -> Bool {
		return process?.suspend() ?? false
	}
	
	func resume() -> Bool {
		return process?.resume() ?? false
	}
	
	var isSuspended: Bool {
		return process?.processState == .suspended
	}
	
	func terminationHandler(exitCode: Int32) {
		process = nil
		let exitError = RGError(exitCode: exitCode)
		display.finish(summary: summary, with: exitError)
	}
	
}
