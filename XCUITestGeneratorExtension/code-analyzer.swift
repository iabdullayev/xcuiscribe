swift
import Foundation

/// Error types for code analysis failures
enum CodeAnalyzerError: Error {
    case invalidRegex(String)
    case invalidStructure(String)
    case copilotError(String)
}

/// A class responsible for analyzing Swift code and extracting information about testable units.
public class CodeAnalyzer {
    
    /// Analyze Swift code and extract information about testable units.
    /// - Parameters:
    ///   - code: The Swift code to analyze.
    ///   - copilotService: An optional Copilot service for enhanced analysis.
    /// - Returns: A result containing an array of TestableUnit or an error.
    public func analyze(_ code: String, copilotService: CopilotService? = nil) -> Result<[TestableUnit], CodeAnalyzerError> {
        guard !code.isEmpty else {
            return .failure(.invalidStructure("Code is empty"))
        }
        
        var testableUnits: [TestableUnit] = []
        
        // Extract testable units (functions, properties)
        testableUnits.append(contentsOf: extractTestableFunctions(from: code, copilotService: copilotService))
        testableUnits.append(contentsOf: extractTestableProperties(from: code, copilotService: copilotService))
        
        return .success(testableUnits.uniqued())
    }
    
    // MARK: - Helper Methods
    
    /// Extract testable functions from the code.
    /// - Parameters:
    ///   - code: The code to analyze.
    ///   - copilotService: An optional Copilot service for enhanced analysis.
    /// - Returns: An array of TestableUnit representing functions.
    private func extractTestableFunctions(from code: String, copilotService: CopilotService? = nil) -> [TestableUnit] {
        var functions: [TestableUnit] = []
        
        // Regular expression to match functions with various access modifiers and static/non-static keywords
        let pattern = "(public|private|internal|fileprivate)?\\s*(static)?\\s*func\\s+([a-zA-Z0-9_]+)\\s*\\(.*\\)\\s*(->\\s*[a-zA-Z0-9_?<>?\\[\\]! ]+)?(\\s+throws?)?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: code, range: NSRange(code.startIndex..., in: code))
            
            for match in matches {
                if match.numberOfRanges >= 4,
                   let functionNameRange = Range(match.range(at: 3), in: code) {
                    let functionName = String(code[functionNameRange])
                    let isStatic = match.range(at: 2).location != NSNotFound
                    let newFunction = TestableUnit(name: functionName, type: .function, isStatic: isStatic)
                    functions.append(newFunction)
                }
            }
        } catch {
            print("Error creating regex: \(error)")
            
            if let copilotService = copilotService {
                var copilotFunctions: [TestableUnit] = []
                let semaphore = DispatchSemaphore(value: 0)
                copilotService.generateCode(prompt: "Extract all the functions in this code: \(code)") { result in
                    switch result {
                    case .success(let functionsString):
                        if let data = functionsString.data(using: .utf8) {
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                    for json in jsonArray {
                                        if let name = json["name"] as? String,
                                           let isStatic = json["isStatic"] as? Bool {
                                            
                                            let newFunction = TestableUnit(name: name, type: .function, isStatic: isStatic)
                                            copilotFunctions.append(newFunction)
                                        }
                                    }
                                }
                            } catch {
                                print("Error parsing Copilot's function JSON: \(error)")
                            }
                        }
                    case .failure(let error):
                        print("Copilot failed to extract functions: \(error.localizedDescription)")
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()
                return copilotFunctions
            }
            
            return []
        }
        
        return functions
    }
    
    /// Extract testable properties from the code.
    /// - Parameters:
    ///   - code: The code to analyze.
    ///   - copilotService: An optional Copilot service for enhanced analysis.
    /// - Returns: An array of TestableUnit representing properties.
    private func extractTestableProperties(from code: String, copilotService: CopilotService? = nil) -> [TestableUnit] {
        var properties: [TestableUnit] = []
        
        // Regular expression to match properties with various access modifiers and static/non-static keywords
        let pattern = "(public|private|internal|fileprivate|)\\s*(static\\s+)?(var|let)\\s+([a-zA-Z0-9_]+)\\s*:\\s*([a-zA-Z0-9_?]+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: code, range: NSRange(code.startIndex..., in: code))
            
            for match in matches {
                if match.numberOfRanges >= 5,
                   let propertyNameRange = Range(match.range(at: 4), in: code) {
                    let propertyName = String(code[propertyNameRange])
                    let isStatic = match.range(at: 2).location != NSNotFound
                    
                    let newProperty = TestableUnit(name: propertyName, type: .property, isStatic: isStatic)
                    properties.append(newProperty)
                }
            }
        } catch {
            print("Error creating regex: \(error)")
            
            if let copilotService = copilotService {
                var copilotProperties: [TestableUnit] = []
                let semaphore = DispatchSemaphore(value: 0)
                copilotService.generateCode(prompt: "Extract all the properties in this code: \(code)") { result in
                    switch result {
                    case .success(let propertiesString):
                        if let data = propertiesString.data(using: .utf8) {
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                    for json in jsonArray {
                                        if let name = json["name"] as? String,
                                           let isStatic = json["isStatic"] as? Bool {
                                            
                                            let newProperty = TestableUnit(name: name, type: .property, isStatic: isStatic)
                                            copilotProperties.append(newProperty)
                                        }
                                    }
                                }
                            } catch {
                                print("Error parsing Copilot's properties JSON: \(error)")
                            }
                        }
                    case .failure(let error):
                        print("Copilot failed to extract properties: \(error.localizedDescription)")
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()
                return copilotProperties
            }
            
            return []
        }
        
        return properties
    }
    
}

extension Array where Element == TestableUnit {
    func uniqued() -> [Element] {
        var seen = Set<String>()
        return filter { seen.insert($0.name).inserted }
    }
}