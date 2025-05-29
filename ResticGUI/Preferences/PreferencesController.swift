//
//  PreferencesViewController.swift
//  ResticGUI
//

import AppKit

class PreferencesTabController: NSTabViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabViewItems[1].image = NSImage.init(byReferencingFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarDeleteIcon.icns")
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window!.title = "Preferences"
	}
	
}
