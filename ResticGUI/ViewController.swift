//
//  ViewController.swift
//  ResticGUI
//


import Cocoa
import SwiftToolbox

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
		initSidebar(ProfileManager.getProfilesList())
		repoManager.initUIView()
		if let s = UserDefaults.standard.string(forKey: DefaultsKeys.lastSelectedProfile), let index = indexOfProfile(s) {
			selectedProfile = loadWithError(named: s)
			if let p = selectedProfile {
				outline.selectRowIndexes(IndexSet.init(integer: index), byExtendingSelection: false)
			}
		}
		scanAhead.state = UserDefaults.standard.bool(forKey: DefaultsKeys.scanAhead) ? .on : .off
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
			if poh.profile == name {
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
		} else if segue.identifier == "Restore" {
			let vc = segue.destinationController as! RestoreViewController
			vc.snapshotToRestore = snapshotsTable.selectedSnapshot
			vc.repo = repoManager.getSelectedRepo()
		} else {
			NSLog("Error: segue \"\(segue.identifier ?? "nil")\" not properly set up!")
		}
	}
	
	func saveQuit() {
		saveSelectedProfile()
	}
	
	
	
// MARK: Profile Sidebar
	@IBOutlet var outline: NSOutlineView!
	@IBOutlet var DeleteProfileButton: NSButton!
	var selectedProfile: Profile?
	
	func newProfile(name: String) -> Bool {
		guard !profileSidebarList.contains(where: { $0.profile == name }) else {
			STBAlerts.alert(title: "This profile name already exists.", message: "Choose a different profile name.", style: .informational)
			return false
		}
		let new = Profile.init(name: name)
		append(profile: new)
		saveWithError(new)
		outline.selectRowIndexes(IndexSet.init(integer: indexOfProfile(new.name) ?? 1), byExtendingSelection: false)
		return true
	}
	
	@IBAction func deleteProfile(_ sender: NSButton) {
		guard let profile = selectedProfile?.name else { return }
		
		var index = (indexOfProfile(profile) ?? 0) - 1
		if index <= 0 {
			index = 1
		}
		let deleteResponse = STBAlerts.destructiveAlert(title: "Delete profile \"\(profile)\"?", message: "Are you sure you want to delete the profile \"\(profile)\"? It will be moved to your Trash.", style: .informational, destructiveButtonText: "Delete")
		if deleteResponse {
			ProfileManager.delete(profile)
			profileSidebarList = profileSidebarList.filter { (poh) -> Bool in
				if let profile = poh.profile {
					return profile != profile
				}
				return true
			}
			outline.removeItems(at: [index], inParent: nil)
//			outline.reloadData()
			selectedProfile = nil
			if profileSidebarList.count == 1 {
				performSegue(withIdentifier: "NewProfile", sender: sender)
			} else {
				outline.selectRowIndexes(IndexSet.init(integer: index), byExtendingSelection: false)
			}
		} else {
			NSLog("Delete cancelled")
		}
	}
	
	func editProfileName(_ sender: NSTextField) {
		if let selected = (outline.item(atRow: outline.selectedRow) as? ProfileOrHeader)?.profile {
			if selectedProfile?.name == selected {
				saveSelectedProfile()
			}
			do {
				try ProfileManager.rename(from: selected, to: sender.stringValue)
			} catch {
				STBAlerts.alert(title: "Couldn't rename profile.", message: "An error occured while trying to change the profile named \"\(selected)\" to \"\(sender.stringValue)\"", error: error, style: .critical)
			}
		}
	}
	
	@IBAction @objc func exportProfile(_ sender: NSMenuItem) {
		guard let selected = (outline.item(atRow: outline.selectedRow) as? ProfileOrHeader)?.profile,
				let profile = try? ProfileManager.load(named: selected) else {
			return
		}
		STBFilePanels.savePanelModal(for: self.view.window!, nameFieldLabel: "Export As", nameField: selected + ".plist", isExtensionHidden: true, allowedFileExtensions: ["plist"], completionHandler: { url in
			if let url {
				do {
					try ProfileManager.save(profile, to: url)
				} catch {
					STBAlerts.alert(title: "Couldn't export profile.", message: "An error occured while trying to export the profile named \"\(selected)\"", error: error, style: .critical)
				}
			}
		})
	}
	
	@IBAction func importProfile(_ sender: NSMenuItem) {
		if let urls = STBFilePanels.openPanel(message: "Select profile(s) to import.", prompt: "Import Profile", canSelectMultipleItems: true, canCreateDirectories: false, selectableTypes: [.files(["plist"])]) {
			let newProfiles = urls.compactMap { url in
				if let profile = ProfileManager.load(url) {
					do {
						try ProfileManager.save(profile)
						return profile.name
					} catch {
						STBAlerts.alert(title: "Couldn't load profile", message: "Failed to load the profile located at \(url.localPath). Tge profile may be corrupt, or invalid.", error: error, style: .critical)
					}
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
		profileSidebarList.append(ProfileOrHeader.init(profile: profile.name))
		profileSidebarList.sort { (a, b) -> Bool in
			if let ap = a.profile, let bp = b.profile {
				return ap < bp
			}
			return false
		}
		outline.reloadData()
	}
	
	func initSidebar(_ newProfiles: [String]) {
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
			profilesCellView.textField?.stringValue = (item as! ProfileOrHeader).profile!
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
		saveSelectedProfile()
		guard let selected = outline.item(atRow: outline.selectedRow) as? ProfileOrHeader, let p = selected.profile else {
			DeleteProfileButton.isEnabled = false
			self.view.window?.title = "ResticGUI"
			return
		}
		DeleteProfileButton.isEnabled = true
		if let profile = loadWithError(named: p) {
			profileEditor.setupMainEditorView(profile: profile)
			selectedProfile = profile
			UserDefaults.standard.set(profile.name, forKey: DefaultsKeys.lastSelectedProfile)
		}
	}
	
	func saveSelectedProfile() {
		if let p = selectedProfile {
			do {
				try ProfileManager.save(p)
			} catch {
				NSLog("Couldn't save profile: \(error)")
				STBAlerts.alert(title: "An error occured trying to save the current profile.", message: "The profile \"\(p.name)\" could not be saved:\n\n\(error.localizedDescription)", style: .critical)
			}
		}
	}
	
	func saveWithError(_ profile: Profile) {
		do {
			try ProfileManager.save(profile)
		} catch {
			NSLog("Couldn't save profile: \(error)")
			STBAlerts.alert(title: "An error occured trying to save the profile.", message: "The profile \"\(profile.name)\" could not be saved.", error: error,style: .critical)
		}
	}
	
	private func loadWithError(named: String) -> Profile? {
		do {
			return try ProfileManager.load(named: named)
		} catch {
			DispatchQueue.main.async {
				STBAlerts.alert(title: "An error occured trying to load a profile", message: "The profile \"\(named)\" could not be loaded.", error: error, style: .critical)
			}
			return nil
		}
	}
	
	@IBAction func saveProfile(_ sender: NSMenuItem) {
		self.view.window?.makeFirstResponder(self) // removes control from text fields
		saveSelectedProfile()
	}
	
	@IBAction func newProfile(_ sender: NSMenuItem) {
		performSegue(withIdentifier: "NewProfile", sender: sender)
	}
	
	@IBAction func revertToSaved(_ sender: NSMenuItem) {
		guard let selectedProfile else { return }
		guard let saved = loadWithError(named: selectedProfile.name) else { return }
		profileEditor.setupMainEditorView(profile: saved)
	}
	
	@IBAction func repoEditButton(_ sender: NSSegmentedControl) {
		if sender.selectedSegment == 1 {
			guard let selectedRepo = repoManager.getSelectedRepo() else { return }
			if STBAlerts.destructiveAlert(title: "Remove repository \"\(selectedRepo.getName())\"", message: "The repository will be removed from the list.", style: .informational, destructiveButtonText: "Delete") {
				do {
					do {
						try repoManager.remove(selectedRepo)
					} catch let error as STBKeychainError {
						let deletingRepoKeychainError = STBAlerts.destructiveAlert(title: "Unable to remove password from Keychain.", message: "The password for the repo you are trying to delete could not be removed from the keychain:\n\(error.errorDescription ?? "")\n\nDelete the repository anyways?", style: .warning, destructiveButtonText: "Delete")
						if deletingRepoKeychainError {
							try repoManager.remove(selectedRepo, removeFromKeychain: false)
						}
					}
				} catch {
					STBAlerts.alert(title: "An error occurred trying to save the repository list.", message: nil, error: error, style: .critical)
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
				saveSelectedProfile()
				if let repo = repoManager.getSelectedRepo() {
					viewState = .backupStarting
					progressBar.isIndeterminate = scanAhead.state == .off
					backupController.backup(profile: profile, repo: repo, scanAhead: scanAhead.state == .on)
					viewState = .backupInProgress
				} else {
					STBAlerts.alert(title: "Please select a repository.", message: "You need to select a repository to back up to.", style: .informational)
				}
			} else {
				STBAlerts.alert(title: "Please select a profile.", message: "You need to select a profile to back up.", style: .informational)
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
			Total Duration: \(String(format: "%.2f", sum.total_duration ?? 0.0)) seconds
			"""
			let label = NSTextField(wrappingLabelWithString: text)
			label.alignment = .left
			label.sizeToFit()
			label.translatesAutoresizingMaskIntoConstraints = false
			let contentViewController = NSViewController()
			let viewFrame = NSRect(x: 0, y: 0, width: label.frame.width + 16, height: label.frame.height + 16)
			contentViewController.view = NSView(frame: viewFrame)
			contentViewController.view.wantsLayer = true
			contentViewController.view.addSubview(label)
			completedBackupPopover!.contentViewController = contentViewController
			completedBackupPopover!.behavior = .semitransient
			NSLayoutConstraint.activate([
				label.topAnchor.constraint(equalTo: contentViewController.view.topAnchor, constant: 8),
				label.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor, constant: -8),
				label.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor, constant: -8),
				label.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor, constant: 8)
			])
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



class ResponsiveProgressBar: NSProgressIndicator {
	@IBOutlet var viewCon: ViewController!
	override func mouseUp(with event: NSEvent) {
		if let popover = viewCon.completedBackupPopover {
			popover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
		}
	}
}
