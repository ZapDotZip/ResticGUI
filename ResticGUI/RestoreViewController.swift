//
//  RestoreViewController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreViewController: NSViewController {
	@IBOutlet weak var sourceTypeEntire: NSButton!
	@IBOutlet weak var sourceTypePartial: NSButton!
	
	@IBOutlet weak var sourcePartialPathsTable: NSTableView!
	
	@IBOutlet weak var destinationTypeOriginal: NSButton!
	@IBOutlet weak var destinationTypeChosen: NSButton!

	@IBOutlet weak var destinationOriginalOverwrite: NSButton!
	@IBOutlet var destinationCustomPath: PathSelectorLabelView!
	
	@IBOutlet weak var restoreButton: NSButton!
	
	var snapshotToRestore: ResticResponse.Snapshot!
	
	private var selectedFileList: [String] = []
		
	override func viewDidLoad() {
		super.viewDidLoad()
		destinationCustomPath.controller.setup(path: nil, callback: self.pathDidChange(_:))
	}
	
	func pathDidChange(_ path: URL?) -> Bool {
		if path != nil && destinationTypeChosen.state == .on {
			restoreButton.isEnabled = true
		} else {
			restoreButton.isEnabled = false
		}
		return true
	}
	
	@IBAction func restoreSnapshotType(_ sender: NSButton) {
		
	}
	
	@IBAction func restoreDestinationType(_ sender: NSButton) {
		if sender.identifier?.rawValue == "restoreDestinationTypeChosen" {
//			if restoreDestinationCustomPath.controller.path != nil {
//				restoreButton.isEnabled = true
//			} else {
//				restoreButton.isEnabled = false
//			}
//		} else {
//			restoreButton.isEnabled = true
		}
	}
	
	private func generatePlanFromUI() -> RestorePlan? {
		let src: RestorePlan.restoreSourceType? = {
			if sourceTypeEntire.state == .on {
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
			if destinationTypeOriginal.state == .on {
				return RestorePlan.restoreDestinationType.originalSource(overwrite: destinationOriginalOverwrite.state == .on)
			} else {
//				if let path = restoreDestinationCustomPath.controller.path {
//					return RestorePlan.restoreDestinationType.newLocation(path: path)
//				} else {
//					Alert(title: "Please select a restore path.", message: "You need to choose a path to restore to.", style: .informational, buttons: ["Ok"])
//					return nil
//				}
				return nil
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
