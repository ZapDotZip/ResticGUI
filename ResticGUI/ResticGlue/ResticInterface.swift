//
//  BackupController.swift
//  ResticGUI
//

import Foundation

/// A simpler interface for calling specific restic functions.
final class ResticInterface {
	/// Calls Restic to create a new repository.
	/// - Parameters:
	///   - repo: The repository to create.
	///   - rc: The ResticController.
	/// - Returns: The response from Restic, the Standard Error as a String.
	static func repoInit(repo: Repo, rc: ResticController) throws -> (ResticResponse.RepoInitResponse, String?) {
		let args: [String] = ["--json", "-r", repo.path, "init"]
		let (res, stderr) = try rc.run(args: args, env: repo.getEnv(), returning: ResticResponse.RepoInitResponse.self)
		return (res, stderr)
	}
	
	static func repoTest(repo: Repo, rc: ResticController) throws -> Bool {
		let args = ["--json", "-r", repo.path, "cat", "config"]
		let res = try rc.run(args: args, env: repo.getEnv(), returning: ResticResponse.RepoConfig.self).0
		return res.version == 2
	}
	
}
