//
//  SnapshotsDataSource.swift
//  ResticGUI
//

import Cocoa

class SnapshotsTable: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	lazy var resticController = appDel.resticController!
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var viewCon: ViewController!
	
	@IBOutlet var table: NSTableView!
	
	var snapshots: [Snapshot] = []
	let df: DateFormatter = DateFormatter()
	let byteFmt = ByteCountFormatter()
	
	private let encoder = PropertyListEncoder.init()
	private let decoder = PropertyListDecoder.init()
	
	let cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Snapshots", isDirectory: true)
	
	required init?(coder: NSCoder) {
		df.locale = .current
		encoder.outputFormat = .binary
		super.init(coder: coder)
		UserDefaults.standard.addObserver(self, forKeyPath: "SnapshotDateFormat", options: .new, context: nil)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "SnapshotDateFormat" {
			reload()
		}
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return snapshots.count
	}
	
	func reload() {
		if let userDF = UserDefaults.standard.string(forKey: "SnapshotDateFormat"), userDF != "" {
			df.dateFormat = userDF
		} else {
			df.dateFormat = "YYYY-MM-dd 'at' h:mm a"
		}
		table.reloadData()
	}
	
	@IBAction func reloadButton(_ sender: NSButton) {
		load()
	}
	
	func load() {
		if let selectedRepo = repoManager.getSelectedRepo() {
			if let selectedProfile = viewCon.selectedProfile {
				do {
					try snapshots = resticController.run(args: ["-r", selectedRepo.path, "snapshots", "--json"], env: selectedRepo.getEnv(), returning: [Snapshot].self).0.filter({ (snap) -> Bool in
						return snap.tags?.contains(selectedProfile.name) ?? false
					})
				} catch {
					NSLog("Couldn't load snapshots: \(error)")
					Alert(title: "Failed to load snapshots.", message: "An error occured trying to load the snapshots:\n\n\(error.localizedDescription)", style: .warning, buttons: ["Ok"])
				}
				reload()
				saveToCache()
			}
		}
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
			return nil
		}
		if tableColumn!.identifier.rawValue == "Date & Time" {
			cell.textField!.stringValue = df.string(from: snapshots[row].date)
		} else if tableColumn!.identifier.rawValue == "Tags" {
			cell.textField!.stringValue = snapshots[row].tags?.joined(separator: ", ") ?? ""
		} else if tableColumn!.identifier.rawValue == "Size" {
			cell.textField!.stringValue = byteFmt.string(fromByteCount: Int64(snapshots[row].summary.data_added_packed))
		} else {
			cell.textField!.stringValue = "Unknown Error"
		}
		return cell
	}
	
	
	@IBOutlet var restoreButton: NSButton!
	@IBAction func restoreButton(_ sender: NSButton) {
		
	}
	
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
	
	
	
	func loadIfCached() {
		if let repoID = repoManager.getSelectedRepo()?.id {
			let snapshotCacheURL: URL = cacheDirectory.appendingPathComponent(repoID, isDirectory: false)
			if FileManager.default.fileExists(atPath: snapshotCacheURL.path) {
				do {
					let data = try Data.init(contentsOf: snapshotCacheURL)
					snapshots = try decoder.decode([Snapshot].self, from: data).filter({ (snap) -> Bool in
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
	
	func saveToCache() {
		if let repoID = repoManager.getSelectedRepo()?.loadID() {
			let snapshotCacheURL: URL = cacheDirectory.appendingPathComponent(repoID, isDirectory: false)
			if let data = try? encoder.encode(snapshots) {
				do {
					try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
					try data.write(to: snapshotCacheURL)
					NSLog("Saved snapshot cache to \(snapshotCacheURL)")
				} catch {
					NSLog("Couldn't save cache \(error)")
				}
			}
		}
	}
	
}
