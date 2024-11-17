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
	
	required init?(coder: NSCoder) {
		df.locale = .current
		df.dateFormat = "YYYY-MM-dd 'at' h:mm:ss a"
		super.init(coder: coder)
	}

	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return snapshots.count
	}
	
	func reload() {
		table.reloadData()
	}
	
	@IBAction func reloadButton(_ sender: NSButton) {
		load()
	}
	
	func load() {
		if let selectedRepo = repoManager.getSelectedRepo() {
			if let selectedProfile = viewCon.selectedProfile {
				do {
					try (snapshots, _) = resticController.run(args: ["-r", selectedRepo.path, "snapshots", "--tag", selectedProfile.name, "--json"], env: selectedRepo.getEnv(), returning: [Snapshot].self)
				} catch {
					NSLog("\(error)")
					Alert(title: "Failed to load snapshots.", message: "An error occured trying to load the snapshots:\n\n\(error.localizedDescription)", style: .warning, buttons: ["Ok"])
				}
				reload()
			}
		}		
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
			return nil
		}
		if tableColumn!.identifier.rawValue == "Date & Time" {
			cell.textField!.stringValue = df.string(from: snapshots[row].getDate())
		} else if tableColumn!.identifier.rawValue == "Tags" {
			cell.textField!.stringValue = snapshots[row].tags.joined(separator: ", ")
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
	
	
}
