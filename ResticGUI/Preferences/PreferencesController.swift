//
//  PreferencesViewController.swift
//  ResticGUI
//

import AppKit

class PreferencesTabController: NSTabViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabViewItems[1].image = NSImage.init(byReferencingFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarDeleteIcon.icns")
		tabViewItems[3].image = NSImage.init(byReferencingFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns")
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		selectedTabViewItemIndex = UserDefaults.standard.integer(forKey: DefaultsKeys.prefWindowLastTab)
		self.view.window!.title = "Preferences"
	}
	
	var calls = 0
	override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelect: tabViewItem)
		if calls > 1 {
			UserDefaults.standard.set(selectedTabViewItemIndex, forKey: DefaultsKeys.prefWindowLastTab)
		} else {
			calls += 1
		}
	}
	
}
