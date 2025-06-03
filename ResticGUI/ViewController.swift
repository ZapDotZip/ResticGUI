//
//  ViewController.swift
//  ResticGUI
//


import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
	
	@IBOutlet var profileEditor: ProfileEditorController!
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var repoEditButton: NSSegmentedControl!
	@IBOutlet weak var snapshotsTable: SnapshotsTable!
	
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	lazy var backupController: BackupController = appDel.backupController
	
	var bf = ByteCountFormatter.init()
		
// MARK: ViewController functionality
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.window?.title = "ResticGUI"
		
		appDel.viewFinishedLoading(vc: self)
		
		profileEditor.viewCon = self
		profileEditor.repoManager = repoManager
		profileSidebarList.append(ProfileOrHeader.init(header: "Profiles"))
		DeleteProfileButton.isEnabled = false
		let profileListMenu = NSMenu()
		profileListMenu.addItem(NSMenuItem(title: "Export Profile...", action: #selector(exportProfile(_:)), keyEquivalent: ""))
		outline.menu = profileListMenu
		
		// view data setup
		initSidebar(ProfileManager.loadAllProfiles())
		profileEditor.viewDidLoad()
		repoManager.initUIView()
		if let s = UserDefaults.standard.string(forKey: "LastSelectedProfile") {
			selectedProfile = ProfileManager.load(name: s)
			if let p = selectedProfile {
				outline.selectRowIndexes(IndexSet.init(integer: indexOfProfile(p.name) ?? 1), byExtendingSelection: false)
			}
		}
		scanAhead.state = UserDefaults.standard.bool(forKey: "Scan Ahead") ? .on : .off
		viewState = .noBackupInProgress
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
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
		
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue.identifier == "NewProfile" {
			let vc = segue.destinationController as! NewProfileVC
			vc.viewCon = self
		} else if segue.identifier == "RepoEdit" {
			let vc = segue.destinationController as! RepoEditViewController
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
			let deleteResponse = DestructiveAlert(title: "Delete profile \"\(p.name)\".", message: "Are you sure you want to delete the profile \"\(p.name)\"? It will be moved to your Trash.", style: .informational, destructiveButtonText: "Delete")
			if deleteResponse {
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
		if let selected = (outline.item(atRow: outline.selectedRow) as? ProfileOrHeader)?.profile {
			selected.name = sender.stringValue
		}
	}
	
	@IBAction @objc func exportProfile(_ sender: NSMenuItem) {
		if let selected = (outline.item(atRow: outline.selectedRow) as? ProfileOrHeader)?.profile {
			savePanel(for: self.view.window!, message: "Export Profile", nameFieldLabel: "Export As:", nameField: selected.name + ".plist", currentDirectory: nil, canCreateDirectories: true, canSelectHiddenExtension: true, isExtensionHidden: false, completionHandler: { res, url in
				if res == .OK || res == .continue, let destination = url {
					ProfileManager.save(selected, to: destination)
				}
			})
		}
	}
	
	@IBAction func importProfile(_ sender: NSMenuItem) {
		let (panel, res) = openPanel(message: "Select profile(s) to import.", prompt: "Import Profile", canChooseDirectories: false, canChooseFiles: true, allowsMultipleSelection: true, canCreateDirectories: false, allowedFileTypes: ["plist"])
		if res == .OK {
			let newProfiles = panel.urls.compactMap { url in
				if let profile = ProfileManager.load(url) {
					ProfileManager.save(profile)
					return profile
				}
				return nil
			}
			initSidebar(newProfiles)
			outline.reloadData()
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
			if let selectedRepo = repoManager.getSelectedRepo() {
				let res = DestructiveAlert(title: "Remove repository \"\(selectedRepo.getName())\"", message: "The repository will be removed from the list.", style: .informational, destructiveButtonText: "Delete")
				if res {
					do {
						do {
							try repoManager.remove(selectedRepo)
						} catch let error as KeychainInterface.KeychainError {
							let res = DestructiveAlert(title: "Unable to remove password from Keychain.", message: "The password for the repo you are trying to delete could not be removed from the keychain:\n\(error.errorDescription ?? "")\n\nDelete the repository anyways?", style: .warning, destructiveButtonText: "Delete")
							if res {
								try repoManager.remove(selectedRepo, removeFromKeychain: false)
							}
						}
					} catch {
						Alert(title: "An error occurred tryingt to save the repository list..", message: "\(error)", style: .critical, buttons: ["Ok"])
					}
				}
			}
		} else if sender.selectedSegment == 0 {
			self.performSegue(withIdentifier: "RepoEdit", sender: self)
		} else {
			self.performSegue(withIdentifier: "RepoEdit", sender: repoManager.getSelectedRepo())
		}
	}
	
	@IBOutlet weak var progressLabel: NSTextField!
	@IBOutlet weak var progressBar: NSProgressIndicator!
	@IBOutlet weak var runBackupButton: NSButton!
	@IBOutlet weak var scanAhead: NSButton!
	
	
	@IBAction func runBackup(_ sender: Any) {
		if backupController.state == .suspended {
			if backupController.resume() {
				viewState = .backupInProgress
			}
		} else if backupController.state == .inProgress {
			backupController.cancel()
			viewState = .noBackupInProgress
		} else {
			if let profile = selectedProfile {
				ProfileManager.save(profile)
				if let repo = repoManager.getSelectedRepo() {
					viewState = .backupStarting
					progressBar.isIndeterminate = scanAhead.state == .off
					backupController.backup(profile: profile, repo: repo, scanAhead: scanAhead.state == .on)
					viewState = .backupInProgress
				} else {
					Alert(title: "Please select a repository.", message: "You need to select a repository to back up to.", style: .informational, buttons: ["Ok"])
				}
			} else {
				Alert(title: "Please select a profile.", message: "You need to select a profile to back up.", style: .informational, buttons: ["Ok"])
			}
		}
	}
	
	enum ViewState {
		case noBackupInProgress
		case backupStarting
		case backupInProgress
		case backupPaused
		case finishedBackup
	}
	
	var viewState: ViewState = .noBackupInProgress {
		didSet {
			switch viewState {
				case .noBackupInProgress:
					progressBar.doubleValue = 0.0
					progressBar.maxValue = 1.0
					progressLabel.stringValue = ""
					runBackupButton.isEnabled = true
				case .backupStarting:
					progressBar.doubleValue = 0.0
					progressLabel.stringValue = ""
					runBackupButton.isEnabled = false
				case .backupInProgress:
					runBackupButton.title = "Cancel"
					runBackupButton.isEnabled = true
				case .backupPaused:
					runBackupButton.title = "Resume"
					runBackupButton.isEnabled = true
				case .finishedBackup:
					progressBar.doubleValue = 1.0
					progressLabel.stringValue = ""
					runBackupButton.isEnabled = true
			}
		}
	}
	
			
	var completedBackupPopover: NSPopover? = nil
	
	func completedBackup(_ summary: ResticResponse.backupSummary?) {
		progressBar.isIndeterminate = false
		if let sum = summary {
			progressBar.doubleValue = progressBar.maxValue
			progressLabel.stringValue = "Backup finished."
			completedBackupPopover = NSPopover()
			let text = """
			Files Processed: \(sum.total_files_processed)
			- Files Added: \(sum.files_new)
			- Files Changed: \(sum.files_changed)
			- Files Unmodified: \(sum.files_unmodified)
			- Directories Added: \(sum.dirs_new)
			- Directories Changed: \(sum.dirs_changed)
			- Directories Unmodified: \(sum.dirs_unmodified)
			Data Processed: \(bf.string(fromByteCount: Int64(sum.total_bytes_processed)))
			- Uncompressed Size: \(bf.string(fromByteCount: Int64(sum.data_added)))
			- Compressed Added: \(bf.string(fromByteCount: Int64(sum.data_added_packed)))
			- Blobs Added: \(sum.data_blobs), Tree Blobs Added: \(sum.tree_blobs)
			Total Duration: \(sum.total_duration ?? 0.0) seconds
			"""
			let label = NSTextField(wrappingLabelWithString: text)
			label.alignment = .left
			label.sizeToFit()
			let contentViewController = NSViewController()
			contentViewController.view = NSView(frame: label.frame)
			contentViewController.view.wantsLayer = true
			contentViewController.view.addSubview(label)
			completedBackupPopover!.contentViewController = contentViewController
			completedBackupPopover!.behavior = .transient
			completedBackupPopover!.show(relativeTo: progressBar.bounds, of: progressBar, preferredEdge: .maxY)
		} else {
			viewState = .noBackupInProgress
			progressLabel.stringValue = "Summary details are unavailable for the last backup."
			completedBackupPopover = nil
		}
		runBackupButton.title = "Start Backup"
	}
	
	
	
	func setMessage(_ text: String) {
		progressLabel.stringValue = text
	}
	
	func setMessageButtonEnable(_ text: String, _ enabled: Bool) {
		progressLabel.stringValue = text
		runBackupButton.isEnabled = enabled
	}
	
	func displayProgress(_ text: String?, _ progress: Double) {
		if text != nil {
			progressLabel.stringValue = text!
		}
		progressBar.doubleValue = progress
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


class ResponsiveProgressBar: NSProgressIndicator {
	@IBOutlet var viewCon: ViewController!
	override func mouseUp(with event: NSEvent) {
		if let popover = viewCon.completedBackupPopover {
			popover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
		}
	}
}
