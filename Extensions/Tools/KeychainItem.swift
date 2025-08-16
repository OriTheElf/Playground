/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct for accessing generic password keychain items.
*/

import Foundation

enum KeychainService: String {
    
    enum DeviceInfo: String {
        case deviceIdentifier
    }
    
    
    case deviceInfo
}

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unexpectedItemData
    case unhandledError
}

struct KeychainItem<T: Codable> {
    
    // MARK: Properties
    
    let service: String
    
    private(set) var account: String
    
    let accessGroup: String?
    
    // MARK: Intialization
    init(service: String, account: String, accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }
    
    static func allItemsForService(_ service: String) throws -> [T] {
        var query = [String: AnyObject]()
        query[kSecAttrService as String] = service as AnyObject
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnRef as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == noErr else { throw KeychainError.unhandledError }
        
        guard let results = queryResult as? Array<[String: Any]> else { throw KeychainError.unhandledError }
        let jsonDecoder = JSONDecoder()
        let items = results.compactMap { dict -> T? in
            guard let data = dict[kSecValueData as String] as? Data else { return nil }
            return try? jsonDecoder.decode(T.self, from: data)
        }
        return items
    }
    
    // MARK: Keychain access
    func read() throws -> T {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == noErr else { throw KeychainError.unhandledError }
        
        // Parse the password string from the query result.
        guard
            let existingItem = queryResult as? [String: AnyObject],
            let itemData = existingItem[kSecValueData as String] as? Data
        else {
            throw KeychainError.unexpectedPasswordData
        }
        
        let item = try JSONDecoder().decode(T.self, from: itemData)
        return item
    }
    
    func save(_ item: T) throws {
        // Encode the password into an Data object.
        let encodedItem = try JSONEncoder.encode(item)
        
        do {
            // Check for an existing item in the keychain.
            try _ = read()
            
            // Update the existing item with the new password.
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedItem as AnyObject?
            
            let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError }
        } catch KeychainError.noPassword {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedItem as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError }
        }
    }
    
    func deleteItem() throws {
        // Delete the existing item from the keychain.
        let query = KeychainItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError }
    }
    
    // MARK: Convenience
    
    private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}
