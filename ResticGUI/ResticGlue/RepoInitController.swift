//
//  BackupController.swift
//  ResticGUI
//

import Foundation

/// Used to create new repositories.
final class RepoInitController {
	static func repoInit(repo: Repo, rc: ResticController) throws -> (RepoInitResponse, String?) {
		let args: [String] = ["--json", "-r", repo.path, "init"]
		let (res, stderr) = try rc.run(args: args, env: repo.getEnv(), returning: RepoInitResponse.self)
		return (res, stderr)
	}
	
	struct RepoInitResponse: Decodable {
		let message_type: String
		let id: String
		let repository: String
	}
}
