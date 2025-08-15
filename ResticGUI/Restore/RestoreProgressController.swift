//
//  RestoreProgressController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreProgressController: NSViewController, ProgressDisplayer {
	
	@IBOutlet var progressBar: NSProgressIndicator!
	@IBOutlet var label: NSTextField!
	@IBOutlet var cancel: NSButton!
	@IBOutlet var pauseButton: NSButton!
	
	public var plan: RestorePlan?
	
	private let dq = DispatchQueue.init(label: "RestoreCoordinator", qos: .background)
	private var restoreCoordinator: RestoreCoordinator?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		progressBar.maxValue = 100.0
		progressBar.doubleValue = 0.0
		progressBar.isIndeterminate = true
	}
	
	override func viewDidAppear() {
		if let plan {
			dq.async { [self] in
				restoreCoordinator = RestoreCoordinator(plan: plan, reportingTo: self)
				restoreCoordinator?.restore()
			}
			pauseButton.isEnabled = true
		} else {
			STB.log("RestorePlan was not set up correctly.")
			STBAlerts.alert(title: "An error has occured.", message: "The restore plan was not set up. Please try again.", style: .warning)
			dismiss(self)
		}
	}
	
	func setProgressBar(to value: Double, max: Double) {
		DispatchQueue.main.async {
			self.progressBar.doubleValue = value
			self.progressBar.maxValue = max
		}
	}
	
	func updateProgress(to value: Double, infoText: String?) {
		DispatchQueue.main.async {
			self.progressBar.doubleValue = value
			if let infoText {
				self.label.stringValue = infoText
			}
		}
	}
	
	func displayError(_ error: Error, isFatal: Bool) {
		DispatchQueue.main.async {
			if let rErr = error as? ResticError, case let .exitCode(code, _) = rErr, code != 130 {
				STBAlerts.alert(title: "An error occured while trying to restore the backup", message: rErr.description, style: .critical)
			} else {
				STBAlerts.alert(title: "An error occured while trying to restore the backup", message: "The error message was:\n\n\(error.localizedDescription)", style: .critical)
			}
			if isFatal {
				self.dismiss(self)
			}
		}
	}
	
	func finish(summary: String?, with error: (any Error)?) {
		DispatchQueue.main.async {
			self.restoreCoordinator = nil
			if let error {
				self.displayError(error, isFatal: false)
			}
			if let summary {
				STBAlerts.alert(title: "Restore finished", message: "The restore has finished:\n\n\(summary)", style: .informational)
			}
		}
	}
	
	func setIndeterminate(_ isIndeterminate: Bool) {
		DispatchQueue.main.async {
			self.progressBar.isIndeterminate = isIndeterminate
		}
	}
	
	@IBAction func pauseButtonPressed(_ sender: NSButton) {
		if let restoreController {
			if restoreController.isSuspended {
				restoreController.pause()
				pauseButton.stringValue = "Resume"
			} else {
				restoreController.resume()
				pauseButton.stringValue = "Pause"
			}
		}
	}
	
	var wasCancelled = false
	@IBAction func cancelButtonPressed(_ sender: NSButton) {
		guard let restoreCoordinator else {
			dismiss(self)
			return
		}
		restoreCoordinator.terminate()
		wasCancelled = true
	}
	
}
