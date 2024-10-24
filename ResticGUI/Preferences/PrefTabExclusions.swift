//
//  PrefsTabExclusions.swift
//  ResticGUI
//

import Cocoa

class PrefTabExclusions: NSViewController {

	
	@IBOutlet var ExcludeTextView: NSTextView!
	@IBOutlet weak var ExcludeFileLabel: NSTextField!
	@IBOutlet weak var ExcludeFileClearButton: NSButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        ExcludeTextView.font = NSFont.init(name: "Menlo", size: 12)
		if let path = UserDefaults.standard.string(forKey: "GlobalExcludeFile") {
			ExcludeFileLabel.stringValue = path
			ExcludeFileClearButton.isEnabled = true
		}
    }
	@IBAction func excludePatternFile(_ sender: NSButton) {
		let (panel, res) = openPanel(message: "Select an exclude pattern file.", prompt: "Select", canChooseDirectories: false, canChooseFiles: true, allowsMultipleSelection: false, canCreateDirectories: false)
		if res == .OK && panel.urls.count != 0 {
			UserDefaults.standard.set(panel.urls[0], forKey: "GlobalExcludeFile")
			ExcludeFileLabel.stringValue = panel.urls[0].path
			ExcludeFileClearButton.isEnabled = true
		}
	}
	
	@IBAction func excludePatternFileClear(_ sender: NSButton) {
		UserDefaults.standard.set(nil, forKey: "GlobalExcludeFile")
		ExcludeFileLabel.stringValue = ""
		ExcludeFileClearButton.isEnabled = true
	}
	
}
