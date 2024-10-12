//
//  RepoManager.swift
//  ResticGUI
//


import Foundation
import AppKit



class RepoEditViewController: NSViewController {
	
	var repoManager: ReposManager!
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
			nameField.stringValue = r.name ?? ""
			pathField.stringValue = r.path
			passwordField.stringValue = r.password
			cacheDirLabel.stringValue = r.cacheDir ?? ""
			cacheDirLabel.toolTip = r.cacheDir ?? ""
			saveButton.isEnabled = true
			createRepoButton.isEnabled = true
			testRepoButton.isEnabled = true
		} else {
			saveButton.isEnabled = false
			createRepoButton.isEnabled = false
			testRepoButton.isEnabled = false
			nameField.stringValue = ""
			passwordField.stringValue = ""
			cacheDirLabel.stringValue = ""
			cacheDirLabel.toolTip = ""
		}
	}
	
	
	@IBAction func choosePath(_ sender: NSButton) {
		let (urls, response) = openPanel(message: "Select the folder to use as the Restic repository.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, allowsMultipleSelection: false, canCreateDirectories: true)
		if response == NSApplication.ModalResponse.OK {
			if urls.count == 1 {
				pathField.stringValue = urls[0].path
			}
		}
	}
	
	@IBAction func chooseCacheDir(_ sender: NSButton) {
		let (urls, response) = openPanel(message: "Select the folder to use as the Restic cache directory.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, allowsMultipleSelection: false, canCreateDirectories: true)
		if response == NSApplication.ModalResponse.OK {
			if urls.count == 1 {
				cacheDirLabel.stringValue = urls[0].path
				cacheDirLabel.toolTip = urls[0].path
			}
		}
	}
	
	@IBAction func clearCacheDir(_ sender: NSButton) {
		cacheDirLabel.stringValue = ""
	}
	
	
	@IBAction func createRepo(_ sender: NSButton) {
		
	}
	
	@IBAction func testRepo(_ sender: NSButton) {
		
	}
	
	@IBAction func saveRepo(_ sender: NSButton) {
		if let r = selectedRepo {
			repoManager.remove(r)
			r.path = pathField.stringValue
			r.password = passwordField.stringValue
		} else {
			selectedRepo = Repo.init(path: pathField.stringValue, password: passwordField.stringValue)
		}
		
		if nameField.stringValue.count != 0 {
			selectedRepo!.name = nameField.stringValue
		} else {
			selectedRepo!.name = nil
		}
		if cacheDirLabel.stringValue.count != 0 {
			selectedRepo!.cacheDir = cacheDirLabel.stringValue
		} else {
			selectedRepo!.cacheDir = nil
		}
		// TODO: add env table.
		
		repoManager.add(selectedRepo!)
		selectedRepo = nil
		dismiss(self)
	}
	
	@objc func controlTextDidChange(_ sender: NSTextField) {
		let enable = pathField.stringValue.count != 0 && passwordField.stringValue.count != 0
		saveButton.isEnabled = enable
		createRepoButton.isEnabled = enable
		testRepoButton.isEnabled = enable
	}
	
}
