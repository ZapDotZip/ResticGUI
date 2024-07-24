//
//  BackupPathsManager.swift
//  ResticGUI
//

import Cocoa


class BackupPathsDataSource: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var table: NSTableView!
	
// MARK: data source/delegate implementation
	var paths: [String] = []
	
	func load(fromProfile profile: Profile) {
		// TODO: load saved items
		append("/")
		append("/Users")
		table.reloadData()
	}
	
	func append(_ path: String) {
		paths.append(path)
		table.reloadData()
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		paths.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {return nil}
		cell.textField!.stringValue = paths[row]
		return cell
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
	
}

