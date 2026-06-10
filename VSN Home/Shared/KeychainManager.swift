import Security
import Foundation

/// Secure Keychain wrapper for storing sensitive data
/// Use this for passwords, API keys, tokens - NOT UserDefaults
struct KeychainManager {
    
    private static let serviceName = "com.vsn.home"
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "Credentials not found"
            case .duplicateItem:
                return "Item already exists"
            case .invalidItemFormat:
                return "Invalid data format"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    /// Save sensitive data to Keychain
    static func save<T: Codable>(_ value: T, key: String) throws {
        let encoded = try JSONEncoder().encode(value)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve sensitive data from Keychain
    static func retrieve<T: Codable>(key: String, type: T.Type) throws -> T {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    }
    
    /// Delete sensitive data from Keychain
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Save password securely
    static func savePassword(_ password: String, for account: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve password securely
    static func getPassword(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return password
    }
}
