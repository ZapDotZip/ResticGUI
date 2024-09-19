//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
	
	@IBOutlet var profileEditor: ProfileEditorController!
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var repoEditButton: NSSegmentedControl!
	
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	
	
	
// MARK: ViewController functionality
	override func viewDidLoad() {
		// view itself setup
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		
		appDel.viewFinishedLoading(vc: self)
		
		profileEditor.viewCon = self
		profileEditor.repoManager = repoManager
		profileSidebarList.append(ProfileOrHeader.init(header: "Profiles"))
		DeleteProfileButton.isEnabled = false
		
		// view data setup
		initSidebar(ProfileManager.load())
		profileEditor.viewDidLoad()
		repoManager.initUIView()
		if let s = UserDefaults.standard.string(forKey: "LastSelectedProfile") {
			selectedProfile = ProfileManager.load(name: s)
			if let p = selectedProfile {
				outline.selectRowIndexes(IndexSet.init(integer: indexOfProfile(p.name) ?? 1), byExtendingSelection: false)
			}
		}
		
	}
	
	override func viewDidAppear() {
		if profileSidebarList.count == 1 {
			performSegue(withIdentifier: "NewProfile", sender: self)
		}
	}
	
	func indexOfProfile(_ name: String) -> Int? {
		for (idx, poh) in profileSidebarList.enumerated() {
			if poh.profile?.name == name {
				return idx
			}
		}
		return nil
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
			vc.repoManager = repoManager
			if let selectedRepo = sender as? Repo {
				vc.selectedRepo = selectedRepo
			}
		} else {
			NSLog("Error: segue \"\(segue.identifier ?? "nil")\" not properly set up!")
		}
	}
	
	func saveQuit() {
		if let profile = selectedProfile {
			ProfileManager.save(profile)
		} else {
			NSLog("No profile selected to save.")
		}
	}
	
	
	
// MARK: Profile Sidebar
	@IBOutlet var outline: NSOutlineView!
	@IBOutlet var DeleteProfileButton: NSButton!
	var selectedProfile: Profile?
	
	func newProfile(name: String) {
		let new = Profile.init(name: name)
		append(profile: new)
		ProfileManager.save(new)
		outline.selectRowIndexes(IndexSet.init(integer: indexOfProfile(new.name) ?? 1), byExtendingSelection: false)
	}
	
	@IBAction func deleteProfile(_ sender: NSButton) {
		if let p = selectedProfile {
			var index = (indexOfProfile(p.name) ?? 0) - 1
			if index <= 0 {
				index = 1
			}
			let alertResponse = Alert(title: "Delete profile \"\(p.name)\".", message: "Are you sure you want to delete the profile \"\(p.name)\"? It will be moved to your Trash.", style: .informational, buttons: ["Delete", "Cancel"])
			if alertResponse == .alertFirstButtonReturn {
				ProfileManager.delete(p)
				profileSidebarList = profileSidebarList.filter { (poh) -> Bool in
					if let p = poh.profile {
						return p != selectedProfile
					}
					return true
				}
				outline.reloadData()
				selectedProfile = nil
				if profileSidebarList.count == 1 {
					performSegue(withIdentifier: "NewProfile", sender: sender)
				} else {
					outline.selectRowIndexes(IndexSet.init(integer: index), byExtendingSelection: false)
				}
			} else {
				NSLog("Delete cancelled")
			}
		} else {
			NSLog("No profile selected to delete.")
		}
	}
	
	func editProfileName(_ sender: NSTextField) {
		if let selected = outline.item(atRow: outline.selectedRow) as? Profile {
			selected.name = sender.stringValue
		}
	}
	
	
	
// OutlineDataSource
	var profileSidebarList: [ProfileOrHeader] = []
	
	func append(profile: Profile) {
		profileSidebarList.append(ProfileOrHeader.init(profile: profile))
		profileSidebarList.sort { (a, b) -> Bool in
			if let ap = a.profile, let bp = b.profile {
				return ap.name < bp.name
			}
			return false
		}
		outline.reloadData()
	}
	
	func initSidebar(_ newProfiles: [Profile]) {
		profileSidebarList.reserveCapacity(profileSidebarList.count + newProfiles.count)
		for i in newProfiles {
			profileSidebarList.append(ProfileOrHeader.init(profile: i))
		}
		outline.reloadData()
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		profileSidebarList[index]
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		profileSidebarList.count
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
		save()
		if let selected = outline.item(atRow: outline.selectedRow) as? ProfileOrHeader {
			if let p = selected.profile {
				DeleteProfileButton.isEnabled = true
				profileEditor.setupMainEditorView(profile: p)
				selectedProfile = p
				UserDefaults.standard.set(p.name, forKey: "LastSelectedProfile")
			} else {
				DeleteProfileButton.isEnabled = false
				self.view.window?.title = "ResticGUI"
			}
		} else {
			DeleteProfileButton.isEnabled = false
			self.view.window?.title = "ResticGUI"
		}
	}
	
	private func save() {
		if let p = selectedProfile {
			ProfileManager.save(p)
		}
	}
	
	@IBAction func saveProfile(_ sender: NSMenuItem) {
		self.view.window?.makeFirstResponder(self) // removes control from text fields
		save()
	}
	
	@IBAction func newProfile(_ sender: NSMenuItem) {
		performSegue(withIdentifier: "NewProfile", sender: sender)
	}
	
	@IBAction func revertToSaved(_ sender: NSMenuItem) {
		if let p = selectedProfile {
			if let saved = ProfileManager.load(name: p.name) {
				if let i = profileSidebarList.firstIndex(where: { (poh) -> Bool in
					return poh.profile === selectedProfile
				}) {
					profileSidebarList[i].profile = saved
					outline.reloadData()
				}
			}
		}
	}
	
	@IBAction func repoEditButton(_ sender: NSSegmentedControl) {
		if sender.selectedSegment == 1 {
			// Delete alert
			// confirm delete
		} else if sender.selectedSegment == 0 {
			self.performSegue(withIdentifier: "RepoEdit", sender: self)
		} else {
			self.performSegue(withIdentifier: "RepoEdit", sender: repoManager.getSelectedRepo())
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
