//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
	
	@IBOutlet var ProfileEditor: ProfileEditor!
	@IBOutlet var RepoManager: ReposManager!
	@IBOutlet var repoEditButton: NSSegmentedControl!
	
	let profManager: ProfilesManager = {
		return ProfilesManager.init()
	}()
	
	
// MARK: ViewController functionality
	override func viewDidLoad() {
		// view itself setup
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		ProfileEditor.viewCon = self
		ProfileEditor.profManager = profManager
		profiles.append(ProfileOrHeader.init(header: "Profiles"))
		DeleteProfileButton.isEnabled = false
		
		// view data setup
		initSidebar(profManager.load())
		ProfileEditor.viewDidLoad()
		// TODO: get last selected profile and select/load it.
		RepoManager.initUIView()
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		if segue.identifier == "NewProfile" {
			let vc = segue.destinationController as! NewProfileVC
			vc.viewCon = self
		} else if segue.identifier == "RepoEdit" {
			let vc = segue.destinationController as! RepoEditViewController
			vc.repoManager = RepoManager
			if let selectedRepo = sender as? Repo {
				vc.selectedRepo = selectedRepo
			}
		} else {
			NSLog("Error: segue \"\(segue.identifier ?? "nil")\" not properly set up!")
		}
	}
	
	
	func modified() {
		NSApplication.shared.mainWindow?.windowController?.setDocumentEdited(true)
		
	}
	
	func saveQuit() {
		if let prof = selectedProfile {
			profManager.save(profile: prof)
		}
	}
	
	
	
// MARK: Profile Sidebar
	@IBOutlet var outline: NSOutlineView!
	@IBOutlet var DeleteProfileButton: NSButton!
	var selectedProfile: Profile?
	
	func newProfile(name: String) {
		let new = Profile.init(name: name)
		append(profile: new)
		profManager.save(profile: new)
	}
	
	@IBAction func deleteProfile(_ sender: Any) {
		
	}
	
	func editProfileName(_ sender: NSTextField) {
		if let selected = outline.item(atRow: outline.selectedRow) as? Profile {
			selected.name = sender.stringValue
		}
	}
	
	
	
// OutlineDataSource
	var profiles: [ProfileOrHeader] = []
	
	func append(profile: Profile) {
		profiles.append(ProfileOrHeader.init(profile: profile))
		outline.reloadData()
	}
	
	func initSidebar(_ newProfiles: [Profile]) {
		profiles.reserveCapacity(profiles.count + newProfiles.count)
		for i in newProfiles {
			profiles.append(ProfileOrHeader.init(profile: i))
		}
		outline.reloadData()
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		profiles[index]
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		profiles.count
	}
	
// OutlineDelegate
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		var profilesCellView: NSTableCellView
		if (item as! ProfileOrHeader).isHeader {
			profilesCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView)
			profilesCellView.textField?.stringValue = (item as! ProfileOrHeader).header!
			return profilesCellView
		} else {
			profilesCellView = (outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ProfileCell"), owner: self) as! NSTableCellView)
			profilesCellView.textField?.stringValue = (item as! ProfileOrHeader).profile!.name
			return profilesCellView
			
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		if (item as! ProfileOrHeader).isHeader {
			return false
		}
		return true
	}
	
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		if let selected = outline.item(atRow: outline.selectedRow) as? ProfileOrHeader {
			if selected.isHeader {
				DeleteProfileButton.isEnabled = false
				self.view.window?.title = "ResticGUI"
			} else {
				DeleteProfileButton.isEnabled = true
				ProfileEditor.setupMainEditorView(profile: selected.profile!)
			}
		} else {
			DeleteProfileButton.isEnabled = false
			self.view.window?.title = "ResticGUI"
		}
	}
	
	func saveSelectedProfile() {
		if let p = selectedProfile {
			profManager.save(profile: p)
		NSApplication.shared.mainWindow?.windowController?.setDocumentEdited(false)
		}
	}
	
	
	@IBAction func repoEditButton(_ sender: NSSegmentedControl) {
		if sender.selectedSegment == 1 {
			// Delete alert
			// confirm delete
		} else if sender.selectedSegment == 0 {
			self.performSegue(withIdentifier: "RepoEdit", sender: self)
		} else {
			self.performSegue(withIdentifier: "RepoEdit", sender: RepoManager.getSelectedRepo())
		}
	}

	

	
}






class NewProfileVC: NSViewController {
	var viewCon: ViewController!
	@IBOutlet var textField: NSTextField!
	@IBOutlet var addButton: NSButton!
	override func viewDidLoad() {
		addButton.keyEquivalent = "\r"
	}
	@IBAction func textFieldDidChange(_ sender: NSTextField) {
		if sender.stringValue.count == 0 {
			addButton.isEnabled = false
		} else {
			addButton.isEnabled = true
		}
	}
	
	@IBAction func addButton(_ sender: NSButton) {
		if textField.stringValue.count != 0 {
			viewCon.newProfile(name: textField.stringValue)
			dismiss(self)
		}
	}
}
