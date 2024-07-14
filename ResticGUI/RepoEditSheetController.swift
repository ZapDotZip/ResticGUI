//
//  RepoEditSheetController.swift
//  ResticGUI
//

import Cocoa

class RepoEditSheetController: NSViewController {
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	@IBAction func closeSheet(_ sender: NSButton) {
		self.dismiss(nil)
	}
	
	@IBAction func saveSheet(_ sender: NSButton) {
		// TODO: save contents
		self.dismiss(nil)
	}
	
}
