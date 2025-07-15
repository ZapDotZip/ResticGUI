//
//  PathTable.swift
//  ResticGUI
//

import AppKit

class PathTable: NSScrollView, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	@IBOutlet var table: NSTableView!
	
	private var list: [String] = []
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.registerForDraggedTypes([.fileURL])
	}
	
	override func layout() {
		super.layout()
		table.tableColumns.first!.width = self.frame.width - 16
	}
	
	func save() -> [String]? {
		guard list.count != 0 else {
			return nil
		}
		return list
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return list.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {return nil}
		cell.textField!.stringValue = list[row]
		return cell
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
		return true
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		guard let draggedItems = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) else {
			return false
		}
		for i in draggedItems {
			if let draggedItem = i as? URL {
				append(draggedItem.localPath)
			}
		}
		return true
	}
	
	func append(_ path: String) {
		if !list.contains(path) {
			list.append(path)
			table.reloadData()
		}
	}
	
	override func draggingEnded(_ sender: NSDraggingInfo) {
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
	@IBAction func textDidEndEditing(_ sender: NSTextField) {
		guard table.selectedRow != -1 else {
			return
		}
		list[table.selectedRow] = sender.stringValue
		table.reloadData(forRowIndexes: [table.selectedRow], columnIndexes: [0])
	}
}
