//
//  BackupPathsManager.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox


class BackupPathsDataSource: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var table: NSTableView!
	@IBOutlet var deleteButton: NSButton!
	
// MARK: data source/delegate implementation
	var selectedProfile: Profile?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.registerForDraggedTypes([.fileURL])
		table.tableColumns.first!.width = self.frame.width - 16
	}
		
	override func layout() {
		super.layout()
		table.tableColumns.first!.width = self.frame.width - 16
	}
	
	func load(fromProfile profile: Profile) {
		self.selectedProfile = profile
		deleteButton.isEnabled = false
		table.reloadData()
	}
	
	func reload() {
		table.reloadData()
	}
	
	func append(_ path: String) {
		selectedProfile?.addPath(path)
		table.reloadData()
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return selectedProfile?.paths.count ?? 0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {return nil}
		cell.textField!.stringValue = selectedProfile!.paths[row]
		return cell
	}
	
	@IBAction func doubleClick(_ sender: NSTableView) {
		if selectedProfile?.paths.count ?? 0 > 0 {
			NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: selectedProfile!.paths[table.clickedRow])
		}
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		if table.selectedRowIndexes.count == 0 {
			deleteButton.isEnabled = false
		} else {
			deleteButton.isEnabled = true
		}
	}
	
	@objc func copy(_ sender: AnyObject?) {
		if let p = selectedProfile?.paths {
			var copyPaths = [String]()
			for i in table.selectedRowIndexes {
				copyPaths.append(p[i])
			}
			NSPasteboard.general.clearContents()
			if NSPasteboard.general.setData(copyPaths.joined(separator: "\n").data(using: .utf8), forType: .string) {
				return
			} else {
				NSLog("Error writing to pasteboard.")
			}
		}
	}
	
	@objc func cut(_ sender: AnyObject?) {
		copy(sender)
		selectedProfile?.paths = []
		table.reloadData()
	}
	
// MARK: dragging implementation
	private var NormalBorderColor: CGColor?
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
			self.layer?.borderWidth = 2.0
			NormalBorderColor = self.layer?.borderColor ?? NSColor.controlBackgroundColor.cgColor
			self.layer?.borderColor = NSColor.selectedTextBackgroundColor.cgColor
			return .copy
		} else {
			return NSDragOperation()
		}
	}
	
	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		// TODO: check if path already exists
		return true
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		if let draggedItems = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) {
			for i in draggedItems {
				if let draggedItem = i as? NSURL {
					self.append(draggedItem.path!)
				}
			}
		}
		return true
	}
	
	override func draggingEnded(_ sender: NSDraggingInfo) {
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
	
	
	
	
	
	// MARK: Profile Tab: paths
	@IBAction func addPath(_ sender: NSButton) {
		if let urls = STBFilePanels.openPanel(message: "Select items you would like to back up.", canSelectMultipleItems: true, canCreateDirectories: true, selectableTypes: [.directories, .files()]) {
			for url in urls {
				selectedProfile?.addPath(url.path)
			}
			reload()
		}
	}
	
	@IBAction func deletePath(_ sender: NSButton) {
		for i in table.selectedRowIndexes.enumerated().reversed() {
			selectedProfile?.paths.remove(at: i.element)
		}
		reload()
	}
	
	@IBAction func importPathsFromTextFile(_ sender: NSButton) {
		if let urls = STBFilePanels.openPanel(message: "Select a text file containing paths to back up.", prompt: "Add", canSelectMultipleItems: true, canCreateDirectories: false, selectableTypes: [.files()]) {
			for url in urls {
				do {
					let txt = try String.init(contentsOf: url)
					for line in txt.split(separator: "\n") {
						selectedProfile?.addPath(String(line))
					}
				} catch {
					NSLog("Failed to load user-selected paths file: \(error)")
					STBAlerts.alert(title: "Failed to load paths from file.", message: "The file \(url.path) couldn't be read.\n\n\(error.localizedDescription)", style: .warning)
				}
			}
			reload()
		}
	}
	
	@IBAction @objc func paste(_ sender: AnyObject?) {
		for i in NSPasteboard.general.pasteboardItems ?? [] {
			if let str = i.string(forType: .fileURL), let url = URL.init(string: str)?.path {
				selectedProfile?.addPath(url)
			} else if let str = i.string(forType: .string) {
				for line in str.split(separator: "\n") {
					selectedProfile?.addPath(String(line))
				}
			}
		}
		reload()
	}

	
}

