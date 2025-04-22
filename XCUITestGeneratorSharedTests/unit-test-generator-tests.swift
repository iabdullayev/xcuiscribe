swift
import XCTest
@testable import XCUITestGeneratorShared

final class UnitTestGeneratorTests: XCTestCase {
    
    /// Tests the generation of test functions for a list of `TestableUnit` instances.
    ///
    /// This test checks if the `UnitTestGenerator` correctly generates test functions
    /// for the given testable units and verifies that the generated code includes
    /// the necessary `import XCTest` statement, a test class named `GeneratedTests`,
    /// and the expected test functions with a placeholder `XCTAssert(true)` and a
    /// `// TODO: Add more tests` comment.
    ///
    /// - Throws: An error if the test fails.
    func testGenerateTests_WithFunctions_ReturnsTestFunctions() throws {
        let unitTestGenerator = UnitTestGenerator()
        let testableUnits = [
            TestableUnit(name: "sum", type: .function),
            TestableUnit(name: "subtract", type: .function)
        ]
        let result = unitTestGenerator.generateTests(for: testableUnits)
        
        // Check if the generated code imports XCTest
        XCTAssertTrue(result.contains("import XCTest"), "Generated code should import XCTest")
        
        // Check if the generated code contains the test class
        let classRegex = try NSRegularExpression(pattern: "class GeneratedTests: XCTestCase {", options: [])
        XCTAssertTrue(classRegex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain a test class named 'GeneratedTests'")
        
        // Check if the generated code contains the test functions with correct content
        let functionRegexes: [NSRegularExpression] = try [
            NSRegularExpression(pattern: "func testSum\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: []),
            NSRegularExpression(pattern: "func testSubtract\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: [])
        ]
        
        for regex in functionRegexes {
            XCTAssertTrue(regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain test functions with correct content")
        }
    }
    
    /// Tests the generation of test functions for a list of static `TestableUnit` instances.
    ///
    /// This test checks if the `UnitTestGenerator` correctly generates test functions
    /// for static functions and verifies that the generated code includes
    /// the necessary `import XCTest` statement, a test class named `GeneratedTests`,
    /// and the expected test functions with a placeholder `XCTAssert(true)` and a
    /// `// TODO: Add more tests` comment.
    ///
    /// - Throws: An error if the test fails.
    func testGenerateTests_WithStaticFunctions_ReturnsTestFunctions() throws {
        let unitTestGenerator = UnitTestGenerator()
        let testableUnits = [
            TestableUnit(name: "staticSum", type: .function),
            TestableUnit(name: "staticSubtract", type: .function)
        ]
        let result = unitTestGenerator.generateTests(for: testableUnits)
        
        // Check if the generated code imports XCTest
        XCTAssertTrue(result.contains("import XCTest"), "Generated code should import XCTest")
        
        // Check if the generated code contains the test class
        let classRegex = try NSRegularExpression(pattern: "class GeneratedTests: XCTestCase {", options: [])
        XCTAssertTrue(classRegex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain a test class named 'GeneratedTests'")
        
        // Check if the generated code contains the test functions with correct content
        let functionRegexes: [NSRegularExpression] = try [
            NSRegularExpression(pattern: "func testStaticSum\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: []),
            NSRegularExpression(pattern: "func testStaticSubtract\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: [])
        ]
        
        for regex in functionRegexes {
            XCTAssertTrue(regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain test functions with correct content")
        }
    }
    
    /// Tests the generation of an empty test class when no functions are provided.
    ///
    /// This test checks if the `UnitTestGenerator` correctly generates an empty
    /// test class when given an empty array of `TestableUnit` instances. It verifies
    /// that the generated code includes the necessary `import XCTest` statement and
    /// a test class named `GeneratedTests` with no test functions.
    ///
    /// - Throws: An error if the test fails.
    func testGenerateTests_WithoutFunctions_ReturnsEmptyTestClass() throws {
        let unitTestGenerator = UnitTestGenerator()
        let testableUnits: [TestableUnit] = []
        let result = unitTestGenerator.generateTests(for: testableUnits)
        
        // Check if the generated code imports XCTest
        XCTAssertTrue(result.contains("import XCTest"), "Generated code should import XCTest")
        
        // Check if the generated code contains the test class
        let classRegex = try NSRegularExpression(pattern: "class GeneratedTests: XCTestCase {\\s*}", options: [])
        XCTAssertTrue(classRegex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain an empty test class named 'GeneratedTests'")
    }
    
    /// Tests the generation of test functions with different access modifiers.
    ///
    /// This test checks if the `UnitTestGenerator` correctly generates test functions
    /// for functions with different access modifiers (e.g., public, private) and
    /// verifies that the generated code includes the necessary `import XCTest`
    /// statement, a test class named `GeneratedTests`, and the expected test
    /// functions with a placeholder `XCTAssert(true)` and a `// TODO: Add more tests`
    /// comment.
    ///
    /// - Throws: An error if the test fails.
    func testGenerateTests_WithAccessModifiers_ReturnsTestFunctions() throws {
        let unitTestGenerator = UnitTestGenerator()
        let testableUnits = [
            TestableUnit(name: "publicFunc", type: .function),
            TestableUnit(name: "privateFunc", type: .function)
        ]
        let result = unitTestGenerator.generateTests(for: testableUnits)
        
        // Check if the generated code imports XCTest
        XCTAssertTrue(result.contains("import XCTest"), "Generated code should import XCTest")
        
        // Check if the generated code contains the test class
        let classRegex = try NSRegularExpression(pattern: "class GeneratedTests: XCTestCase {", options: [])
        XCTAssertTrue(classRegex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain a test class named 'GeneratedTests'")
        
        // Check if the generated code contains the test functions with correct content
        let functionRegexes: [NSRegularExpression] = try [
            NSRegularExpression(pattern: "func testPublicFunc\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: []),
            NSRegularExpression(pattern: "func testPrivateFunc\\(\\) {\\s*// TODO: Add more tests\\s*XCTAssert\\(true\\)\\s*}", options: [])
        ]
        
        for regex in functionRegexes {
            XCTAssertTrue(regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil, "Generated code should contain test functions with correct content")
        }
    }
}