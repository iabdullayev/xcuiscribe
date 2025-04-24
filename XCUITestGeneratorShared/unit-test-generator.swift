import Foundation

/// A class responsible for generating unit tests for Swift code.
public class UnitTestGenerator {
    
    /// Initializes a new `UnitTestGenerator`.
    public init() {}
    
    /// Generates unit tests for the specified testable units.
    ///
    /// - Parameter testableUnits: The testable units to generate tests for.
    /// - Returns: The generated unit test code as a string.
    public func generateTests(for testableUnits: [TestableUnit]) -> String {
        var testCode = "import XCTest\n\nclass GeneratedTests: XCTestCase {\n"
        
        for unit in testableUnits {
            let testFunctionName = "test" + unit.name.capitalizedFirstLetter()
            testCode += """
    func \(testFunctionName)() {
        // TODO: Add more tests
        XCTAssert(true)
    }
"""
        }
        
        testCode += "}"
        return testCode
    }
}

extension String {
    /// Returns a new string with the first letter capitalized.
    ///
    /// - Returns: A string with the first letter capitalized.
    func capitalizedFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}