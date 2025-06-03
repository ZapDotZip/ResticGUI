//
//  EnviormentTable.swift
//  ResticGUI
//

import Cocoa

class EnviormentTableView: NSView {
	@IBOutlet var mainView: NSView!
	@IBOutlet weak var table: EnviormentTable!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		let nib = NSNib(nibNamed: "EnviormentTableView", bundle: Bundle(for: type(of: self)))
		nib?.instantiate(withOwner: self, topLevelObjects: nil)
		let previousConstraints = mainView.constraints
		mainView.subviews.forEach({addSubview($0)})
		for constraint in previousConstraints {
			let firstItem = (constraint.firstItem as? NSView == mainView) ? self : constraint.firstItem
			let secondItem = (constraint.secondItem as? NSView == mainView) ? self : constraint.secondItem
			addConstraint(NSLayoutConstraint(item: firstItem as Any, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
		}
	}
	
}

class EnviormentTable: NSTableView, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	private static let columnIndexes = IndexSet(integersIn: 0..<2)
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	@IBOutlet var deleteButton: NSButton!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.delegate = self
		self.dataSource = self
	}
	
	private var dict: [(String, String)] = []
	private func beenModified() {
		NotificationQueue.default.enqueue(Notification.init(name: Notification.Name.EnvTableDidChange, object: self), postingStyle: .whenIdle, coalesceMask: .onSender, forModes: nil)
	}

	func load(_ env: [String : String]?) {
		if let env = env {
			dict = env.map { (key: String, value: String) in
				return (key, value)
			}
		} else {
			dict = []
		}
		reloadData()
	}
	
	func save() -> [String : String]? {
		guard dict.count != 0 else {
			return nil
		}
		var env: [String : String] = [:]
		for i in dict {
			env[i.0] = i.1
		}
		return env
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return dict.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
			return nil
		}
		if tableColumn!.identifier.rawValue == "Enviorment Variable" {
			cell.textField!.stringValue = row < dict.count ? dict[row].0 : ""
		} else if tableColumn!.identifier.rawValue == "Value" {
			cell.textField!.stringValue = row < dict.count ? dict[row].1 : ""
		} else {
			cell.textField!.stringValue = "Unknown Error"
		}
		cell.textField?.delegate = self
		return cell
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		if selectedRowIndexes.count == 0 {
			deleteButton.isEnabled = false
		} else {
			deleteButton.isEnabled = true
		}
	}
	
	@IBAction func newItem(_ sender: NSButton) {
		insertRows(at: [dict.count], withAnimation: .effectGap)
		reloadData(forRowIndexes: [dict.count], columnIndexes: EnviormentTable.columnIndexes)
		selectRowIndexes([dict.count], byExtendingSelection: false)
		beenModified()
	}
	
	@IBAction func deleteItem(_ sender: NSButton) {
		for i in selectedRowIndexes.enumerated().reversed() {
			dict.remove(at: i.element)
		}
		beenModified()
		reloadData()
		deleteButton.isEnabled = false
	}
	
	var lastEditedCell: NSText?
	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		if fieldEditor.string == "" {
			return false
		}
		lastEditedCell = fieldEditor
		return true
	}
	
	override func textDidEndEditing(_ notification: Notification) {
		textFinishedEditing()
	}
	
	func textFinishedEditing() {
		if let textField = lastEditedCell {
			let row = row(for: textField)
			let col = column(for: textField)
			if row >= dict.count {
				if col == 0 {
					dict.append((textField.string, ""))
				} else {
					if let firstColText = (view(atColumn: 0, row: row, makeIfNecessary: true) as! NSTableCellView).textField?.stringValue {
						dict.append((firstColText, textField.string))
					}
				}
			} else {
				if col == 0 {
					dict[row].0 = textField.string
				} else {
					dict[row].1 = textField.string
				}
			}
			reloadData(forRowIndexes: [row], columnIndexes: EnviormentTable.columnIndexes)
			beenModified()
			lastEditedCell = nil
		}
	}
	
}
