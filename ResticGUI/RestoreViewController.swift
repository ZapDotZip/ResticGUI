//
//  RestoreViewController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreViewController: NSViewController {
	@IBOutlet weak var restoreSourceTypeEntire: NSButton!
	@IBOutlet weak var restoreSourceTypePartial: NSButton!
	
	@IBOutlet weak var restoreSnapshotTable: NSScrollView!
	
	@IBOutlet weak var restoreDestinationTypeOriginal: NSButton!
	@IBOutlet weak var restoreDestinationTypeChosen: NSButton!

	@IBOutlet weak var restoreDestinationOriginalOverwrite: NSButton!
	@IBOutlet var restoreDestinationCustomPath: PathSelectorLabelView!
	
	@IBOutlet weak var restoreButton: NSButton!
	
	var snapshotToRestore: ResticResponse.Snapshot!
	
	private var selectedFileList: [String] = []
	
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		
	}
	
	@IBAction func restoreSnapshotType(_ sender: NSButton) {
		
	}
	
	@IBAction func restoreDestinationType(_ sender: NSButton) {
		if sender.identifier?.rawValue == "restoreDestinationTypeChosen" {
			if restoreDestinationCustomPath.controller.path != nil {
				restoreButton.isEnabled = true
			} else {
				restoreButton.isEnabled = false
			}
		} else {
			restoreButton.isEnabled = true
		}
	}
	
	private func generatePlanFromUI() -> RestorePlan? {
		let src: RestorePlan.restoreSourceType? = {
			if restoreSourceTypeEntire.state == .on {
				return RestorePlan.restoreSourceType.entireSnapshot
			} else {
				if selectedFileList.count > 0 {
					return RestorePlan.restoreSourceType.selectedFiles(files: selectedFileList)
				} else {
					Alert(title: "No files chosen to restore.", message: "Please choose at least one file or folder to restore, or choose to restore an entire snapshot.", style: .informational, buttons: ["Ok"])
					return nil
				}
			}
		}()
		let dest: RestorePlan.restoreDestinationType? = {
			if restoreDestinationTypeOriginal.state == .on {
				return RestorePlan.restoreDestinationType.originalSource(overwrite: restoreDestinationOriginalOverwrite.state == .on)
			} else {
				if let path = restoreDestinationCustomPath.controller.path {
					return RestorePlan.restoreDestinationType.newLocation(path: path)
				} else {
					Alert(title: "Please select a restore path.", message: "You need to choose a path to restore to.", style: .informational, buttons: ["Ok"])
					return nil
				}
			}
		}()
		
		if let src, let dest {
			return RestorePlan(snapshot: snapshotToRestore, restoreSource: src, restoreDestination: dest)
		} else {
			return nil
		}
	}
	
	
	
	@IBAction func restoreButtonPressed(_ sender: NSButton) {
		
	}
	
	
	
}

struct RestorePlan {
	enum restoreSourceType {
		case entireSnapshot
		case selectedFiles(files: [String])
	}
	enum restoreDestinationType {
		case originalSource(overwrite: Bool)
		case newLocation(path: URL)
	}
	
	let snapshot: ResticResponse.Snapshot
	let restoreSource: restoreSourceType
	let restoreDestination: restoreDestinationType
	
}
