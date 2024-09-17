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
		profiles.append(ProfileOrHeader.init(header: "Profiles"))
		DeleteProfileButton.isEnabled = false
		
		// view data setup
		initSidebar(ProfileManager.load())
		profileEditor.viewDidLoad()
		// TODO: get last selected profile and select/load it.
		repoManager.initUIView()
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
	}
	
	@IBAction func deleteProfile(_ sender: NSButton) {
		if let p = selectedProfile {
			let alertResponse = Alert(title: "Delete profile \"\(p.name)\".", message: "Are you sure you want to delete the profile \"\(p.name)\"? It will be moved to your Trash.", style: .informational, buttons: ["Delete", "Cancel"])
			if alertResponse == .alertFirstButtonReturn {
				ProfileManager.delete(p)
				profiles = profiles.filter { (poh) -> Bool in
					if let p = poh.profile {
						return p == selectedProfile
					}
					return false
				}
				outline.reloadData()
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
		save()
		if let selected = outline.item(atRow: outline.selectedRow) as? ProfileOrHeader {
			if let p = selected.profile {
				DeleteProfileButton.isEnabled = true
				profileEditor.setupMainEditorView(profile: p)
				selectedProfile = p
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
			self.view.window?.makeFirstResponder(self) // removes control from text fields
			ProfileManager.save(p)
		}
	}
	
	@IBAction func saveProfile(_ sender: NSMenuItem) {
		save()
	}
	
	@IBAction func newProfile(_ sender: NSMenuItem) {
		performSegue(withIdentifier: "NewProfile", sender: sender)
	}
	
	@IBAction func revertToSaved(_ sender: NSMenuItem) {
		if let p = selectedProfile {
			if let saved = ProfileManager.load(name: p.name) {
				if let i = profiles.firstIndex(where: { (poh) -> Bool in
					return poh.profile === selectedProfile
				}) {
					profiles[i].profile = saved
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
