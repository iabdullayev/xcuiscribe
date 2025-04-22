swift
import Foundation
import XCTest

/// A class responsible for generating unit tests for Swift code.
public class UnitTestGenerator {
    
    /// Generates unit tests for a list of testable units.
    /// - Parameters:
    ///   - units: An array of `TestableUnit` instances representing functions and properties to be tested.
    ///   - copilotService: An optional `CopilotService` for generating tests for complex scenarios.
    /// - Returns: A string containing the generated unit test code.
    public func generateTests(for units: [TestableUnit], copilotService: CopilotService? = nil) -> String {
        var testCode = """
        import XCTest

        class GeneratedTests: XCTestCase {

        """
        
        for unit in units {
            
            if let copilotService = copilotService {
                let semaphore = DispatchSemaphore(value: 0)
                var generatedCode: String?
                copilotService.generateCode(prompt: "Generate a test for this function or property: \(unit.name), and this is the type: \(unit.type)") { result in
                    switch result{
                    case .success(let code):
                        copilotCode = code
                    case .failure(let error):
                        print("Copilot failed to generate test for \(unit.name): \(error.localizedDescription)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                if let generatedCode = generatedCode{
                    testCode += """
                            func test\(unit.name.capitalizingFirstLetter())() throws {
                                \(generatedCode)
                            }
                        """
                } else {
                    var call:String
                    var returnTest:String
                    var returnType: String
                    switch unit.type {
                    case .function:
                        call = "\(unit.name)()"
                        returnType = "()"
                    case .property:
                        call = "\(unit.name)"
                        returnType = "Any"
                    }
                    
                    if unit.isStatic {
                        call = "GeneratedTests.\(call)"
                    } else {
                        call = "instance.\(call)"
                    }
                    
                    
                    switch returnType {
                    case "Int":
                        returnTest = "XCTAssertEqual(instance.\(call), 0)"
                    case "String":
                        returnTest = "XCTAssertNotNil(instance.\(call))"
                    case "Bool":
                        returnTest = "XCTAssertFalse(instance.\(call))"
                    case "()":
                        returnTest = "XCTAssertNoThrow(try instance.\(call))"
                    default:
                        returnTest = "XCTAssertNotNil(instance.\(call))"
                    }
                    
                    testCode += """
                                func test\(unit.name.capitalizingFirstLetter())() throws {
                                    // TODO: Add more tests
                                    \(returnTest)
                                }
                            """
                }
            } else {
        }
        
        testCode += "\n}"
        
        return testCode
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}