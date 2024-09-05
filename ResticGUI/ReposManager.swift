//
//  ReposManager.swift
//  ResticGUI
//

import Foundation
import AppKit

class ReposManager: NSObject {
	private var repolist = Dictionary<String, Repo>()
	
	@IBOutlet weak var RepoMenu: NSPopUpButton!
	@IBOutlet weak var repoEditControl: NSSegmentedControl!
	
	let repolistFile: URL = {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ResticGUI", isDirectory: true).appendingPathComponent("Repositories.plist", isDirectory: false)
	}()
	
	let encoder = PropertyListEncoder.init()
	
	override init() {
		super.init()
		if FileManager.default.fileExists(atPath: repolistFile.path) {
			let decoder = PropertyListDecoder.init()
			do {
				repolist = try decoder.decode(Dictionary<String, Repo>.self, from: Data.init(contentsOf: repolistFile))
			} catch {
				NSLog("Error loading profile: \(error)")
				let alert = NSAlert()
				alert.messageText = "An error occured trying to load the list of repositories."
				alert.informativeText = "\(error.localizedDescription)"
				alert.alertStyle = .critical
				alert.addButton(withTitle: "Ok")
				alert.runModal()
			}
		}
	}
	
	func initUIView() {
		guard repolist.count != 0 else {
			repoEditControl.setEnabled(false, forSegment: 2)
			return
		}
		fillMenu()
		if UserDefaults.standard.bool(forKey: "Global Repo Selection"), let selected = UserDefaults.standard.string(forKey: "Selected Repo") {
			RepoMenu.selectItem(withTitle: selected)
		}
	}
	
	func fillMenu() {
		for i in repolist.keys.sorted() {
			RepoMenu.addItem(withTitle: i)
		}
	}
	
	/// Saves the repository list.
	func save() {
		do {
			let data = try encoder.encode(repolist)
			try data.write(to: repolistFile)
		} catch {
			NSLog("Error saving Profile: \(error)")
			let alert = NSAlert()
			alert.messageText = "An error occured trying to save repository list."
			alert.informativeText = "\(error.localizedDescription)"
			alert.alertStyle = .critical
			alert.addButton(withTitle: "Ok")
			alert.runModal()
		}
	}
	
	/// Adds or overwrites a repo to the repo list. Saves the repo aferwards.
	/// - Parameter repo: The repo to add to the list.
	func add(_ repo: Repo) {
		let name: String = repo.name ?? repo.path
		repolist[name] = repo
		fillMenu()
		setSelectedItem(title: name)
		save()
	}
	
	/// Removes the repo from the repo list. Does not delete the repo itself.
	/// - Parameter repo: The repo to remove.
	func remove(_ repo: Repo) {
		let name: String = repo.name ?? repo.path
		repolist.removeValue(forKey: name)
		RepoMenu.removeItem(withTitle: name)
	}
	
	func get(name: String) -> Repo? {
		return repolist[name]
	}
	
	func getSelectedRepo() -> Repo? {
		return repolist[RepoMenu.titleOfSelectedItem ?? ""]
	}
	
	func setSelectedItem(title: String) {
		RepoMenu.selectItem(withTitle: title)
	}
	
	
}
