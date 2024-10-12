//
//  BackupPathsManager.swift
//  ResticGUI
//

import Cocoa


class BackupPathsDataSource: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var table: NSTableView!
	@IBOutlet var deleteButton: NSButton!
	var viewCon: ViewController!
	
// MARK: data source/delegate implementation
	var selectedProfile: Profile?
	
	func load(fromProfile profile: Profile) {
		// TODO: load saved items
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
	
	
// MARK: dragging implementation
	private var NormalBorderColor: CGColor?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.registerForDraggedTypes([.fileURL])
	}
	
	
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
		let (urls, response) = openPanel(message: "Select items you would like to back up.", prompt: "Add", canChooseDirectories: true, canChooseFiles: true, allowsMultipleSelection: true, canCreateDirectories: false)
		if response == NSApplication.ModalResponse.OK, urls.count != 0 {
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
		
	}
	
	@IBAction func importPathsFromClipboard(_ sender: NSButton) {
		
	}

	
}

