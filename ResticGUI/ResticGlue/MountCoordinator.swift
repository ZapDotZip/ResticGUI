//
//  MountCoordinator.swift
//  ResticGUI
//

import Foundation
import SwiftProcessController

class MountCoordinator: SPCDelegate {
	
	private var currentlyRunningProcess: SPCController?
	
	public var ui: SnapshotsTable?
	public var mountPoint: URL?
	
	private let goDF = "2006-01-02 at 03-04-05 PM"
	
	func mount(repo: Repo, to mountPoint: URL) throws {
		self.mountPoint = mountPoint
		let restic = SPCController(executableURL: try ResticController.default.getResticURL(), delegate: self)
		restic.env = try repo.getEnv()
		restic.qualityOfService = .default
		let args = ["mount", mountPoint.localPath, "--time-template", goDF]
		RGLogger.default.run(process: restic, args: args)
		try restic.launch(args: args)
		currentlyRunningProcess = restic
	}
	
	
	func stdoutHandler(_ data: Data) {
		guard let str = String(data: data, encoding: .utf8) else { return }
		if str.contains("Now serving the repository at") {
			ui?.mountPointDidMount()
		}
	}
	
	func stderrHandler(_ data: Data) {
		guard let str = String(data: data, encoding: .utf8) else { return }
		ui?.mountPointError(msg: str)
	}
	
	func terminationHandler(exitCode: Int32) {
		if exitCode == 130 {
			ui?.mountPointExited()
		}
		ui?.mountPointExited(with: RGError.init(exitCode: exitCode))
	}
	
	func eject() {
		currentlyRunningProcess?.interrupt()
	}
	
}
