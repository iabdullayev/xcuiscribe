import XCTest
@testable import XCUITestGenerator

class KeychainManagerTests: XCTestCase {
    
    // The keychain manager instance to test
    var keychainManager: KeychainManager!
    
    // Test account and string values
    let testAccount = "test_account"
    let testString = "test_string_value"
    let updatedTestString = "updated_test_string_value"
    
    override func setUp() {
        super.setUp()
        // Use a unique service name for tests to avoid conflicts
        keychainManager = KeychainManager(serviceName: "com.xcuitestgenerator.tests")
        
        // Clean up any existing test items
        try? keychainManager.delete(forAccount: testAccount)
    }
    
    override func tearDown() {
        // Clean up test items
        try? keychainManager.delete(forAccount: testAccount)
        keychainManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testSaveAndRetrieveString() throws {
        // Verify the item doesn't exist initially
        XCTAssertFalse(keychainManager.hasValue(forAccount: testAccount))
        
        // Save a string
        try keychainManager.save(string: testString, forAccount: testAccount)
        
        // Verify the item exists
        XCTAssertTrue(keychainManager.hasValue(forAccount: testAccount))
        
        // Retrieve the string
        let retrievedString = try keychainManager.getString(forAccount: testAccount)
        
        // Verify the retrieved string matches the original
        XCTAssertEqual(retrievedString, testString)
    }
    
    func testUpdateExistingString() throws {
        // Save a string
        try keychainManager.save(string: testString, forAccount: testAccount)
        
        // Update the string
        try keychainManager.save(string: updatedTestString, forAccount: testAccount)
        
        // Retrieve the updated string
        let retrievedString = try keychainManager.getString(forAccount: testAccount)
        
        // Verify the retrieved string matches the updated string
        XCTAssertEqual(retrievedString, updatedTestString)
    }
    
    func testDeleteString() throws {
        // Save a string
        try keychainManager.save(string: testString, forAccount: testAccount)
        
        // Verify the item exists
        XCTAssertTrue(keychainManager.hasValue(forAccount: testAccount))
        
        // Delete the string
        try keychainManager.delete(forAccount: testAccount)
        
        // Verify the item no longer exists
        XCTAssertFalse(keychainManager.hasValue(forAccount: testAccount))
        
        // Verify trying to retrieve the deleted string throws an error
        XCTAssertThrowsError(try keychainManager.getString(forAccount: testAccount)) { error in
            XCTAssertEqual(error as? KeychainManager.KeychainError, KeychainManager.KeychainError.itemNotFound)
        }
    }
    
    func testRetrieveNonExistentItem() {
        // Try to retrieve a non-existent item
        XCTAssertThrowsError(try keychainManager.getString(forAccount: "non_existent_account")) { error in
            XCTAssertEqual(error as? KeychainManager.KeychainError, KeychainManager.KeychainError.itemNotFound)
        }
    }
    
    func testSaveEmptyString() throws {
        // Save an empty string
        try keychainManager.save(string: "", forAccount: testAccount)
        
        // Verify the item exists
        XCTAssertTrue(keychainManager.hasValue(forAccount: testAccount))
        
        // Retrieve the string
        let retrievedString = try keychainManager.getString(forAccount: testAccount)
        
        // Verify the retrieved string is empty
        XCTAssertEqual(retrievedString, "")
    }
    
    func testDeleteNonExistentItem() throws {
        // Delete a non-existent item (should not throw)
        XCTAssertNoThrow(try keychainManager.delete(forAccount: "non_existent_account"))
    }
    
    func testKeychainErrorDescriptions() {
        // Test error descriptions
        XCTAssertEqual(KeychainManager.KeychainError.itemNotFound.localizedDescription,
                       "The specified item could not be found in the keychain.")
        
        XCTAssertEqual(KeychainManager.KeychainError.duplicateItem.localizedDescription,
                       "The item already exists in the keychain.")
        
        XCTAssertEqual(KeychainManager.KeychainError.invalidItemFormat.localizedDescription,
                       "The item format is invalid.")
        
        let statusError = KeychainManager.KeychainError.unexpectedStatus(-1)
        XCTAssertTrue(statusError.localizedDescription.contains("An unexpected error occurred"))
    }
}
