//
//  RGError.swift
//  ResticGUI
//

import Foundation

enum RGError: Error, CustomStringConvertible, LocalizedError {
	case couldNotDecodeOutput(Error?)
	case noResticInstallationsFound(String)
	case unsupportedRepositoryVersion(version: Int)
	case resticErrorMessage(message: String?, code: Int?, stderr: String?)
	case exitCode(code: Int32, description: String)
	case unknownError(message: String?)
	case osError(message: String, description: String)
	
	init(from rError: ResticResponse.error) {
		self = .resticErrorMessage(message: rError.getMessage(), code: rError.code, stderr: nil)
	}
	
	/// Decodes from a failed ``SPCResultDecoded``
	init(decodingError: Error, rawData: Data, stderr: String?, exitCode: Int32?) {
		if let resticErrMessage = try? AppDelegate.jsonDecoder.decode(ResticResponse.error.self, from: rawData) {
			self.init(from: resticErrMessage)
		} else {
			let out = String(data: rawData, encoding: .utf8)
			if stderr != nil || out != nil {
				let ec: Int? = {
					guard let exitCode else { return nil }
					return Int(exitCode)
				}()
				self = .resticErrorMessage(message: out, code: ec, stderr: stderr)
			} else {
				self = .couldNotDecodeOutput(decodingError)
			}
		}
	}
	
	/// Creates an error message from an "OS" error, typically caught when doing file-system operations.
	///
	/// The resulting description will be `"\(message):\n\n\(error.localizedDescription"`
	/// - Parameters:
	///   - err: The generic Error thrown by a Foundation function.
	///   - message: What the app was trying to do.
	init(from err: Error, message: String) {
		self = .osError(message: message, description: err.localizedDescription)
	}
	
	/// Creates an error from Restic's exit status.
	/// - Parameter exitCode: Restic's exit status.
	init?(exitCode: Int32) {
		switch exitCode {
			case 0: return nil
			case 1: self = .exitCode(code: 1, description: "Command failed")
			case 2: self = .exitCode(code: 2, description: "Go runtime error")
			case 3: self = .exitCode(code: 3, description: "Could not read source data")
			case 10: self = .exitCode(code: 10, description: "Repository does not exist")
			case 11: self = .exitCode(code: 11, description: "Repository could not be locked")
			case 12: self = .exitCode(code: 12, description: "Wrong repository password")
			case 130: self = .exitCode(code: 130, description: "Restic was interrupted using SIGINT or SIGSTOP")
			default: self = .exitCode(code: exitCode, description: "Unknown exit code reason")
		}
		RGLogger.default.log("Restic returned exit code \(self)")
	}
	
	public var description: String {
		switch self {
			case .couldNotDecodeOutput:
				return "Could not decode output from Restic. Make sure you are using a supported version in ResticGUI's Preferences."
			case .noResticInstallationsFound(let msg):
				return "No Restic installations found (\(msg))"
			case .resticErrorMessage(message: let message, code: let code, let stderr):
				var msg = "\"\(message ?? "(no error message)")\""
				if let code {
					msg = "Restic returned error code \(code), \(msg)"
				}
				if let stderr, message == nil {
					msg += ", stderr: \"\(stderr)\""
				}
				return msg
			case .unsupportedRepositoryVersion(version: let version):
				return "ResticGUI only supports repository version 2, this repository is verion \(version)."
			case .exitCode(code: let code, description: let description):
				return description + " (exit code: \(code))."
			case .unknownError(message: let message):
				return message ?? "There was an unkown error"
			case .osError(message: let message, description: let description):
				return "\(message):\n\n\(description)"
		}
	}
	
	public var errorDescription: String? {
		return self.description
	}
	
}
