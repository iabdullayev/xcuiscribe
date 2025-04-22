import Foundation
import Security

/// A utility class for securely storing and retrieving sensitive information in the Keychain
public class KeychainManager {
    
    /// Errors that can occur during Keychain operations
    public enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "The specified item could not be found in the keychain."
            case .duplicateItem:
                return "The item already exists in the keychain."
            case .invalidItemFormat:
                return "The item format is invalid."
            case .unexpectedStatus(let status):
                return "An unexpected error occurred. Status code: \(status)."
            }
        }
    }
    
    /// The service name used for keychain queries
    private let serviceName: String
    
    /// The access group for sharing keychain items (optional)
    private let accessGroup: String?
    
    /// Initialize with service name and optional access group
    /// - Parameters:
    ///   - serviceName: The service name for keychain entries
    ///   - accessGroup: Optional access group for shared keychain access
    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    /// Save a string value to the Keychain
    /// - Parameters:
    ///   - string: The string to save
    ///   - account: The account identifier (key)
    /// - Throws: KeychainError if saving fails
    public func save(string: String, forAccount account: String) throws {
        // Convert string to data
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        // Create query dictionary
        var query = baseQuery(forAccount: account)
        
        // Check if the item already exists
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            // Item exists, update it
            let attributes: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
        case errSecItemNotFound:
            // Item doesn't exist, add it
            query[kSecValueData as String] = data
            status = SecItemAdd(query as CFDictionary, nil)
            
        default:
            throw KeychainError.unexpectedStatus(status)
        }
        
        // Check for errors
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve a string value from the Keychain
    /// - Parameter account: The account identifier (key)
    /// - Returns: The stored string
    /// - Throws: KeychainError if retrieval fails
    public func getString(forAccount account: String) throws -> String {
        // Create query dictionary
        var query = baseQuery(forAccount: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        // Execute the query
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Check for errors
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        // Convert result to string
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return string
    }
    
    /// Delete an item from the Keychain
    /// - Parameter account: The account identifier (key)
    /// - Throws: KeychainError if deletion fails
    func delete(forAccount account: String) throws {
        // Create query dictionary
        let query = baseQuery(forAccount: account)
        
        // Execute the delete
        let status = SecItemDelete(query as CFDictionary)
        
        // Check for errors (ignore if item not found)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Check if an item exists in the Keychain
    /// - Parameter account: The account identifier (key)
    /// - Returns: True if the item exists
    func hasValue(forAccount account: String) -> Bool {
        // Create query dictionary
        let query = baseQuery(forAccount: account)
        
        // Execute the query
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        // Return true if the item exists
        return status == errSecSuccess
    }
    
    /// Create a base query dictionary for Keychain operations
    /// - Parameter account: The account identifier (key)
    /// - Returns: A query dictionary
    private func baseQuery(forAccount account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}
