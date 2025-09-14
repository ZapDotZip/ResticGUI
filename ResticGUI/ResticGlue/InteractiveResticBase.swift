//
//  InteractiveResticBase.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController


/// Holds implementation for both ``BackupController`` and ``RestoreCoordinator``.
class InteractiveResticBase<D: Decodable, C> {
	
	var process: SPCControllerDecoder<D>?
	var display: any ProgressDisplayer<C>

	let jsonDecoder = JSONDecoder()
	
	var state: ProcessState {
		get {
			return process?.processState ?? .notRunning
		}
	}
	
	init(display: any ProgressDisplayer<C>) {
		self.display = display
	}
	
	var isQuittingIntentionally = false
	func stderrHandler(_ errData: Data) {
		if let rErr = try? jsonDecoder.decode(ResticResponse.error.self, from: errData) {
			RGLogger.default.stderr("(decoded json): \(rErr)")
			guard !isQuittingIntentionally && rErr.message == "exit_error" else {
				isQuittingIntentionally = false
				return
			}
			display.displayError(RGError.init(from: rErr), isFatal: false)
		} else if let errStr = String.init(data: errData, encoding: .utf8) {
			if processIsBeingTerminated || errStr.contains("received, cleaning up") {
				return // do not display an error message when the user terminates the restore.
			} else {
				RGLogger.default.stderr(errStr)
				display.displayError(RGError.unknownError(message: errStr), isFatal: false)
			}
		} else {
			RGLogger.default.log("Undecodable stderr data received from Restic")
		}
	}
	
	private var processIsBeingTerminated = false
	func terminate() {
		processIsBeingTerminated = true
		process?.terminate()
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

}
