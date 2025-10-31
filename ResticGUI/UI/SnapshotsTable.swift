//
//  SnapshotsDataSource.swift
//  ResticGUI
//

import Cocoa
import SwiftToolbox
import SwiftProcessController

class SnapshotsTable: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var repoManager: ReposManager!
	@IBOutlet var viewCon: ViewController!
	
	@IBOutlet var table: NSTableView!
	@IBOutlet var reloadButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	
	private enum State {
		case notLoading
		case loading
	}
	
	
	private var loadState: State = .notLoading {
		didSet {
			switch loadState {
			case .notLoading:
				progressIndicator.stopAnimation(self)
			case .loading:
				progressIndicator.startAnimation(self)
			}
			reloadButton.isEnabled = loadState == .notLoading
			mountButton.isEnabled = loadState == .notLoading
		}
	}
	
	private var snapshots: [ResticResponse.Snapshot] = []
	private let df = DateFormatter()
	private let byteFmt = ByteCountFormatter()
	
	private static let cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "ResticGUI", isDirectory: true).appending(path: "Snapshots", isDirectory: true)
	
	required init?(coder: NSCoder) {
		df.locale = .autoupdatingCurrent
		super.init(coder: coder)
		UserDefaults.standard.addObserver(self, forKeyPath: DefaultsKeys.snapshotDateFormat, options: .new, context: nil)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == DefaultsKeys.snapshotDateFormat {
			reload()
		}
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int { return snapshots.count }
	
	func reload() {
		if let userDF = UserDefaults.standard.string(forKey: DefaultsKeys.snapshotDateFormat), userDF != "" {
			df.dateFormat = userDF
		} else {
			df.dateFormat = "YYYY-MM-dd 'at' h:mm a"
		}
		table.reloadData()
	}
	
	@IBAction func reloadButton(_ sender: NSButton) {
		guard let selectedRepo = repoManager.getSelectedRepo(),
				let selectedProfile = viewCon.selectedProfile else { return }
		loadState = .loading
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try self.load(selectedRepo, selectedProfile)
				DispatchQueue.main.async { self.afterLoad() }
			} catch {
				DispatchQueue.main.async { self.loadError(error) }
			}
		}
	}
	
	/// Called when an error occurs during loading.
	private func loadError(_ error: Error) {
		NSLog("Couldn't load snapshots: \(error)")
		loadState = .notLoading
		STBAlerts.alert(title: "Unable to load snapshots", message: nil, error: error, style: .critical)
	}
	
	/// Gets the list of snapshots for a repository from Restic.
	/// - Parameters:
	///   - selectedRepo: The repository to load snapshots from.
	///   - selectedProfile: The profile to filter snapshots with.
	func load(_ selectedRepo: Repo, _ selectedProfile: Profile) throws {
		let loaded = try ResticController.default.getSnapshots(for: selectedRepo)
		saveToCache(loaded, for: selectedRepo)
		snapshots = loaded.filter({ (snap) -> Bool in
			return snap.tags?.contains(selectedProfile.name) ?? false
		})
	}
	
	/// Reloads the table after loading.
	private func afterLoad() {
		reload()
		loadState = .notLoading
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let column = tableColumn,
				let cell = tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView else {
			NSLog("\(#function) cell with \(tableColumn?.identifier.rawValue ?? "nil") couldn't be made.")
			return nil
		}
		switch column.identifier.rawValue {
			case "Date & Time": cell.textField!.stringValue = df.string(from: snapshots[row].date)
			case "Tags": cell.textField!.stringValue = snapshots[row].tags?.joined(separator: ", ") ?? ""
			case "Size": cell.textField!.stringValue = byteFmt.string(fromByteCount: Int64(snapshots[row].summary.data_added_packed))
			default:
				NSLog("\(#function) recieved unknown identifier \(column.identifier)")
				cell.textField!.stringValue = "Unknown Error"
		}
		return cell
	}
	
	@IBOutlet var restoreButton: NSButton!
	
	private var mc: MountCoordinator?
	
	@IBOutlet var mountButton: NSButton!
	@IBAction func mountButton(_ sender: NSButton) {
		guard mc == nil else {
			if let mc {
				loadState = .loading
				ResticController.default.dq.async {
					mc.eject()
				}
			} else {
				STBAlerts.alert(title: "Repository is already mounted", message: "An unknown error occurred.", style: .informational)
			}
			return
		}
		guard let repo = repoManager.getSelectedRepo() else {
			NSLog("Unable to setup mount because repo was nil!")
			return
		}
		guard let mountPoint = STBFilePanels.openPanel(message: "Select a directory to mount the repository at.", canSelectMultipleItems: false, canCreateDirectories: true, selectableTypes: [.directories])?.first else { return }
		
		loadState = .loading
		mc = MountCoordinator()
		guard let mc else { return }
		mc.ui = self
		ResticController.default.dq.async { [self] in
			do {
				try mc.mount(repo: repo, to: mountPoint)
			} catch {
				DispatchQueue.main.async { [self] in
					STBAlerts.alert(title: "Unable to mount repository", message: "Could not run restic to mount the repository.", error: error, style: .warning)
					loadState = .notLoading
				}
			}
		}
	}
	
	func mountPointDidMount() {
		DispatchQueue.main.async { [self] in
			loadState = .notLoading
			mountButton.title = "Unmount repository"
			if let mp = mc?.mountPoint {
				NSWorkspace.shared.open(mp)
			}
		}
	}
	
	func mountPointError(msg: String) {
		DispatchQueue.main.async { [self] in
			loadState = .notLoading
			mountButton.isEnabled = true
			mountButton.title = "Mount repository..."
		}
	}
	
	func mountPointExited(with error: RGError? = nil) {
		DispatchQueue.main.async { [self] in
			if let error {
				STBAlerts.alert(title: "Failed to mount repository", message: "Restic returned an error trying to mount the repository.", error: error, style: .warning)
			}
			mountButton.isEnabled = true
			mountButton.title = "Mount repository..."
			loadState = .notLoading
			mc = nil
		}
	}
	
	@IBOutlet var deleteButton: NSButton!
	@IBAction func deleteButton(_ sender: NSButton) {
		
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		if table.selectedRowIndexes.count == 0 {
			restoreButton.isEnabled = false
			deleteButton.isEnabled = false
		} else if table.selectedRowIndexes.count == 1 {
			restoreButton.isEnabled = true
			deleteButton.isEnabled = true
		} else {
			restoreButton.isEnabled = false
			deleteButton.isEnabled = true
		}
	}
	
	/// The currently selected snapshot in the table.
	public var selectedSnapshot: ResticResponse.Snapshot? { return snapshots[table.selectedRow] }
	
	/// Returns the full URL path for the repository snapshot cache.
	private func getSnapshotCacheURL(repo: Repo) -> URL? {
		guard let repoID = repo.id else {
			RGLogger.default.log("Unable to load/save snapshot caches for repo \"\(repo.path)\" because it does not have an ID.")
			return nil
		}
		return SnapshotsTable.cacheDirectory.appending(path: repoID, isDirectory: false)
	}
	
	/// Loads the snapshots from cache asynchronously.
	/// - Parameters:
	///   - profile: The profile to filter snapshots with.
	///   - repo: The repository of snapshots to load.
	func loadIfCached(for profile: Profile, repo: Repo) {
		loadState = .loading
		DispatchQueue.global(qos: .utility).async {
			self.loadFromFileCache(for: profile, repo: repo)
			DispatchQueue.main.async {
				self.afterLoad()
			}
		}
	}
	
	/// Loads snapshots from cache, if possible.
	/// - Parameters:
	///   - profile: The profile to filter snapshots with.
	///   - repo: The repository of snapshots to load.
	private func loadFromFileCache(for profile: Profile, repo: Repo) {
		guard let sc = getSnapshotCacheURL(repo: repo), FileManager.default.fileExists(atPath: sc.path) else {
			snapshots = []
			return
		}
		do {
			let data = try Data.init(contentsOf: sc)
			snapshots = try AppDelegate.plistDecoder.decode([ResticResponse.Snapshot].self, from: data).filter({ (snap) -> Bool in
				return snap.tags?.contains(profile.name) ?? false
			})
		} catch {
			RGLogger.default.log("\(#function) was unable to load the snapshot cache \(error)")
		}
	}
	
	/// Writes the provided snapshot list to disk cache.
	/// - Parameters:
	///   - list: The snapshot list to save.
	///   - repo: The repo to save the cache for.
	private func saveToCache(_ list: [ResticResponse.Snapshot], for repo: Repo) {
		guard let id = repo.loadID() else { return }
		let sc = SnapshotsTable.cacheDirectory.appending(path: id, isDirectory: false)
		do {
			let data = try AppDelegate.plistEncoderBinary.encode(list)
			try FileManager.default.createDirectory(at: SnapshotsTable.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
			try data.write(to: sc)
		} catch {
			RGLogger.default.log("\(#function) was unable to save the snapshot cache \(error)")
		}
	}
	
}
