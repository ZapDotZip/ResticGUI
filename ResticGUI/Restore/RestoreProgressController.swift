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
		super.viewDidAppear()
		if let plan {
			dq.async { [self] in
				restoreCoordinator = RestoreCoordinator(plan: plan, reportingTo: self)
				restoreCoordinator?.restore()
			}
			pauseButton.isEnabled = true
		} else {
			STB.log("RestorePlan was not set up correctly.")
			STBAlerts.alert(title: "An error has occured.", message: "The restore plan was not set up correctly. Please try again.", style: .warning)
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
			guard let infoText else { return }
			self.label.stringValue = infoText
		}
	}
	
	func displayError(_ error: Error, isFatal: Bool) {
		DispatchQueue.main.async { [self] in
			STBAlerts.alert(title: "An error occured while trying to restore the backup", message: nil, error: error, style: .critical)
			if isFatal {
				dismiss(self)
			}
		}
	}
	
	func finish(summary: ResticResponse.RestoreProgress?, with error: (any Error)?) {
		DispatchQueue.main.async { [self] in
			restoreCoordinator = nil
			if let error {
				displayError(error, isFatal: false)
			}
			if let summary {
				STBAlerts.alert(title: "Restore finished", message: "The restore has finished:\n\n\(summary.summaryReport())", style: .informational)
			}
			dismiss(self)
		}
	}
	
	func setIndeterminate(_ isIndeterminate: Bool) {
		DispatchQueue.main.async {
			self.progressBar.isIndeterminate = isIndeterminate
		}
	}
	
	@IBAction func pauseButtonPressed(_ sender: NSButton) {
		guard let restoreCoordinator else { return }
		if restoreCoordinator.isSuspended {
			if restoreCoordinator.resume() {
				pauseButton.stringValue = "Pause"
			}
		} else {
			if restoreCoordinator.pause() {
				pauseButton.stringValue = "Resume"
			}
		}
	}
	
	@IBAction func cancelButtonPressed(_ sender: NSButton) {
		guard let restoreCoordinator else {
			dismiss(self)
			return
		}
		restoreCoordinator.terminate()
	}
	
}
