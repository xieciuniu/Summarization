import Foundation
import Security

class APIKeyManager {
    enum KeychainError: Error {
        case unhandledError(status: OSStatus)
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
    }
    
    private let serviceIdentifier = "com.summarizator.apikeys"
    
    func saveAPIKey(_ key: String, for provider: String) throws {
        let account = provider
        
        // Check if the key already exists and delete it if it does
        try? deleteAPIKey(for: provider)
        
        // Prepare the query dictionary
        var query = keychainQuery(provider: provider)
        query[kSecValueData as String] = key.data(using: .utf8)
        
        // Add the key to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getAPIKey(for provider: String) throws -> String {
        var query = keychainQuery(provider: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return key
    }
    
    func deleteAPIKey(for provider: String) throws {
        let query = keychainQuery(provider: provider)
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func keychainQuery(provider: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: provider
        ]
    }
}
