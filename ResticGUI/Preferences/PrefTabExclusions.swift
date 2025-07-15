//
//  PrefsTabExclusions.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox


class PrefTabExclusions: NSViewController {

	
	@IBOutlet var ExcludeTextView: NSTextView!
	@IBOutlet weak var ExcludeFileLabel: NSTextField!
	@IBOutlet weak var ExcludeFileClearButton: NSButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        ExcludeTextView.font = NSFont.init(name: "Menlo", size: 12)
		if let path = UserDefaults.standard.string(forKey: DefaultsKeys.globalExcludePatternFile) {
			ExcludeFileLabel.stringValue = path
			ExcludeFileClearButton.isEnabled = true
		}
    }
	@IBAction func excludePatternFile(_ sender: NSButton) {
		if let url = FileDialogues.openPanel(message: "Select an exclude pattern file.", prompt: "Select", canChooseDirectories: false, canChooseFiles: true, canSelectMultipleItems: false, canCreateDirectories: false)?.first {
			UserDefaults.standard.set(url, forKey: DefaultsKeys.globalExcludePatternFile)
			ExcludeFileLabel.stringValue = url.localPath
			ExcludeFileClearButton.isEnabled = true
		}
	}
	
	@IBAction func excludePatternFileClear(_ sender: NSButton) {
		UserDefaults.standard.set(nil, forKey: DefaultsKeys.globalExcludePatternFile)
		ExcludeFileLabel.stringValue = ""
		ExcludeFileClearButton.isEnabled = true
	}
	
}
