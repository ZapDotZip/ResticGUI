//
//  KeychainInterface.swift
//  ResticGUI
//

import Foundation

class KeychainInterface {
	
	enum KeychainError: Error {
		case unableToDecodeResult(msg: String = "The data from the keychain could not be decoded to a string.")
		case unhandledOSStatusError(msg: String)
		case itemNotFound(msg: String)
		case ioError(msg: String)
		case parameterError(msg: String)
		case duplicateItem(msg: String)
		case userCanceled(msg: String)
		init(_ status: OSStatus) {
			let msg = (SecCopyErrorMessageString(status, nil) as? String) ?? "An unknown error occured (OSStatus \(status))"
			switch status {
			case errSecItemNotFound: self = .itemNotFound(msg: msg)
			case errSecIO: self = .ioError(msg: msg)
			case errSecParam: self = .parameterError(msg: msg)
			case errSecDuplicateItem: self = .duplicateItem(msg: msg)
			case errSecUserCanceled: self = .userCanceled(msg: msg)
			default:
				NSLog("Unhandled OSStatus: \(status)")
				self = .unhandledOSStatusError(msg: msg)
			}
		}
		
		var errorDescription: String? {
			switch self {
			case .unableToDecodeResult(msg: let msg):
				return msg
			case .unhandledOSStatusError(msg: let msg):
				return msg
			case .itemNotFound(msg: let msg):
				return msg
			case .ioError(msg: let msg):
				return msg
			case .parameterError(msg: let msg):
				return msg
			case .duplicateItem(msg: let msg):
				return msg
			case .userCanceled(msg: let msg):
				return msg
			}
		}
	}
	
	static let service = Bundle.main.bundleIdentifier ?? "unknown bundle identifier"
	
	static func add(path: String, password: String) throws(KeychainError) {
		let dict = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: path,
			kSecValueData: password
		] as CFDictionary
		let status = SecItemAdd(dict, nil)
		if status != errSecSuccess {
			throw KeychainError(status)
		}
	}
	
	static func load(path: String) throws(KeychainError) -> String {
		let dict = [
			kSecMatchLimit: kSecMatchLimitOne,
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: path,
			kSecReturnData: true,
		] as CFDictionary
		var result: AnyObject?
		
		let status = SecItemCopyMatching(dict, &result)
		if status != errSecSuccess {
			NSLog("Unable to get keychain item: \(status)")
			throw KeychainError(status)
		}
		if let data = result as? Data, let str = String.init(data: data, encoding: .utf8) {
			return str
		} else {
			throw KeychainError.unableToDecodeResult()
		}
	}
	
	static func update(path: String, password: String) throws(KeychainError) {
		let dict = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: path,
		] as CFDictionary
		let update = [
			kSecValueData: password.data(using: .utf8)!,
		] as CFDictionary
		
		let status = SecItemUpdate(dict, update)
		if status != errSecSuccess {
			throw KeychainError(status)
		}
	}
	
	static func update(path: String) throws(KeychainError) {
		let dict = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: path,
		] as CFDictionary
		let update = [
			kSecAttrAccount: path
		] as CFDictionary
		
		let status = SecItemUpdate(dict, update)
		if status != errSecSuccess {
			throw KeychainError(status)
		}
	}
	
	static func updateOrAdd(path: String, password: String) throws(KeychainError) {
		do {
			try update(path: path, password: password)
		} catch {
			switch error {
			case .itemNotFound:
				do {
					try add(path: path, password: password)
				} catch {
					throw error
				}
			default:
				throw error
			}
		}
	}
	
	static func delete(path: String) throws(KeychainError) {
		let dict = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: service,
			kSecAttrAccount: path,
		] as CFDictionary
		
		let status = SecItemDelete(dict)
		if status != errSecSuccess {
			throw KeychainError(status)
		}
	}
	
}
