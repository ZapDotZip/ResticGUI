//
//  SnapshotsDataSource.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox
import SwiftProcessController

class SnapshotsTable: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	private lazy var resticController = ResticController.default
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var viewCon: ViewController!
	
	@IBOutlet var table: NSTableView!
	@IBOutlet var reloadButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	
	var snapshots: [ResticResponse.Snapshot] = []
	let df: DateFormatter = DateFormatter()
	let byteFmt = ByteCountFormatter()
	
	private let encoder = PropertyListEncoder.init()
	private let decoder = PropertyListDecoder.init()
	private let jsonDecoder = JSONDecoder.init()

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
		if let selectedRepo = repoManager.getSelectedRepo(), let selectedProfile = viewCon.selectedProfile {
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
	}
	
	func loadError(_ error: Error) {
		NSLog("Couldn't load snapshots: \(error)")
		progressIndicator.stopAnimation(self)
		reloadButton.isEnabled = true
		if let err = error as? ResticError {
			Alerts.Alert(title: "Unable to load snapshots", message: err.description, style: .critical)
		} else {
			Alerts.Alert(title: "Unable to load snapshots", message: "An error occured trying to load the snapshots: \(error.localizedDescription)", style: .critical)
		}
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
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
			return nil
		}
		guard let column = tableColumn else {
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
	
	
	
	func loadIfCached() {
		if let repoID = repoManager.getSelectedRepo()?.id {
			let snapshotCacheURL: URL = SnapshotsTable.cacheDirectory.appending(path: repoID, isDirectory: false)
			if FileManager.default.fileExists(atPath: snapshotCacheURL.path) {
				do {
					let data = try Data.init(contentsOf: snapshotCacheURL)
					snapshots = try decoder.decode([ResticResponse.Snapshot].self, from: data).filter({ (snap) -> Bool in
						return snap.tags?.contains(viewCon!.selectedProfile?.name ?? "") ?? false
					})
					reload()
					return
				} catch {
					NSLog("Couldn't load snapshot cache: \(error)")
				}
			}
		}
		snapshots = []
		reload()
	}
	
	func saveToCache(_ repo: Repo) {
		if let repoID = repo.loadID() {
			let snapshotCacheURL: URL = SnapshotsTable.cacheDirectory.appending(path: repoID, isDirectory: false)
			if let data = try? encoder.encode(snapshots) {
				do {
					try FileManager.default.createDirectory(at: SnapshotsTable.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
					try data.write(to: snapshotCacheURL)
					NSLog("Saved snapshot cache to \(snapshotCacheURL)")
				} catch {
					NSLog("Couldn't save cache \(error)")
				}
			}
		}
	}
	
}
