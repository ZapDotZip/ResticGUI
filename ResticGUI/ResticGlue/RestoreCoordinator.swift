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

class RestoreCoordinator: InteractiveResticBase<ResticResponse.RestoreProgress, ResticResponse.RestoreProgress>, SPCDecoderDelegate {
	typealias D = ResticResponse.RestoreProgress
	
	private var plan: RestorePlan
	
	init(plan: RestorePlan, reportingTo display: any ProgressDisplayer<ResticResponse.RestoreProgress>) {
		self.plan = plan
		super.init(display: display)
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
		willStart()
		do {
			let p = try SPCControllerDecoder<D>.init(executableURL: ResticController.default.getResticURL(), delegate: self, decoderType: .JSON)
			p.env = try plan.repo.getEnv()
			let args: [String] = try argsFromPlan()
			RGLogger.default.run(process: p, args: args)
			try p.launch(args: args)
			process = p
		} catch {
			display.displayError(error, isFatal: true)
		}
	}
	
	func stdoutHandler(_ response: SPCDecodedResult<D>) {
		switch response {
			case .object(output: let output):
				if let progress = output.percent_done {
					display.updateProgress(to: progress, infoText: output.progressReport())
				} else {
					summary = output
				}
			case .error(rawData: let rawData, decodingError: let decodingError):
				let error = RGError.init(decodingError: decodingError, rawData: rawData, stderr: nil, exitCode: nil)
				RGLogger.default.log(error)
				display.displayError(error, isFatal: false)
		}
	}
	
}
