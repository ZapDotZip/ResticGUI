//
//  ReposManager.swift
//  ResticGUI
//

import Foundation
import AppKit
import SwiftToolbox

class ReposManager: NSObject {
	private var repos = Dictionary<String, Repo>()
	
	@IBOutlet weak var RepoMenu: NSPopUpButton!
	@IBOutlet weak var repoEditControl: NSSegmentedControl!
	@IBOutlet weak var profileEditor: ProfileEditorController!
	
	static let repolistFile: URL = AppDelegate.appSupportDirectory.appending(path: "Repositories.plist", isDirectory: false)
	
	static var `default`: ReposManager!
	override init() {
		super.init()
		if FileManager.default.fileExists(atPath: ReposManager.repolistFile.path) {
			do {
				repos = try AppDelegate.plistDecoder.decode(Dictionary<String, Repo>.self, from: Data.init(contentsOf: ReposManager.repolistFile))
			} catch {
				NSLog("Error loading profile: \(error)")
				STBAlerts.alert(title: "An error occured trying to load the list of repositories.", message: nil, error: error)
			}
		}
		ReposManager.default = self
	}
	
	
	func initUIView() {
		guard repos.count != 0 else {
			repoEditControl.setEnabled(false, forSegment: 1)
			repoEditControl.setEnabled(false, forSegment: 2)
			return
		}
		fillMenu()
		if UserDefaults.standard.bool(forKey: DefaultsKeys.globalRepoSelection), let selected = UserDefaults.standard.string(forKey: DefaultsKeys.selectedRepo), repos[selected] != nil {
			RepoMenu.selectItem(withTitle: selected)
		}
	}
	
	func fillMenu() {
		RepoMenu.addItems(withTitles: repos.keys.sorted())
	}
	
	/// Saves the repository list.
	func save() throws {
		let data = try AppDelegate.plistEncoderXML.encode(repos)
		try data.write(to: ReposManager.repolistFile)
	}
	
	/// Adds a new repo to the repo list. Does not save keychain passwords.
	/// - Parameter repo: The repo to add to the list.
	func add(_ repo: Repo) throws {
		let name = repo.getName()
		repos[name] = repo
		RepoMenu.addItem(withTitle: name)
		setSelectedRepo(title: name)
		try save()
		repoEditControl.setEnabled(true, forSegment: 1)
		repoEditControl.setEnabled(true, forSegment: 2)
	}
	
	/// Updates an existing repository.
	/// - Parameters:
	///   - oldRepoName: The repo name before the update.
	///   - newRepo: the updated repository
	func update(oldRepoName: String, updatedRepo: Repo) throws {
		if updatedRepo.getName() != oldRepoName {
			repos.removeValue(forKey: oldRepoName)
			RepoMenu.removeItem(withTitle: oldRepoName)
		} else {
			repos[oldRepoName] = updatedRepo
		}
		try save()
		repoEditControl.setEnabled(true, forSegment: 1)
		repoEditControl.setEnabled(true, forSegment: 2)
	}
	
	/// Removes the repo from the repo list. Does not delete the repo itself.
	/// - Parameter repo: The repo to remove.
	func remove(_ repo: Repo, removeFromKeychain: Bool = true) throws {
		if removeFromKeychain {
			try STBKeychain.delete(path: repo.path)
		}
		
		let name = repo.getName()
		repos.removeValue(forKey: name)
		RepoMenu.removeItem(withTitle: name)
		if repos.count == 0 {
			repoEditControl.setEnabled(false, forSegment: 1)
			repoEditControl.setEnabled(false, forSegment: 2)
		}
		try save()
	}
	
	func getSelectedRepo() -> Repo? {
		return repos[RepoMenu.titleOfSelectedItem ?? ""]
	}
	
	func setSelectedRepo(title: String) {
		if repos[title] != nil {
			RepoMenu.selectItem(withTitle: title)
		}
	}
	
	@IBAction func selectorDidChange(_ sender: NSPopUpButton) {
		guard let selectedRepo = getSelectedRepo() else { return }
		profileEditor.setSelectedRepo(selectedRepo)
		if UserDefaults.standard.bool(forKey: DefaultsKeys.globalRepoSelection) {
			UserDefaults.standard.set(selectedRepo.getName(), forKey: DefaultsKeys.selectedRepo)
		}
	}
	
}
