//
//  KeychainInterface.swift
//  ResticGUI
//

import Foundation

class KeychainInterface {
	
	enum KeychainError: Error {
		case unhandledOSStatusError(status: OSStatus)
		case unableToDecodeResult
		case itemNotFound
		case ioError
		case applicationError
		case duplicateItem
		case userCanceled
		init(_ status: OSStatus) {
			switch status {
			case errSecItemNotFound: self = .itemNotFound
			case errSecIO: self = .ioError
			case errSecParam: self = .applicationError
			case errSecDuplicateItem: self = .duplicateItem
			case errSecUserCanceled: self = .userCanceled
			default:
				NSLog("Unhandled OSStatus: \(status)")
				self = .unhandledOSStatusError(status: status)
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
			throw KeychainError.unableToDecodeResult
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
