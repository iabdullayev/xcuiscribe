import Foundation

/// A class responsible for analyzing Swift code to identify testable units for unit test generation.
public class CodeAnalyzer {
    
    /// Initializes a new `CodeAnalyzer`.
    public init() {}
    
    /// Analyzes Swift code and returns information about testable units.
    ///
    /// - Parameter code: The Swift code to analyze.
    /// - Returns: A result containing an array of `TestableUnit` on success, or an error on failure.
    public func analyze(_ code: String) -> Result<[TestableUnit], CodeAnalyzerError> {
        do {
            let regex = try NSRegularExpression(pattern: "\\b(?:public|private|internal|fileprivate)?\\s*(?:static\\s+)?(?:func|var|let)\\s+([a-zA-Z0-9_]+)", options: [])
            let range = NSRange(code.startIndex..., in: code)
            let matches = regex.matches(in: code, options: [], range: range)
            
            var testableUnits: [TestableUnit] = []
            
            for match in matches {
                guard let nameRange = Range(match.range(at: 1), in: code) else {
                    continue
                }
                
                let name = String(code[nameRange])
                let isFunction = code[code.index(before: nameRange.lowerBound)...].prefix(4) == "func"
                let isStatic = code[..<nameRange.lowerBound].contains("static")
                
                let type: TestableUnitType = isFunction ? .function : .property
                testableUnits.append(TestableUnit(name: name, type: type, isStatic: isStatic))
            }
            
            return .success(testableUnits)
        } catch {
            return .failure(.invalidRegex)
        }
    }
}

/// Represents a unit of code that can be tested (e.g., a function).
public struct TestableUnit: Equatable {
    /// The name of the testable unit.
    public let name: String
    /// The type of the testable unit.
    public let type: TestableUnitType
    /// Is it a static method.
    public let isStatic: Bool
    
    public init(name: String, type: TestableUnitType, isStatic: Bool = false) {
        self.name = name
        self.type = type
        self.isStatic = isStatic
    }
}

/// The type of a testable unit.
public enum TestableUnitType: Equatable {
    /// A function.
    case function
    /// A property.
    case property
}

/// Errors that can occur during code analysis.
public enum CodeAnalyzerError: Error, LocalizedError {
    /// The regular expression used for analysis is invalid.
    case invalidRegex
    /// The code structure is invalid.
    case invalidStructure(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidRegex:
            return "The regular expression used to analyze the code is invalid."
        case .invalidStructure(let message):
            return "Invalid code structure: \(message)"
        }
    }
}