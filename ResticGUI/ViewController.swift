//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate {
	
	@IBOutlet var outline: NSOutlineView!
	@IBOutlet var profilesDataSource: ProfilesDataSource!
	@IBOutlet var MainEditorView: NSView!
	@IBOutlet var RepoSelector: NSPopUpButton!
	@IBOutlet var DeleteProfileButton: NSButton!
	@IBOutlet var BackupPathsListView: BackupPathsManager!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//MainEditorView.isHidden = true
		DeleteProfileButton.isEnabled = false
		// Do any additional setup after loading the view.
		let krList = UserDefaults.standard.stringArray(forKey: "Known Repositories") ?? ["test 1", "test 2"]// [String]()
		RepoSelector.addItems(withTitles: krList)
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		var profilesCellView: NSTableCellView
		if (item as! Profile).isHeader {
			profilesCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView)
			profilesCellView.textField?.stringValue = (item as! Profile).name
			return profilesCellView
		} else {
			profilesCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProfileCell"), owner: self) as! NSTableCellView)
			profilesCellView.textField?.stringValue = (item as! Profile).name
			return profilesCellView
			
		}
	}
	
	func editProfileName(_ sender: NSTextField) {
		if let selected = outline.item(atRow: outline.selectedRow) as? Profile {
			selected.name = sender.stringValue
		}
	}
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		if let selected = outline.item(atRow: outline.selectedRow) as? Profile {
			if selected.isHeader {
				DeleteProfileButton.isEnabled = false
				MainEditorView.isHidden = true
			} else {
				DeleteProfileButton.isEnabled = true
				setupMainEditorView(profile: selected)
			}
		} else {
			DeleteProfileButton.isEnabled = false
			MainEditorView.isHidden = true
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	func setupMainEditorView(profile: Profile) {
		
		
		
		
		MainEditorView.isHidden = false
	}
	
	
}

