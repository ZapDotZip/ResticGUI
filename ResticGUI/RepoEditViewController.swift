//
//  RepoManager.swift
//  ResticGUI
//


import Foundation
import AppKit



class RepoEditViewController: NSViewController {
	
	var viewCon: ViewController!
	var selectedRepo: Repo?
	
	@IBOutlet var pathField: NSTextField!
	private var pathFilled = false
	@IBOutlet var passwordField: NSSecureTextField!
	private var passFilled = false
	@IBOutlet var saveButton: NSButton!
	@IBOutlet var createRepoButton: NSButton!
	@IBOutlet var testRepoButton: NSButton!
	@IBOutlet var cacheDirLabel: NSTextField!
	@IBOutlet var nameField: NSTextField!
	
	
	override func viewDidLoad() {
		if let customCache = UserDefaults.standard.string(forKey: "Cache Directory") {
			cacheDirLabel.stringValue = "App Default (\(customCache))"
		}
		if let r = selectedRepo {
			if r.name != nil {
				nameField.stringValue = r.name!
			}
			pathField.stringValue = r.path
			passwordField.stringValue = r.password
			if r.cacheDir != nil {
				cacheDirLabel.stringValue = r.cacheDir!
			}
		}
	}
	
	
	@IBAction func choosePath(_ sender: NSButton) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.allowsMultipleSelection = false
		openPanel.canCreateDirectories = true
		openPanel.message = "Select the folder to use as the Restic repository."
		openPanel.prompt = "Use this folder"
		if openPanel.runModal() == NSApplication.ModalResponse.OK {
			if openPanel.urls.count == 1 {
				pathField.stringValue = openPanel.urls[0].path
			}
		}
	}
	
	@IBAction func chooseCacheDir(_ sender: NSButton) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.allowsMultipleSelection = false
		openPanel.canCreateDirectories = true
		openPanel.message = "Select the folder to use as the Restic cache directory."
		openPanel.prompt = "Use this folder"
		if openPanel.runModal() == NSApplication.ModalResponse.OK {
			if openPanel.urls.count == 1 {
				cacheDirLabel.stringValue = openPanel.urls[0].path
			}
		}
	}
	
	@IBAction func createRepo(_ sender: NSButton) {
		
	}
	
	@IBAction func testRepo(_ sender: NSButton) {
		
	}
	
	@IBAction func saveRepo(_ sender: NSButton) {
		if let r = selectedRepo {
			r.path = pathField.stringValue
			r.password = passwordField.stringValue
		} else {
			selectedRepo = Repo.init(path: pathField.stringValue, password: passwordField.stringValue)
		}
		if nameField.stringValue.count != 0 {
			selectedRepo!.name = nameField.stringValue
		}
		if cacheDirLabel.stringValue.count != 0 {
			selectedRepo!.cacheDir = cacheDirLabel.stringValue
		}
		// TODO: add env table.
		
		viewCon.ProfileEditor.addRepo(selectedRepo!)
	}
	
	@objc func controlTextDidChange(_ sender: NSTextField) {
		let enable = pathField.stringValue.count != 0 && passwordField.stringValue.count != 0
		saveButton.isEnabled = enable
		createRepoButton.isEnabled = enable
		testRepoButton.isEnabled = enable
	}
	
	func rename(_ profile: Profile) {
		// TODO: Implement
	}
	
	func copy(_ profile: Profile) {
		// TODO: Implement
	}
	
	
}

