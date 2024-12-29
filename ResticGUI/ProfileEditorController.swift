//
//  ProfileEditor.swift
//  ResticGUI
//

import Cocoa

/// Controls the editor panel in the UI.
class ProfileEditorController: NSView, NSTextViewDelegate, NSTabViewDelegate {
	
	@IBOutlet var TabView: NSTabView!
	@IBOutlet var snapshotsTable: SnapshotsTable!
	var viewCon: ViewController!
	var repoManager: ReposManager!
	
	func viewDidLoad() {
		ExcludeTextView.font = NSFont.init(name: "Menlo", size: 12)
		BackupPathsDS.viewCon = viewCon
		TabView.selectTabViewItem(at: UserDefaults.standard.integer(forKey: "ProfileEditorTabIndex"))
	}
	
	func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		for (i, tvi) in TabView.tabViewItems.enumerated() {
			if tvi == tabViewItem {
				UserDefaults.standard.set(i, forKey: "ProfileEditorTabIndex")
				break
			}
		}
	}
	
	@IBOutlet var BackupPathsDS: BackupPathsDataSource!
	
	
// MARK: Profile Tabs: setup
	/// Configures the UI based off the provided profile. Saves the existing profile if selected and modified.
	/// - Parameter profile: The profile to load.
	func setupMainEditorView(profile: Profile) {
		// save the existing profile if it has been modified
		if let prof = viewCon.selectedProfile {
			ProfileManager.save(prof)
		}
		viewCon.view.window?.title = profile.name
		viewCon.selectedProfile = profile
		BackupPathsDS.load(fromProfile: profile)
		ExcludeTextView.string = profile.exclusions ?? ""
		ExcludeCaseSensitive.state = profile.exclusionsCS ? .on : .off
		ExcludeCacheDirs.state = profile.excludeCacheDirs ? .on : .off
		if let val = profile.excludeMaxFilesize {
			ExcludeFilesOver.state = .on
			ExcludeFilesOverValue.stringValue = val
		} else {
			ExcludeFilesOver.state = .off
			ExcludeFilesOverValue.stringValue = ""
		}
		
		ExcludeTMDefault.state = profile.excludesTMDefault ? .on : .off
		ExcludeTMUser.state = profile.excludesTMUser ? .on : .off
		ExcludePatternFile.stringValue = profile.excludePatternFile ?? ""
		ExcludePatternFileClearButton.isEnabled = ExcludePatternFile.stringValue.count != 0
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
		if let selectedRepo = profile.selectedRepo, !UserDefaults.standard.bool(forKey: "Global Repo Selection") {
			repoManager.setSelectedRepo(title: selectedRepo)
		}
		
		TagField.objectValue = profile.tags
		snapshotsTable.loadIfCached()
		
	}
	
	func setSelectedRepo(_ repo: String) {
		viewCon.selectedProfile?.selectedRepo = repo
		snapshotsTable.loadIfCached()
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
	@IBOutlet var ExcludePatternFileClearButton: NSButton!
	@IBOutlet var ExcludePatternFileCS: NSButton!
	@IBOutlet var Compression: NSPopUpButton!
	@IBOutlet var ReadConcurrency: NSTextField!
	@IBOutlet var PackSize: NSTextField!
	@IBOutlet var TagField: NSTokenField!
	
	@IBAction func ExcludeCaseSensitiveChanged(_ sender: NSButton) {
		if sender.state == .on {
			viewCon.selectedProfile?.exclusionsCS = true
		} else {
			viewCon.selectedProfile?.exclusionsCS = false
		}
		
	}
	
	@IBAction func ExcludeFilesOverChanged(_ sender: NSButton) {
		if sender.state == .on {
			ExcludeFilesOverValue.isEnabled = true
			ExcludeFilesOverValue.stringValue = viewCon.selectedProfile?.excludeMaxFilesize ?? ""
			ExcludeFilesOverValue.becomeFirstResponder()
		} else {
			ExcludeFilesOverValue.isEnabled = false
			viewCon.selectedProfile?.excludeMaxFilesize = nil
		}
	}
	
	@IBAction func ExcludeFilesOverValueChanged(_ sender: NSTextField) {
		viewCon.selectedProfile?.excludeMaxFilesize = sender.stringValue
	}
	
	
	@IBAction func ExcludeCacheDirectoriesChanged(_ sender: NSButton) {
		if sender.state == .on {
			viewCon.selectedProfile?.excludeCacheDirs = true
		} else {
			viewCon.selectedProfile?.excludeCacheDirs = false
		}
	}
	
	@IBAction func ExcludeTMDefaultChanged(_ sender: NSButton) {
		if sender.state == .on {
			viewCon.selectedProfile?.excludesTMDefault = true
		} else {
			viewCon.selectedProfile?.excludesTMDefault = false
		}
	}
	
	@IBAction func ExcludeTMUserChanged(_ sender: NSButton) {
		if sender.state == .on {
			viewCon.selectedProfile?.excludesTMUser = true
		} else {
			viewCon.selectedProfile?.excludesTMUser = false
		}
	}
	
	@IBAction func setExcludeFile(_ sender: NSButton) {
		let (panel, response) = openPanel(message: "Select your exclude pattern file.", prompt: "Select", canChooseDirectories: false, canChooseFiles: true, allowsMultipleSelection: false, canCreateDirectories: false)
		if response == NSApplication.ModalResponse.OK, panel.urls.count != 0 {
			viewCon.selectedProfile?.excludePatternFile = panel.urls[0].path
			ExcludePatternFile.stringValue = panel.urls[0].path
			ExcludePatternFileClearButton.isEnabled = true
		}
	}
	
	@IBAction func removeExcludeFile(_ sender: NSButton) {
		ExcludePatternFile.stringValue = ""
		viewCon.selectedProfile?.excludePatternFile = nil
		ExcludePatternFileClearButton.isEnabled = false
	}
	
	@IBAction func ExcludePatternFileCSChanged(_ sender: NSButton) {
		if sender.state == .on {
			viewCon.selectedProfile?.excludePatternFileCS = true
		} else {
			viewCon.selectedProfile?.excludePatternFileCS = false
		}
	}
	
	@IBAction func CompressionChanged(_ sender: NSPopUpButton) {
		if let type = sender.selectedItem?.title {
			viewCon.selectedProfile?.compression = type
		}
	}

	@IBAction func ReadConcurrencyChanged(_ sender: NSTextField) {
		if let val = UInt(sender.stringValue) {
			viewCon.selectedProfile?.readConcurrency = val
		} else if sender.stringValue.count == 0 {
			viewCon.selectedProfile?.readConcurrency = nil
		}
	}
	
	@IBAction func PackSizeChanged(_ sender: NSTextField) {
		if let val = Int(sender.stringValue) {
			viewCon.selectedProfile?.packSize = val
		} else if sender.stringValue.count == 0 {
			viewCon.selectedProfile?.packSize = nil
		}
	}
	
	func textDidEndEditing(_ notification: Notification) {
		viewCon.selectedProfile?.exclusions = ExcludeTextView.string
	}

	@IBAction func tagFieldDidChange(_ sender: NSTextField) {
		viewCon.selectedProfile!.tags = TagField.objectValue as! [String]
	}
	

    
}

final class NumbersTextField: NumberFormatter {
	override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		if UInt64(partialString) != nil {
			return true
		}
		return partialString.count == 0
	}
}
