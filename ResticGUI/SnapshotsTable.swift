//
//  SnapshotsDataSource.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox
import SwiftProcessController

class SnapshotsTable: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var viewCon: ViewController!
	
	@IBOutlet var table: NSTableView!
	@IBOutlet var reloadButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	
	var snapshots: [ResticResponse.Snapshot] = []
	let df = DateFormatter()
	let byteFmt = ByteCountFormatter()
	
	private let encoder = PropertyListEncoder.init()
	private let decoder = PropertyListDecoder.init()

	private static let cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "ResticGUI", isDirectory: true).appending(path: "Snapshots", isDirectory: true)
	
	required init?(coder: NSCoder) {
		df.locale = .current
		encoder.outputFormat = .binary
		super.init(coder: coder)
		UserDefaults.standard.addObserver(self, forKeyPath: DefaultsKeys.snapshotDateFormat, options: .new, context: nil)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == DefaultsKeys.snapshotDateFormat {
			reload()
		}
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return snapshots.count
	}
	
	func reload() {
		if let userDF = UserDefaults.standard.string(forKey: DefaultsKeys.snapshotDateFormat), userDF != "" {
			df.dateFormat = userDF
		} else {
			df.dateFormat = "YYYY-MM-dd 'at' h:mm a"
		}
		table.reloadData()
	}
	
	@IBAction func reloadButton(_ sender: NSButton) {
		guard let selectedRepo = repoManager.getSelectedRepo(), let selectedProfile = viewCon.selectedProfile else {
			return
		}
		reloadButton.isEnabled = false
		progressIndicator.startAnimation(self)
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try self.load(selectedRepo, selectedProfile)
				DispatchQueue.main.async { self.afterLoad() }
			} catch {
				DispatchQueue.main.async { self.loadError(error) }
			}
		}
	}
	
	func loadError(_ error: Error) {
		NSLog("Couldn't load snapshots: \(error)")
		progressIndicator.stopAnimation(self)
		reloadButton.isEnabled = true
		STBAlerts.alert(title: "Unable to load snapshots", message: nil, error: error, style: .critical)
	}
		
	func load(_ selectedRepo: Repo, _ selectedProfile: Profile) throws {
		snapshots = try ResticController.default.run(args: ["-r", selectedRepo.path, "snapshots", "--json"], env: try selectedRepo.getEnv(), returning: [ResticResponse.Snapshot].self)
		snapshots = snapshots.filter({ (snap) -> Bool in
			return snap.tags?.contains(selectedProfile.name) ?? false
		})
		saveToCache(selectedRepo)
	}
	
	func afterLoad() {
		reload()
		progressIndicator.stopAnimation(self)
		reloadButton.isEnabled = true
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let column = tableColumn,
				let cell = tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView else {
			NSLog("\(#function) cell with \(tableColumn?.identifier.rawValue ?? "nil") couldn't be made.")
			return nil
		}
		switch column.identifier.rawValue {
			case "Date & Time":
				cell.textField!.stringValue = df.string(from: snapshots[row].date)
			case "Tags":
				cell.textField!.stringValue = snapshots[row].tags?.joined(separator: ", ") ?? ""
			case "Size":
				cell.textField!.stringValue = byteFmt.string(fromByteCount: Int64(snapshots[row].summary.data_added_packed))
			default:
				NSLog("\(#function) recieved unknown identifier \(column.identifier)")
				cell.textField!.stringValue = "Unknown Error"
		}
		return cell
	}
	
	@IBOutlet var restoreButton: NSButton!
	
	@IBOutlet var mountButton: NSButton!
	@IBAction func mountButton(_ sender: NSButton) {
		
	}
	
	@IBOutlet var deleteButton: NSButton!
	@IBAction func deleteButton(_ sender: NSButton) {
		
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		if table.selectedRowIndexes.count == 0 {
			restoreButton.isEnabled = false
			deleteButton.isEnabled = false
			mountButton.isEnabled = false
		} else if table.selectedRowIndexes.count == 1 {
			restoreButton.isEnabled = true
			deleteButton.isEnabled = true
			mountButton.isEnabled = true
		} else {
			restoreButton.isEnabled = false
			deleteButton.isEnabled = true
			mountButton.isEnabled = false
		}
	}
	
	public var selectedSnapshot: ResticResponse.Snapshot? {
		get {
			return snapshots[table.selectedRow]
		}
	}
	
	private func getSnapshotCacheURL(_ caller: String = #function) -> URL? {
		if let repoID = repoManager.getSelectedRepo()?.id {
			return SnapshotsTable.cacheDirectory.appending(path: repoID, isDirectory: false)
		} else {
			RGLogger.default.log("\(caller) was unable to get the repo ID.")
			return nil
		}
	}
	
	func loadIfCached() {
		guard let sc = getSnapshotCacheURL(), let profile = viewCon.selectedProfile?.name,
				FileManager.default.fileExists(atPath: sc.path) else {
			snapshots = []
			reload()
			return
		}
		do {
			let data = try Data.init(contentsOf: sc)
			snapshots = try decoder.decode([ResticResponse.Snapshot].self, from: data).filter({ (snap) -> Bool in
				return snap.tags?.contains(profile) ?? false
			})
			reload()
		} catch {
			RGLogger.default.log("\(#function) was unable to load the snapshot cache \(error)")
		}
	}
	
	func saveToCache(_ repo: Repo) {
		guard let sc = getSnapshotCacheURL() else {	return }
		do {
			let data = try encoder.encode(snapshots)
			try FileManager.default.createDirectory(at: SnapshotsTable.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
			try data.write(to: sc)
		} catch {
			RGLogger.default.log("\(#function) was unable to save the snapshot cache \(error)")
		}
	}
	
}
