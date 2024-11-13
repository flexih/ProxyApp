//
//  KeychainManager.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//


//
//  KeychainManager.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.increments.ProxyApp"
    
    private init() {}
    
    func storePassword(_ password: String, for account: String) throws -> Data {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // First, try to delete any existing password
        SecItemDelete(query as CFDictionary)
        
        // Then add the new password
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
        
        return passwordData
    }
    
    func getPassword(for account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data else {
            throw KeychainError.unableToRetrieve
        }
        
        return passwordData
    }
    
    func deletePassword(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToStore
    case unableToRetrieve
    case unableToDelete
}