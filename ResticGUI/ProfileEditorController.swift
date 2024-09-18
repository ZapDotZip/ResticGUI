//
//  ProfileEditor.swift
//  ResticGUI
//

import Cocoa

/// Controls the editor panel in the UI.
class ProfileEditorController: NSView, NSTextViewDelegate {
	
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
		if let selectedRepo = profile.selectedRepo {
			repoManager.setSelectedRepo(title: selectedRepo)
		}
		
		
	}
	
	func setSelectedRepo(_ repo: String) {
		selectedProfile?.selectedRepo = repo
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
			ExcludeFilesOverValue.stringValue = selectedProfile?.excludeMaxFilesize ?? ""
			ExcludeFilesOverValue.becomeFirstResponder()
		} else {
			ExcludeFilesOverValue.isEnabled = false
			selectedProfile?.excludeMaxFilesize = nil
		}
	}
	
	@IBAction func ExcludeFilesOverValueChanged(_ sender: NSTextField) {
		selectedProfile?.excludeMaxFilesize = sender.stringValue
	}
	
	
	@IBAction func ExcludeCacheDirectoriesChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.excludeCacheDirs = true
		} else {
			selectedProfile?.excludeCacheDirs = false
		}
	}
	
	@IBAction func ExcludeTMDefaultChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.excludesTMDefault = true
		} else {
			selectedProfile?.excludesTMDefault = false
		}
	}
	
	@IBAction func ExcludeTMUserChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.excludesTMUser = true
		} else {
			selectedProfile?.excludesTMUser = false
		}
	}
	
	@IBAction func setExcludeFile(_ sender: NSButton) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.allowsMultipleSelection = false
		openPanel.canCreateDirectories = false
		openPanel.message = "Select your exclude pattern file."
		openPanel.prompt = "Select"
		if openPanel.runModal() == NSApplication.ModalResponse.OK, openPanel.urls.count != 0 {
			selectedProfile?.excludePatternFile = openPanel.urls[0].path
			ExcludePatternFile.stringValue = openPanel.urls[0].path
			ExcludePatternFileClearButton.isEnabled = true
		}
	}
	
	@IBAction func removeExcludeFile(_ sender: NSButton) {
		ExcludePatternFile.stringValue = ""
		selectedProfile?.excludePatternFile = nil
		ExcludePatternFileClearButton.isEnabled = false
	}
	
	@IBAction func ExcludePatternFileCSChanged(_ sender: NSButton) {
		if sender.state == .on {
			selectedProfile?.excludePatternFileCS = true
		} else {
			selectedProfile?.excludePatternFileCS = false
		}
	}
	
	@IBAction func CompressionChanged(_ sender: NSPopUpButton) {
		if let type = sender.selectedItem?.title {
			selectedProfile?.compression = type
		}
	}

	@IBAction func ReadConcurrencyChanged(_ sender: NSTextField) {
		if let val = Int(sender.stringValue) {
			selectedProfile?.readConcurrency = val
		} else if sender.stringValue.count == 0 {
			selectedProfile?.readConcurrency = nil
		}
	}
	
	@IBAction func PackSizeChanged(_ sender: NSTextField) {
		if let val = Int(sender.stringValue) {
			selectedProfile?.packSize = val
		} else if sender.stringValue.count == 0 {
			selectedProfile?.packSize = nil
		}
	}
	
	func textDidEndEditing(_ notification: Notification) {
		selectedProfile?.exclusions = ExcludeTextView.string
	}

	
	

    
}

final class NumbersTextField: NumberFormatter {
	override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		if let _ = UInt64(partialString) {
			return true
		}
		return partialString.count == 0
	}
}
