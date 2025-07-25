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
	
	static let repolistFile: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			.appending(path: "ResticGUI", isDirectory: true)
			.appending(path: "Repositories.plist", isDirectory: false)
	}()
	
	private let encoder = PropertyListEncoder.init()
	private let decoder = PropertyListDecoder.init()
	
	static var `default`: ReposManager!
	override init() {
		super.init()
		if FileManager.default.fileExists(atPath: ReposManager.repolistFile.path) {
			do {
				repos = try decoder.decode(Dictionary<String, Repo>.self, from: Data.init(contentsOf: ReposManager.repolistFile))
			} catch {
				NSLog("Error loading profile: \(error)")
				STBAlerts.alert(title: "An error occured trying to load the list of repositories.", message: error.localizedDescription, style: .critical)
			}
		}
		ReposManager.default = self
		encoder.outputFormat = .xml
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
		let data = try encoder.encode(repos)
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
			try KeychainInterface.delete(path: repo.path)
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
	
	func get(name: String) -> Repo? {
		return repos[name]
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
		if let repoName = sender.titleOfSelectedItem {
			profileEditor.setSelectedRepo(repoName)
			if UserDefaults.standard.bool(forKey: DefaultsKeys.globalRepoSelection) {
				UserDefaults.standard.set(repoName, forKey: DefaultsKeys.selectedRepo)
			}
		}
	}
	
}
