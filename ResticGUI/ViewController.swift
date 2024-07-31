//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
	
	@IBOutlet var BackupPathsDS: BackupPathsDataSource!
	
	var profManager: ProfilesManager {
		return ProfilesManager.init()
	}
	
	
// MARK: primary view function
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		profiles.append(ProfileOrHeader.init(header: "Profiles"))
		
		DeleteProfileButton.isEnabled = false
		let krList = UserDefaults.standard.stringArray(forKey: "Known Repositories") ?? ["test 1", "test 2"]// [String]()
		RepoSelector.addItems(withTitles: krList)
		append(profiles: profManager.load())
		BackupPathsDS.viewCon = self
		
		
		// re-do
		initRepoSelector()
		
		
		
		
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
			vc.viewCon = self
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
	
	
	
// MARK: profile sidebar functions
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
	
	func append(profiles newProfiles: [Profile]) {
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
				setupMainEditorView(profile: selected.profile!)
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
	
	
	
	
// MARK: profile view header (repo)
	@IBOutlet var RepoSelector: NSPopUpButton!
	var repos: [Repo] = []
	
	func initRepoSelector() {
		if let reposdata = UserDefaults.standard.array(forKey: "Repos") {
			repos.reserveCapacity(reposdata.count)
			let decoder = PropertyListDecoder()
			for i in reposdata {
				if let d = try? decoder.decode(Repo.self, from: (i as! Data)) {
					repos.append(d)
					RepoSelector.addItem(withTitle: d.name ?? d.path)
				}
			}
		}
		//RepoSelector.selectItem(withTitle: )
		
		
		
	}
	
	
	@IBAction func repoEditButton(_ sender: NSSegmentedControl) {
		if sender.selectedSegment == 1 {
			// Delete alert
			// confirm delete
		} else if sender.selectedSegment == 0 {
			self.performSegue(withIdentifier: "RepoEdit", sender: self)
		} else {
			self.performSegue(withIdentifier: "RepoEdit", sender: self)
		}
	}
	
	
	
	
// MARK: profile tabs: setup
	func setupMainEditorView(profile: Profile) {
		// save the existing profile if it has been modified
		if let prof = selectedProfile, NSApplication.shared.mainWindow?.isDocumentEdited ?? false {
			profManager.save(profile: prof)
		}
		self.view.window?.title = profile.name
		selectedProfile = profile
		BackupPathsDS.load(fromProfile: profile)
		ExcludeTextView.string = profile.exclusions.joined(separator: "\n")
		
		
	}
	
	
	
	
	
	
// MARK: profile tabs: paths
	@IBAction func importPathsFromTextFile(_ sender: Any) {
		
	}
	
	@IBAction func importPathsFromClipboard(_ sender: Any) {
		
	}
	
	
	
	
// MARK: Profile Tabs: Excludes & Options
	@IBOutlet var ExcludeTextView: NSTextView!
	@IBOutlet var ExcludeCaseSensitive: NSButton!
	@IBOutlet var ExcludeCacheDirs: NSButton!
	@IBOutlet var ExcludeTMDefault: NSView!
	@IBOutlet var ExcludeTMUser: NSButton!
	@IBOutlet var ExcludeFilesOver: NSButton!
	@IBOutlet var ExcludeFilesOverValue: NSTextField!
	@IBOutlet var ExcludePatternFile: NSTextField!
	@IBOutlet var Compression: NSPopUpButton!
	@IBOutlet var ReadConcurrency: NSTextField!
	@IBOutlet var PackSize: NSTextField!
	
	
	@IBAction func ExcludeCaseSensitiveChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.exclusionsCaseSensitive = true
		} else {
			selectedProfile?.exclusionsCaseSensitive = false
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
