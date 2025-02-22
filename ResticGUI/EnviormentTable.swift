//
//  EnviormentTable.swift
//  ResticGUI
//

import Cocoa

class EnviormentTableView: NSView {
	@IBOutlet var mainView: NSView!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		let nib = NSNib(nibNamed: "EnviormentTableView", bundle: Bundle(for: type(of: self)))
		nib?.instantiate(withOwner: self, topLevelObjects: nil)
		let previousConstraints = mainView.constraints
		mainView.subviews.forEach({addSubview($0)})
		for constraint in previousConstraints {
			print(constraint)
			let firstItem = (constraint.firstItem as? NSView == mainView) ? self : constraint.firstItem
			let secondItem = (constraint.secondItem as? NSView == mainView) ? self : constraint.secondItem
			addConstraint(NSLayoutConstraint(item: firstItem as Any, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
		}
	}
	
}

class EnviormentTable: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
	private static let columnIndexes = IndexSet(integersIn: 0..<2)
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	@IBOutlet var deleteButton: NSButton!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.delegate = self
		self.dataSource = self
	}
	
	private var dict: [(String, String)] = []
	func load(env: [String : String]?) {
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
		if dict.count == 0 {
			return nil
		} else {
			var env: [String : String] = [:]
			for i in dict {
				env[i.0] = i.1
			}
			return env
		}
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
	}
	
	@IBAction func deleteItem(_ sender: NSButton) {
		for i in selectedRowIndexes.enumerated().reversed() {
			dict.remove(at: i.element)
		}
		reloadData()
		deleteButton.isEnabled = false
	}
	
	@IBAction func textFinishedEditing(_ sender: NSTextField) {
		let row = row(for: sender)
		let col = column(for: sender)
		if row >= dict.count {
			if col == 0 {
				dict.append((sender.stringValue, ""))
			} else {
				let firstColText = (view(atColumn: 0, row: row, makeIfNecessary: true) as! NSTableCellView).textField?.stringValue ?? ""
				dict.append((firstColText, sender.stringValue))
			}
		} else {
			if col == 0 {
				dict[row].0 = sender.stringValue
			} else {
				dict[row].1 = sender.stringValue
			}
		}
		reloadData(forRowIndexes: [row], columnIndexes: EnviormentTable.columnIndexes)
	}
	
}

