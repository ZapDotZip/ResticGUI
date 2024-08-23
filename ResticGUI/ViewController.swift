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
	
	
// MARK: ViewController functionality
	override func viewDidLoad() {
		// view itself setup
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		ExcludeTextView.font = NSFont.init(name: "Menlo", size: 12)
		profiles.append(ProfileOrHeader.init(header: "Profiles"))
		DeleteProfileButton.isEnabled = false
		BackupPathsDS.viewCon = self
		
		// view data setup
		initSidebar(profManager.load())
		initRepoSelector()
		// TODO: get last selected profile and select/load it.
		
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
	
	
	
	
// MARK: Profile View Header (repo selector)
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
	}
	
	func addRepo(_ repo: Repo) {
		
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
	
	
	
	
// MARK: Profile Tabs: setup
	/// Configures the UI based off the provided profile. Saves the existing profile if selected and modified.
	/// - Parameter profile: The profile to load.
	func setupMainEditorView(profile: Profile) {
		// save the existing profile if it has been modified
		if let prof = selectedProfile {
			profManager.save(profile: prof)
		}
		self.view.window?.title = profile.name
		selectedProfile = profile
		BackupPathsDS.load(fromProfile: profile)
		ExcludeTextView.string = profile.exclusions.joined(separator: "\n")
		ExcludeCaseSensitive.state = profile.exclusionsCS ? .on : .off
		ExcludeCacheDirs.state = profile.excludeCacheDirs ? .on : .off
		if let val = profile.excludeMaxFilesize {
			ExcludeFilesOver.state = .on
			ExcludeFilesOver.stringValue = val
		} else {
			ExcludeFilesOver.state = .off
		}
		
		ExcludeTMDefault.state = profile.excludesTMDefault ? .on : .off
		ExcludeTMUser.state = profile.excludesTMUser ? .on : .off
		ExcludePatternFile.stringValue = profile.excludePatternFile ?? ""
		ExcludePatternFileCS.state = profile.excludePatternFileCS ? .on : .off
		Compression.selectItem(withTitle: profile.compression ?? "auto")
		if let val = profile.readConcurrency {
			ReadConcurrency.stringValue = String(val)
		} else {
			ReadConcurrency.stringValue = ""
		}
		if let val = profile.packSize {
			PackSize.stringValue = String(val)
		} else {
			PackSize.stringValue = ""
		}
		
		
		
	}
	
	
	
	
	
	
// MARK: Profile Tab: paths
	@IBAction func importPathsFromTextFile(_ sender: Any) {
		
	}
	
	@IBAction func importPathsFromClipboard(_ sender: Any) {
		
	}
	
	
	
	
// MARK: Profile Tab: Excludes & Options
	@IBOutlet var ExcludeTextView: NSTextView!
	@IBOutlet var ExcludeCaseSensitive: NSButton!
	@IBOutlet var ExcludeCacheDirs: NSButton!
	@IBOutlet var ExcludeTMDefault: NSButton!
	@IBOutlet var ExcludeTMUser: NSButton!
	@IBOutlet var ExcludeFilesOver: NSButton!
	@IBOutlet var ExcludeFilesOverValue: NSTextField!
	@IBOutlet var ExcludePatternFile: NSTextField!
	@IBOutlet var ExcludePatternFileCS: NSButton!
	@IBOutlet var Compression: NSPopUpButton!
	@IBOutlet var ReadConcurrency: NSTextField!
	@IBOutlet var PackSize: NSTextField!
	
	
	@IBAction func ExcludeCaseSensitiveChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.exclusionsCS = true
		} else {
			selectedProfile?.exclusionsCS = false
		}
		
	}
	
	@IBAction func ExcludeFilesOverChanged(_ sender: NSButton) {
		if sender.state == .on {
			ExcludeFilesOverValue.isEnabled = true
			selectedProfile?.excludeMaxFilesize = ExcludeFilesOverValue.stringValue
		} else {
			ExcludeFilesOverValue.isEnabled = false
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
