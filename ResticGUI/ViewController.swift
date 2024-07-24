//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate {
	
	@IBOutlet var outline: NSOutlineView!
	@IBOutlet var profilesDataSource: ProfilesDataSource!
	@IBOutlet var RepoSelector: NSPopUpButton!
	@IBOutlet var DeleteProfileButton: NSButton!
	@IBOutlet var ExcludeTextView: NSTextView!
	@IBOutlet var BackupPathsDS: BackupPathsDataSource!
	
	
// MARK: primary view function
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		DeleteProfileButton.isEnabled = false
		let krList = UserDefaults.standard.stringArray(forKey: "Known Repositories") ?? ["test 1", "test 2"]// [String]()
		RepoSelector.addItems(withTitles: krList)
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	
	
	
// MARK: profile sidebar functions
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
				self.view.window?.title = "ResticGUI"
			} else {
				DeleteProfileButton.isEnabled = true
				self.view.window?.title = selected.name
				setupMainEditorView(profile: selected)
			}
		} else {
			DeleteProfileButton.isEnabled = false
			self.view.window?.title = "ResticGUI"
		}
	}
	
	
	
	
// MARK: profile view header (repo)
	@IBAction func repoEditButton(_ sender: NSSegmentedControl) {
		if sender.selectedSegment == 1 {
			// Delete alert
			// confirm delete
		} else {
			self.performSegue(withIdentifier: "repoEditStoryboard", sender: self)
			
		}
	}
	
	
	
	
// MARK: profile tabs: setup
	func setupMainEditorView(profile: Profile) {
		BackupPathsDS.load(fromProfile: profile)
		
		
	}
	
	
	
	
// MARK: profile tabs: paths
	@IBAction func importPathsFromTextFile(_ sender: Any) {
		
	}
	
	@IBAction func importPathsFromClipboard(_ sender: Any) {
		
	}
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
}
