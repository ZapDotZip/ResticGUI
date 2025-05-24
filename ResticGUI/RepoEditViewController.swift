//
//  RepoManager.swift
//  ResticGUI
//


import Foundation
import AppKit



class RepoEditViewController: NSViewController {
	
	let repoManager = ReposManager.default!
	var selectedRepo: Repo?
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	lazy var resticController = appDel.resticController!
	
	@IBOutlet var pathField: NSTextField!
	private var pathFilled = false
	@IBOutlet var passwordField: NSSecureTextField!
	private var passFilled = false
	@IBOutlet var saveButton: NSButton!
	@IBOutlet var createRepoButton: NSButton!
	@IBOutlet var testRepoButton: NSButton!
	@IBOutlet var cacheDirLabel: NSTextField!
	@IBOutlet var nameField: NSTextField!
	
	@IBOutlet weak var tableView: EnviormentTableView!
	
	override func viewDidLoad() {
		if let customCache = UserDefaults.standard.string(forKey: "Cache Directory") {
			cacheDirLabel.stringValue = "App Default (\(customCache))"
		}
		if let r = selectedRepo {
			nameField.stringValue = r.name ?? ""
			pathField.stringValue = r.path
			r.setPassword(passwordField.stringValue)
			cacheDirLabel.stringValue = r.cacheDir ?? ""
			cacheDirLabel.toolTip = r.cacheDir ?? ""
			saveButton.isEnabled = true
			createRepoButton.isEnabled = true
			testRepoButton.isEnabled = true
			tableView.table.load(r.env)
		} else {
			saveButton.isEnabled = false
			createRepoButton.isEnabled = false
			testRepoButton.isEnabled = false
			nameField.stringValue = ""
			passwordField.stringValue = ""
			cacheDirLabel.stringValue = ""
			cacheDirLabel.toolTip = ""
			tableView.table.load(nil)
		}
	}
	
	
	@IBAction func selectFolder(_ sender: NSButton) {
		let (panel, response) = openPanel(message: "Select the folder to use as the Restic repository.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, allowsMultipleSelection: false, canCreateDirectories: true)
		if response == NSApplication.ModalResponse.OK {
			if panel.urls.count == 1 {
				pathField.stringValue = panel.urls[0].path
				
			}
		}
	}
	
	@IBAction func chooseCacheDir(_ sender: NSButton) {
		let (panel, response) = openPanel(message: "Select the folder to use as the Restic cache directory.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, allowsMultipleSelection: false, canCreateDirectories: true)
		if response == NSApplication.ModalResponse.OK {
			if panel.urls.count == 1 {
				cacheDirLabel.stringValue = panel.urls[0].path
				cacheDirLabel.toolTip = panel.urls[0].path
			}
		}
	}
	
	@IBAction func clearCacheDir(_ sender: NSButton) {
		cacheDirLabel.stringValue = ""
	}
	
	
	@IBAction func createRepo(_ sender: NSButton) {
		let repo = repoFromUI()
		do {
			let (res, _) = try ResticInterface.repoInit(repo: repo, rc: resticController)
			NSLog("Created repository response: \(res)")
			Alert(title: "Successfully created repository.", message: "The repository at \(res.repository) has been created.", style: .informational, buttons: ["Ok"])
			saveRepo(sender)
		} catch let error as ResticError {
			let errMsg: String = {
				switch error {
				case .couldNotDecodeJSON( _, let stderr):
					return stderr
				default:
					return error.localizedDescription
				}
			}()
			NSLog("Couldn't create repository: \(error)")
			Alert(title: "An error occured trying to create the repository.", message: "The error message was:\n\n\(errMsg)", style: .critical, buttons: ["Ok"])
		} catch {
			NSLog("Couldn't create repository: \(error)")
			Alert(title: "An error occured trying to create the repository.", message: "The error message was:\n\n\(error)", style: .critical, buttons: ["Ok"])
		}
	}
	
	@IBAction func testRepo(_ sender: NSButton) {
		let repo = repoFromUI()
		do {
			let res = try ResticInterface.repoTest(repo: repo, rc: resticController)
			if !res {
				Alert(title: "The repository exists, but may not be the correct version.", message: "ResticGUI currently supports version 2 repositories.", style: .informational, buttons: ["Ok"])
			}
		} catch ResticError.couldNotDecodeJSON(let rawStr, let error) {
			NSLog("Error testing repository: \(rawStr)\n\(error)")
			Alert(title: "Failed to test repository", message: "Your version of Restic may not be supported, or there may be errors in the configuration preventing the repository from being opened:\n\n\(error)", style: .warning, buttons: ["Ok"])
		} catch {
			NSLog("Error testing repository: \(error)")
			Alert(title: "Failed to test repository", message: "There may be errors in the configuration preventing the repository from being opened:\n\n\(error)", style: .warning, buttons: ["Ok"])
		}
	}
	
	func repoFromUI() -> Repo {
		let repo = Repo(path: pathField.stringValue, noKeychain: passwordField.stringValue)
		if nameField.stringValue.count != 0 {
			repo.name = nameField.stringValue
		}
		if cacheDirLabel.stringValue.count != 0 {
			repo.cacheDir = cacheDirLabel.stringValue
		}
		if let env = tableView.table.save() {
			repo.env = env
		}
		return repo
	}
	
	func updateExistingRepo(existing: Repo) throws(KeychainInterface.KeychainError) {
		if existing.path != pathField.stringValue {
			try existing.updatePath(newPath: pathField.stringValue)
		}
		if existing.cachedPassword! != passwordField.stringValue {
			try existing.updatePassword(newPass: passwordField.stringValue)
		}
		if nameField.stringValue.count != 0 {
			existing.name = nameField.stringValue
		} else {
			existing.name = nil
		}
		if cacheDirLabel.stringValue.count != 0 {
			existing.cacheDir = cacheDirLabel.stringValue
		} else {
			existing.cacheDir = nil
		}
		if let env = tableView.table.save() {
			existing.env = env
		} else {
			existing.env = nil
		}
	}
	
	@IBAction func saveRepo(_ sender: NSButton) {
		var existingPath: String = pathField.stringValue
		do {
			if let existing = selectedRepo {
				try updateExistingRepo(existing: existing)
			} else {
				let newRepo = repoFromUI()
				try repoManager.add(newRepo)
				try newRepo.saveNewPassword(newPass: passwordField.stringValue)
			}
		} catch let error as KeychainInterface.KeychainError {
			switch error {
			case .itemNotFound:
				Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error: \n\n\(error.localizedDescription)", style: .critical, buttons: ["Ok"])
			case .duplicateItem:
				let res = Alert(title: "The password for this repository path already exists.", message: "Overwrite?", style: .warning, buttons: ["Ok", "Cancel"])
				if res == .alertFirstButtonReturn {
					do {
						try KeychainInterface.delete(path: existingPath)
						Alert(title: "Duplicate Entry Deleted", message: "The keychain item for this path has been deleted. Please try saving again.", style: .informational, buttons: ["Ok"])
					} catch {
						Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain: \n\n\(error.localizedDescription)", style: .critical, buttons: ["Ok"])
					}
				} else {
					return
				}
			default:
				Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error: \n\n\(error.localizedDescription)", style: .critical, buttons: ["Ok"])
				return
			}
			
		} catch {
			NSLog("Error saving the repository list: \(error)")
			Alert(title: "An error occured trying to save repository list.", message: error.localizedDescription, style: .critical, buttons: ["Ok"])
			return
		}
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
