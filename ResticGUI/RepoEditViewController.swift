//
//  RepoManager.swift
//  ResticGUI
//


import AppKit
import SwiftToolbox
import SwiftProcessController



class RepoEditViewController: NSViewController {
	
	let repoManager = ReposManager.default!
	var selectedRepo: Repo?
	private let appDel: AppDelegate = (NSApplication.shared.delegate as! AppDelegate)
	lazy var resticController = ResticController.default
	
	@IBOutlet var pathField: NSTextField!
	private var pathFilled = false
	@IBOutlet var passwordField: NSSecureTextField!
	private var passFilled = false
	@IBOutlet var saveButton: NSButton!
	@IBOutlet var createRepoButton: NSButton!
	@IBOutlet var testRepoButton: NSButton!
	@IBOutlet var cacheDirLabel: NSTextField!
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	
	@IBOutlet weak var tableView: EnviormentTableView!
	
	override func viewDidLoad() {
		if let customCache = UserDefaults.standard.string(forKey: DefaultsKeys.cacheDirectory) {
			cacheDirLabel.stringValue = "App Default (\(customCache))"
		}
		if let r = selectedRepo {
			nameField.stringValue = r.name ?? ""
			pathField.stringValue = r.path
			do {
				passwordField.stringValue = try r.getPassword()
			} catch {
				passwordField.stringValue = ""
				DispatchQueue.main.async {
					STBAlerts.alert(title: "Unable to get password from keychain", message: "The password could not be loaded from the keychain:\n\n\(error.errorDescription ?? "")", style: .critical, buttons: [])
				}
			}
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
		if let url = STBFilePanels.openPanel(message: "Select the folder to use as the Restic repository.", canSelectMultipleItems: false, canCreateDirectories: true, selectableTypes: [.directories])?.first {
			pathField.stringValue = url.localPath
		}
	}
	
	@IBAction func chooseCacheDir(_ sender: NSButton) {
		if let url = STBFilePanels.openPanel(message: "Select the folder to use as the Restic cache directory.", canSelectMultipleItems: false, canCreateDirectories: true, selectableTypes: [.directories])?.first {
			cacheDirLabel.stringValue = url.localPath
			cacheDirLabel.toolTip = url.localPath
		}
	}
	
	@IBAction func clearCacheDir(_ sender: NSButton) {
		cacheDirLabel.stringValue = ""
	}
	
	
	@IBAction func createRepo(_ sender: NSButton) {
		let repo = repoFromUI()
		progressIndicator.startAnimation(self)
		saveButton.isEnabled = false
		createRepoButton.isEnabled = false
		testRepoButton.isEnabled = false
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let response = try ResticController.default.run(args: ["--json", "-r", repo.path, "init"], env: try repo.getEnv(), returning: ResticResponse.RepoInitResponse.self)
				DispatchQueue.main.async {
					NSLog("Created repository response: \(response)")
					self.controlTextDidChange(self)
					self.progressIndicator.stopAnimation(self)
					STBAlerts.alert(title: "Successfully created repository.", message: "The repository at \(response.repository) has been created.", style: .informational)
					self.saveRepo(sender)
				}
			} catch {
				DispatchQueue.main.async { self.asyncErrorHandler(error, tryingTo: "create") }
			}
		}
	}
	
	func asyncErrorHandler(_ error: Error, tryingTo: String) {
		controlTextDidChange(self)
		progressIndicator.stopAnimation(self)
		if let err = error as? RGError {
			NSLog("Couldn't create repository: \(error)")
			STBAlerts.alert(title: "An error occured trying to \(tryingTo) the repository.", message: err.description, style: .critical)
		} else {
			NSLog("Couldn't create repository: \(error)")
			STBAlerts.alert(title: "An error occured trying to \(tryingTo) the repository.", message: "The error was:\n\n\(error.localizedDescription)", style: .critical)
		}
	}
	
	@IBAction func testRepo(_ sender: NSButton) {
		let repo = repoFromUI()
		progressIndicator.startAnimation(self)
		saveButton.isEnabled = false
		createRepoButton.isEnabled = false
		testRepoButton.isEnabled = false
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let response = try ResticController.default.run(args: ["--json", "-r", repo.path, "cat", "config"], env: try repo.getEnv(), returning: ResticResponse.RepoConfig.self)
				guard response.version == 2 else {
					throw RGError.unsupportedRepositoryVersion(version: response.version)
				}
				DispatchQueue.main.async { [self] in
					progressIndicator.stopAnimation(self)
					controlTextDidChange(self)
					STBAlerts.alert(title: "Repository successfully accessed", message: "The repository located at \(repo.path) is accessible.\n\nRepository ID: \(response.id)", style: .informational)
				}
			} catch {
				DispatchQueue.main.async { self.asyncErrorHandler(error, tryingTo: "test") }
			}
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
	
	func updateExistingRepo(existing: Repo) throws(STBKeychainError) {
		if existing.path != pathField.stringValue {
			try existing.updatePath(newPath: pathField.stringValue)
		}
		if existing.cachedPassword != passwordField.stringValue {
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
		do {
			if let existing = selectedRepo {
				try updateExistingRepo(existing: existing)
				try repoManager.save()
			} else {
				let newRepo = repoFromUI()
				try repoManager.add(newRepo)
				try newRepo.saveNewPassword(newPass: passwordField.stringValue)
			}
			selectedRepo = nil
			dismiss(self)
		} catch let error as STBKeychainError {
			switch error {
			case .itemNotFound:
					STBAlerts.alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error:\n\n\(error.localizedDescription)", style: .critical)
			case .duplicateItem:
				if STBAlerts.destructiveAlert(title: "The password for this repository path already exists.", message: "Overwrite?", style: .warning, destructiveButtonText: "Overwrite") {
					do {
						try STBKeychain.delete(path: pathField.stringValue)
						STBAlerts.alert(title: "Duplicate Entry Deleted", message: "The keychain item for this path has been deleted.\n\nPlease try saving again.", style: .informational)
					} catch {
						STBAlerts.alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain: \n\n\(error.localizedDescription)", style: .critical)
					}
				} else {
					return
				}
			default:
				STBAlerts.alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error: \n\n\(error.localizedDescription)", style: .critical)
				return
			}
			
		} catch {
			NSLog("Error saving the repository list: \(error)")
			STBAlerts.alert(title: "An error occured trying to save repository list.", message: error.localizedDescription, style: .critical)
			return
		}
	}
	
	@objc func controlTextDidChange(_ sender: Any) {
		let enable = pathField.stringValue.count != 0 && passwordField.stringValue.count != 0
		saveButton.isEnabled = enable
		createRepoButton.isEnabled = enable
		testRepoButton.isEnabled = enable
	}
	
}
