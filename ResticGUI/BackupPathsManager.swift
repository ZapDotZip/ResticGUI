//
//  BackupPathsManager.swift
//  ResticGUI
//

import Cocoa

class BackupPathsManager: NSScrollView, NSOutlineViewDelegate {
	
	@IBOutlet var outline: NSOutlineView!
	
	private var NormalBGColor: NSColor?
	private var NormalBorderColor: CGColor?
	
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
	
	override func awakeFromNib() {
		self.registerForDraggedTypes([.fileURL])
	}
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		let bpi = (item as! BackupPathItem)
		if tableColumn!.identifier.rawValue == "PathCell" {
			var backupPathsCellView: CustomPathCell
			backupPathsCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PathCell"), owner: self) as! CustomPathCell)
			backupPathsCellView.pathControl.url = bpi.path
			return backupPathsCellView
		} else {
			var backupPathsCellView: NSTableCellView
			backupPathsCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SizeCell"), owner: self) as! NSTableCellView)
			backupPathsCellView.textField?.stringValue = String(bpi.size)
			return backupPathsCellView
		}
	}
	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
			NormalBGColor = self.backgroundColor
			self.backgroundColor = NSColor.selectedTextBackgroundColor
			self.layer?.borderWidth = 2.0
			NormalBorderColor = self.layer?.borderColor ?? NSColor.controlBackgroundColor.cgColor
			self.layer?.borderColor = NSColor.linkColor.cgColor
			return .copy
		} else {
			return NSDragOperation()
		}
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		if let draggedItems = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) {
			for i in draggedItems {
				if let draggedItem = i as? NSURL {
					(outline.dataSource as! BackupPathsDataSource).append(draggedItem as URL)
					outline.reloadData()
				}
			}
		}
		return true
	}
	
	override func draggingEnded(_ sender: NSDraggingInfo) {
		self.backgroundColor = NormalBGColor!
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
	override func draggingExited(_ sender: NSDraggingInfo?) {
		self.backgroundColor = NormalBGColor!
		self.layer?.borderWidth = 0.0
		self.layer?.borderColor = NormalBorderColor
	}
	
}

struct BackupPathItem {
	var path: URL
	var size: Int
	init(path: URL, size: Int) {
		self.path = path
		self.size = size
	}
	
}


class BackupPathsDataSource: NSObject, NSOutlineViewDataSource {
	var items: [BackupPathItem] = []
	override init() {
		// TODO: load saved items
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		items[index]
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		items.count
	}
	
	func append(_ item: BackupPathItem) {
		items.append(item)
	}
	
	func append(_ item: URL) {
		items.append(BackupPathItem.init(path: item, size: 0))
		
	}
}

class CustomPathCell: NSTableCellView {
	@IBOutlet var pathControl: NSPathControl!
	
}
