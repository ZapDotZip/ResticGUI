//
//  RepoManager.swift
//  ResticGUI
//


import AppKit
import SwiftToolbox



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
					Alerts.Alert(title: "Unable to get password from keychain", message: "The password could not be loaded from the keychain:\n\n\(error.errorDescription ?? "")", style: .critical, buttons: [])
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
		if let url = FileDialogues.openPanel(message: "Select the folder to use as the Restic repository.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, canSelectMultipleItems: false, canCreateDirectories: true)?.first {
			pathField.stringValue = url.localPath
		}
	}
	
	@IBAction func chooseCacheDir(_ sender: NSButton) {
		if let url = FileDialogues.openPanel(message: "Select the folder to use as the Restic cache directory.", prompt: "Use this folder", canChooseDirectories: true, canChooseFiles: false, canSelectMultipleItems: false, canCreateDirectories: true)?.first {
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
				let response = try self.createRepo(repo)
				DispatchQueue.main.async {
					NSLog("Created repository response: \(response)")
					self.controlTextDidChange(self)
					self.progressIndicator.stopAnimation(self)
					Alerts.Alert(title: "Successfully created repository.", message: "The repository at \(response.repository) has been created.", style: .informational)
					self.saveRepo(sender)
				}
			} catch {
				DispatchQueue.main.async { self.createRepoError(error) }
			}
		}
	}
	
	func createRepo(_ repo: Repo) throws -> ResticResponse.RepoInitResponse {
		let pr = ProcessRunner(executableURL: try ResticController.default.getResticURL())
		pr.env = try repo.getEnv()
		pr.qualityOfService = .userInitiated
		let result = try pr.run(args: ["--json", "-r", repo.path, "init"])
		if let response = try? ResticController.default.jsonDecoder.decode(ResticResponse.RepoInitResponse.self, from: result.output) {
			return response
		} else {
			let response = try ResticController.default.jsonDecoder.decode(ResticResponse.resticError.self, from: result.error)
			throw ResticError.resticErrorMessage(message: response.getMessage, code: response.code ?? -1, stderr: result.errorString())
		}
	}
	
	func createRepoError(_ error: Error) {
		controlTextDidChange(self)
		progressIndicator.stopAnimation(self)
		if let err = error as? ResticError {
			NSLog("Couldn't create repository: \(error)")
			Alerts.Alert(title: "An error occured trying to create the repository.", message: err.description, style: .critical)
		} else {
			NSLog("Couldn't create repository: \(error)")
			Alerts.Alert(title: "An error occured trying to create the repository.", message: "The error was:\n\n\(error.localizedDescription)", style: .critical)
		}
	}
	
	@IBAction func testRepo(_ sender: NSButton) {
		let repo = repoFromUI()
		do {
			let res = try ResticInterface.repoTest(repo: repo, rc: resticController)
			if !res {
				Alerts.Alert(title: "The repository exists, but may not be the correct version.", message: "ResticGUI currently supports version 2 repositories.", style: .informational)
			}
		} catch ResticError.couldNotDecodeJSON(let rawStr, let error) {
			NSLog("Error testing repository: \(rawStr)\n\(error)")
			Alerts.Alert(title: "Failed to test repository", message: "Your version of Restic may not be supported, or there may be errors in the configuration preventing the repository from being opened:\n\n\(error)", style: .warning)
		} catch {
			NSLog("Error testing repository: \(error)")
			Alerts.Alert(title: "Failed to test repository", message: "There may be errors in the configuration preventing the repository from being opened:\n\n\(error)", style: .warning)
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
		} catch let error as KeychainInterface.KeychainError {
			switch error {
			case .itemNotFound:
					Alerts.Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error:\n\n\(error.localizedDescription)", style: .critical)
			case .duplicateItem:
				if Alerts.DestructiveAlert(title: "The password for this repository path already exists.", message: "Overwrite?", style: .warning, destructiveButtonText: "Overwrite") {
					do {
						try KeychainInterface.delete(path: pathField.stringValue)
						Alerts.Alert(title: "Duplicate Entry Deleted", message: "The keychain item for this path has been deleted.\n\nPlease try saving again.", style: .informational)
					} catch {
						Alerts.Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain: \n\n\(error.localizedDescription)", style: .critical)
					}
				} else {
					return
				}
			default:
				Alerts.Alert(title: "The password could not be saved.", message: "The repository password could not be saved in the Keychain due to an error: \n\n\(error.localizedDescription)", style: .critical)
				return
			}
			
		} catch {
			NSLog("Error saving the repository list: \(error)")
			Alerts.Alert(title: "An error occured trying to save repository list.", message: error.localizedDescription, style: .critical)
			return
		}
	}
	
	@objc func controlTextDidChange(_ sender: NSTextField) {
		let enable = pathField.stringValue.count != 0 && passwordField.stringValue.count != 0
		saveButton.isEnabled = enable
		createRepoButton.isEnabled = enable
		testRepoButton.isEnabled = enable
	}
	
}
