//
//  ProfileEditor.swift
//  ResticGUI
//

import Cocoa

/// Controls the editor panel in the UI.
class ProfileEditorController: NSView {
	
	var viewCon: ViewController!
	var repoManager: ReposManager!
	
	func viewDidLoad() {
		ExcludeTextView.font = NSFont.init(name: "Menlo", size: 12)
		BackupPathsDS.viewCon = viewCon
	}
	
	@IBOutlet var BackupPathsDS: BackupPathsDataSource!
	var selectedProfile: Profile?
	
	
// MARK: Profile Tabs: setup
	/// Configures the UI based off the provided profile. Saves the existing profile if selected and modified.
	/// - Parameter profile: The profile to load.
	func setupMainEditorView(profile: Profile) {
		// save the existing profile if it has been modified
		if let prof = selectedProfile {
			ProfileManager.save(prof)
		}
		viewCon.view.window?.title = profile.name
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
		if let selectedRepo = profile.selectedRepo {
			repoManager.setSelectedRepo(title: selectedRepo)
		}
		
		
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
	
	
	func setSelectedRepo(_ repo: String) {
		selectedProfile?.selectedRepo = repo
	}

    
}
