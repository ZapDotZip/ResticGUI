//
//  RestoreViewController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreViewController: NSViewController {
	@IBOutlet var restoreLocationView: PathSelectorLabelView!
	
	var snapshotToRestore: ResticResponse.Snapshot!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		
	}
	
	@IBAction func restoreButtonPressed(_ sender: NSButton) {
		if let restorePath = restoreLocationView.controller.path {
			
		} else {
			Alerts.Alert(title: "Please select a restore path.", message: "...", style: .informational, buttons: ["Ok"])
		}
	}
	
}
