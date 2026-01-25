//
//  KeychainManager.swift
//  FoodShutter
//
//  Secure manager for iOS Keychain operations
//

import Foundation
import Security

/// Secure manager for Keychain operations
/// Uses kSecClassGenericPassword for API key storage
class KeychainManager {

    // MARK: - Constants

    /// Service identifier for this app's Keychain items
    private static let service = Bundle.main.bundleIdentifier ?? "com.foodshutter.app"

    // MARK: - Error Types

    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "API key not found in Keychain"
            case .duplicateItem:
                return "API key already exists"
            case .invalidData:
                return "Invalid API key data"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }

    // MARK: - Public Methods

    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string to save (API key)
    ///   - account: The account identifier (e.g., "gemini_api_key")
    /// - Throws: KeychainError if save fails
    static func save(_ value: String, forAccount account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Check if item already exists
        if (try? retrieve(account)) != nil {
            // Update existing item
            try update(data, forAccount: account)
        } else {
            // Create new item
            try create(data, forAccount: account)
        }
    }

    /// Retrieve a string value from Keychain
    /// - Parameter account: The account identifier
    /// - Returns: The stored string value
    /// - Throws: KeychainError if retrieval fails
    static func retrieve(_ account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    /// Delete a value from Keychain
    /// - Parameter account: The account identifier
    /// - Throws: KeychainError if deletion fails
    static func delete(_ account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Private Methods

    private static func create(_ data: Data, forAccount account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private static func update(_ data: Data, forAccount account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
