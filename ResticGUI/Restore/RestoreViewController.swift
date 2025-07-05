//
//  RestoreViewController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreViewController: NSViewController {
	@IBOutlet weak var sourceTypeEntire: NSButton!
	@IBOutlet weak var sourceTypePartial: NSButton!
	
	@IBOutlet weak var sourcePartialPathsTable: PathTable!
	
	@IBOutlet weak var destinationTypeOriginal: NSButton!
	@IBOutlet weak var destinationTypeChosen: NSButton!

	@IBOutlet weak var destinationOriginalOverwrite: NSButton!
	@IBOutlet var destinationCustomPath: PathSelectorLabelView!
	
	@IBOutlet weak var restoreButton: NSButton!
	
	var snapshotToRestore: ResticResponse.Snapshot!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		destinationCustomPath.controller.setup(path: nil, callback: self.pathDidChange(_:))
		destinationCustomPath.controller.canChooseFiles = false
	}
	
	private let restorableViewSizeKey = "RestoreViewSheet View Size"
	override func viewWillAppear() {
		super.viewWillAppear()
		if !NSEvent.modifierFlags.contains(.shift) {
			if let data = UserDefaults.standard.object(forKey: restorableViewSizeKey) as? Data {
				if let size = try? PropertyListDecoder().decode(CGSize.self, from: data) {
					view.window?.setContentSize(size)
				} else {
					UserDefaults.standard.removeObject(forKey: restorableViewSizeKey)
				}
			}
		}
	}
	
	override func viewWillDisappear() {
		if let size = view.window?.frame.size, let data = try? PropertyListEncoder().encode(size) {
			UserDefaults.standard.set(data, forKey: restorableViewSizeKey)
		}
		super.viewWillDisappear()
	}
	
	private var destinationCustomPathIsSet = false
	private func restoreButtonEnabled() {
		let sourceIsValid = sourceTypeEntire.state == .on || (sourceTypePartial.state == .on && true)
		
		let destinationIsValid = destinationTypeOriginal.state == .on || (destinationCustomPathIsSet && destinationTypeChosen.state == .on)
		
		restoreButton.isEnabled = sourceIsValid && destinationIsValid
	}
	
	func pathDidChange(_ path: URL?) -> Bool {
		if path != nil {
			destinationCustomPathIsSet = true
		} else {
			destinationCustomPathIsSet = false
		}
		restoreButtonEnabled()
		return true
	}
	
	@IBAction func restoreSnapshotType(_ sender: NSButton) {
		restoreButtonEnabled()
	}
	
	@IBAction func restoreDestinationType(_ sender: NSButton) {
		restoreButtonEnabled()
	}
	
	private func generatePlanFromUI() -> RestorePlan? {
		let src: RestorePlan.restoreSourceType? = {
			if sourceTypeEntire.state == .on {
				return RestorePlan.restoreSourceType.entireSnapshot
			} else {
				if let paths = sourcePartialPathsTable.save() {
					return RestorePlan.restoreSourceType.selectedFiles(files: paths)
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
				if let path = destinationCustomPath.controller.path {
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
		let plan = generatePlanFromUI()
		if let plan {
			print(plan)
		}
	}
	
	
	
}
