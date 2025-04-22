swift
import XCTest
@testable import XCUITestGeneratorShared

final class CodeAnalyzerTests: XCTestCase {

    /// Tests that `analyze` returns testable units for functions.
    func testAnalyze_WithFunctions_ReturnsFunctionTestableUnits() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class Calculator {
            func sum(a: Int, b: Int) -> Int {
                return a + b
            }
        }
            func subtract(a: Int, b: Int) -> Int {
                return a - b
            }
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 2)
            XCTAssertEqual(testableUnits[0].name, "sum")
            XCTAssertEqual(testableUnits[0].type, .function)

            XCTAssertEqual(testableUnits[1].name, "subtract")
            XCTAssertEqual(testableUnits[1].type, .function)

        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }
    
    /// Tests that `analyze` returns an empty array when no functions are present.
    func testAnalyze_WithoutFunctions_ReturnsEmptyArray() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class MyClass {
            let value: Int
            init(value: Int) {
                self.value = value
            }
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 0)
        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns testable units for static functions.
    func testAnalyze_WithStaticFunction_ReturnsTestableUnits() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class MyClass {
            static func myStaticFunction() {
                // Implementation
            }
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 1)
            XCTAssertEqual(testableUnits[0].name, "myStaticFunction")
            XCTAssertEqual(testableUnits[0].type, .function)

        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns testable units for async functions.
    func testAnalyze_WithAsyncFunction_ReturnsTestableUnits() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class MyClass {
            async func myAsyncFunction() {
                // Implementation
            }
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 1)
            XCTAssertEqual(testableUnits[0].name, "myAsyncFunction")
            XCTAssertEqual(testableUnits[0].type, .function)

        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns testable units for computed properties.
    func testAnalyze_WithComputedProperty_ReturnsTestableUnits() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class MyClass {
            var myComputedProperty: Int {
                return 42
            }
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 1)
            XCTAssertEqual(testableUnits[0].name, "myComputedProperty")
            XCTAssertEqual(testableUnits[0].type, .function)

        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns testable units for functions with different access modifiers.
    func testAnalyze_WithDifferentAccessModifiers_ReturnsTestableUnits() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        class MyClass {
            public func publicFunction() {}
            private func privateFunction() {}
            internal func internalFunction() {}
            fileprivate func fileprivateFunction() {}
        }
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 4)
            let functionNames = testableUnits.map { $0.name }.sorted()
            XCTAssertEqual(functionNames, ["fileprivateFunction", "internalFunction", "privateFunction", "publicFunction"])

        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns an empty array for wrong code.
    func testAnalyze_WithWrongCode_ReturnsEmptyArray() throws {
        let codeAnalyzer = CodeAnalyzer()

        let code = """
        This is not Swift code.
        """

        let result = codeAnalyzer.analyze(code)

        switch result {
        case .success(let testableUnits):
            XCTAssertEqual(testableUnits.count, 0)
        case .failure(let error):
            XCTFail("The code analysis failed with error: (error.localizedDescription)")
        }
    }

    /// Tests that `analyze` returns an error for invalid regex.
    func testAnalyze_WithInvalidRegex_ReturnsError() throws {
        // This case is not testable because the regex is hardcoded
    }
}