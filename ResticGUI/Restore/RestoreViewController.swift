//
//  RestoreViewController.swift
//  ResticGUI
//

import AppKit
import SwiftToolbox


class RestoreViewController: NSViewController {
	@IBOutlet weak var sourceTypeEntire: NSButton!
	@IBOutlet weak var sourceTypePartial: NSButton!
	
	@IBOutlet weak var sourcePathsTable: STBPathListView!
	private var sourcePathsList: STBPathListController!
	
	@IBOutlet weak var destinationTypeOriginal: NSButton!
	@IBOutlet weak var destinationTypeChosen: NSButton!

	@IBOutlet weak var destinationOriginalOverwrite: NSButton!
	@IBOutlet var destinationCustomPath: STBPathSelectorLabelView!
	
	@IBOutlet weak var restoreButton: NSButton!
	
	var snapshotToRestore: ResticResponse.Snapshot!
	var repo: Repo!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		sourcePathsList = sourcePathsTable.controller
		sourcePathsList.addObserver(self, forKeyPath: "listDidChange", context: nil)
		destinationCustomPath.controller.setup(path: nil, callback: self.pathDidChange(_:))
		destinationCustomPath.controller.canChooseFiles = false
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		if !NSEvent.modifierFlags.contains(.shift) {
			if let data = UserDefaults.standard.object(forKey: DefaultsKeys.viewSizeRestoreView) as? Data {
				if let size = try? PropertyListDecoder().decode(CGSize.self, from: data) {
					view.window?.setContentSize(size)
				} else {
					UserDefaults.standard.removeObject(forKey: DefaultsKeys.viewSizeRestoreView)
				}
			}
		}
	}
	
	override func viewWillDisappear() {
		if let size = view.window?.frame.size, let data = try? AppDelegate.plistEncoderBinary.encode(size) {
			UserDefaults.standard.set(data, forKey: DefaultsKeys.viewSizeRestoreView)
		}
		super.viewWillDisappear()
	}
	
	private var destinationCustomPathIsSet = false
	private func restoreButtonEnabled() {
		let sourceIsValid = sourceTypeEntire.state == .on || (sourceTypePartial.state == .on && sourcePathsList.listCount > 0)
		
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
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard object as? STBPathListController == sourcePathsList else {
			return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
		if sourcePathsList.listCount > 0 {
			sourceTypePartial.state = .on
		}
		restoreButtonEnabled()
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
				if sourcePathsList.listCount > 0 {
					return RestorePlan.restoreSourceType.selectedFiles(files: sourcePathsList.getStrings())
				} else {
					STBAlerts.alert(title: "No files chosen to restore.", message: "Please choose at least one file or folder to restore, or choose to restore an entire snapshot.", style: .informational)
					return nil
				}
			}
		}()
		
		let dest: RestorePlan.restoreDestinationType? = {
			if destinationTypeOriginal.state == .on {
				return RestorePlan.restoreDestinationType.originalSource(overwriteChangedOnly: destinationOriginalOverwrite.state == .on)
			} else {
				if let path = destinationCustomPath.controller.path {
					return RestorePlan.restoreDestinationType.newLocation(path: path)
				} else {
					STBAlerts.alert(title: "Please select a restore path.", message: "You need to choose a path to restore to.", style: .informational)
					return nil
				}
			}
		}()
		
		if let src, let dest {
			return RestorePlan(snapshot: snapshotToRestore, repo: repo, restoreSource: src, restoreDestination: dest)
		} else {
			return nil
		}
	}
	
	
	@IBAction func restoreButtonPressed(_ sender: NSButton) {
		if let plan = generatePlanFromUI() {
			performSegue(withIdentifier: "RestoreProgressSegue", sender: plan)
		}
	}
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue.identifier == "RestoreProgressSegue", let plan = sender as? RestorePlan {
			let vc = segue.destinationController as! RestoreProgressController
			vc.plan = plan
		} else {
			NSLog("Error: segue \"\(segue.identifier ?? "nil")\" not properly set up!")
		}
	}
	
	
	
}
