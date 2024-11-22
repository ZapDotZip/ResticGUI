//
//  ReposManager.swift
//  ResticGUI
//

import Foundation
import AppKit

class ReposManager: NSObject {
	private var repos = Dictionary<String, Repo>()
	
	@IBOutlet weak var RepoMenu: NSPopUpButton!
	@IBOutlet weak var repoEditControl: NSSegmentedControl!
	@IBOutlet weak var profileEditor: ProfileEditorController!
	
	let repolistFile: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Repositories.plist", isDirectory: false)
	}()
	
	private let encoder = PropertyListEncoder.init()
	private let decoder = PropertyListDecoder.init()
	
	static var `default`: ReposManager!
	override init() {
		super.init()
		if FileManager.default.fileExists(atPath: repolistFile.path) {
			do {
				repos = try decoder.decode(Dictionary<String, Repo>.self, from: Data.init(contentsOf: repolistFile))
			} catch {
				NSLog("Error loading profile: \(error)")
				Alert(title: "An error occured trying to load the list of repositories.", message: error.localizedDescription, style: .critical, buttons: ["Ok"])
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
		if UserDefaults.standard.bool(forKey: "Global Repo Selection"), let selected = UserDefaults.standard.string(forKey: "Selected Repo"), repos[selected] != nil {
			RepoMenu.selectItem(withTitle: selected)
		}
	}
	
	func fillMenu() {
		RepoMenu.addItems(withTitles: repos.keys.sorted())
	}
	
	/// Saves the repository list.
	func save() {
		do {
			let data = try encoder.encode(repos)
			try data.write(to: repolistFile)
		} catch {
			NSLog("Error saving repository list: \(error)")
			Alert(title: "An error occured trying to save repository list.", message: error.localizedDescription, style: .critical, buttons: ["Ok"])
		}
	}
	
	/// Adds or overwrites a repo to the repo list. Saves the repo aferwards.
	/// - Parameter repo: The repo to add to the list.
	func add(_ repo: Repo) {
		let name: String = repo.name ?? repo.path
		repos[name] = repo
		fillMenu()
		setSelectedRepo(title: name)
		save()
		repoEditControl.setEnabled(true, forSegment: 1)
		repoEditControl.setEnabled(true, forSegment: 2)
	}
	
	/// Removes the repo from the repo list. Does not delete the repo itself.
	/// - Parameter repo: The repo to remove.
	func remove(_ repo: Repo) {
		let name: String = repo.name ?? repo.path
		repos.removeValue(forKey: name)
		RepoMenu.removeItem(withTitle: name)
		if repos.count == 0 {
			repoEditControl.setEnabled(false, forSegment: 1)
			repoEditControl.setEnabled(false, forSegment: 2)
		}
		save()
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
		profileEditor.setSelectedRepo(sender.titleOfSelectedItem!)
	}
	
	
	
}
