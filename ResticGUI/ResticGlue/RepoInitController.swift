//
//  BackupController.swift
//  ResticGUI
//

import Foundation

final class RepoInitController {
	static func repoInit(repo: Repo, rc: ResticController) throws -> (RepoInitResponse, String?) {
		let args: [String] = ["--json", "-r", repo.path, "init"]
		var env = repo.env ?? [String : String]()
		env["RESTIC_PASSWORD"] = repo.password
		let (res, stderr) = try rc.run(args: args, env: env, returning: RepoInitResponse.self)
		return (res, stderr)
	}
	
	//{"message_type":"initialized","id":"...","repository":"..."}
	struct RepoInitResponse: Decodable {
		var message_type: String
		var id: String
		var repository: String
	}
}
