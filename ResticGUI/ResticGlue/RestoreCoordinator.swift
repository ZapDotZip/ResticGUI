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

class RestoreCoordinator: SPCDecoderDelegate {
	typealias D = ResticResponse.RestoreProgress
	
	private static let rc = ResticController.default
	private var plan: RestorePlan
	private var display: any ProgressDisplayer<String>
	
	private let jsonDec = JSONDecoder()
	
	private var proc: SPCControllerDecoder<D>?
	private var summary: ResticResponse.RestoreProgress?
	
	init(plan: RestorePlan, reportingTo display: any ProgressDisplayer<String>) {
		self.plan = plan
		self.display = display
	}
	
	func argsFromPlan() throws -> [String] {
		var args = ["--json", "-r", plan.repo.path, "restore", plan.snapshot.id, "--target"]
		
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
			proc = try SPCControllerDecoder<D>.init(executableURL: ResticController.default.getResticURL(), delegate: self, decoderType: .JSON)
			proc!.env = try plan.repo.getEnv()
			let args: [String] = try argsFromPlan()
			RGLogger.default.run(process: proc!, args: args)
			try proc!.launch(args: args)
		} catch {
			display.displayError(error, isFatal: true)
		}
	}
	
	func stdoutHandler(_ response: SPCDecodedResult<D>) {
		switch response {
			case .object(output: let output):
				if let progress = output.percent_done {
					display.updateProgress(to: progress, infoText: output.progressReport)
				} else {
					summary = output
				}
			case .error(rawData: let rawData, decodingError: _):
				if let rErr = try? jsonDec.decode(ResticResponse.error.self, from: rawData) {
					RGLogger.default.log("stdout (decoded json): \(rErr)")
					display.displayError(RGError.init(from: rErr), isFatal: false)
				} else if let errStr = String.init(data: rawData, encoding: .utf8) {
					display.displayError(RGError.unknownError(message: errStr), isFatal: false)
				} else {
					display.displayError(RGError.unknownError(message: "Restic returned undecodable data."), isFatal: false)
				}
		}
	}
	
	func stderrHandler(_ errData: Data) {
		if let rErr = try? jsonDec.decode(ResticResponse.error.self, from: errData) {
			RGLogger.default.stderr("(decoded json): \(rErr)")
			display.displayError(RGError.init(from: rErr), isFatal: false)
		} else if let errStr = String.init(data: errData, encoding: .utf8) {
			if errStr.contains("terminated received, cleaning up") {
				return
			} else {
				RGLogger.default.stderr(errStr)
				display.displayError(RGError.unknownError(message: errStr), isFatal: false)
			}
		} else {
			RGLogger.default.log("Undecodable stderr data received from Restic")
		}
	}
	
	func terminationHandler(exitCode: Int32) {
		let exitError = RGError(exitCode: exitCode)
		if let sum = summary?.summaryReport {
			display.finish(summary: sum, with: exitError)
		} else {
			display.finish(summary: "No summary available.", with: exitError)
		}
	}
	
	func terminate() {
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
