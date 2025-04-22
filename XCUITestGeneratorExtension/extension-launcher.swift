import Foundation
import XcodeKit
import XCUITestGeneratorShared

/// The main entry point for the Xcode Source Editor Extension
class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    /// Called when the extension is loaded
    func extensionDidFinishLaunching() {
        // Setup code when the extension is loaded
        commandManager = CommandManager()
        loadConfiguration()
    }
    
    /// Called when the extension is about to be unloaded
    func extensionWillFinishLaunching() {
        // Cleanup code when the extension is about to be unloaded
        cleanupResources()
    }
    
    // MARK: - Private Helper Methods
    
    /// Setup logging for the extension
    private func setupLogging() {
        let logFile = FileManager.default.temporaryDirectory.appendingPathComponent("XCUITestGenerator.log")
        freopen(logFile.path, "a+", stderr)
    }
    
    /// Load configuration from shared container
    private func loadConfiguration() {
        // This is where we would load any configuration from the shared app group
        // or prepare resources needed by the extension
    }
    
    /// Clean up any resources before unloading
    private func cleanupResources() {
        // Clean up any resources or temporary files created by the extension
    }
    
    
    
    
    
    
    
    
    
    
    func sourceEditor(_ sourceEditor: XCSourceEditorExtension, perform commandInvocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        commandManager?.perform(with: commandInvocation, completionHandler: completionHandler)
    }
    
    // MARK: - Properties
    
    private var commandManager: CommandManager?
}

/// The command handler that responds to the "Generate XCUITests" command
class CommandManager: NSObject {
    
    /// Possible errors during command execution
    enum CommandError: Error, LocalizedError {
        case bufferAccessFailure
        case notSwiftUIFile
        case analysisFailure(String)
        case apiKeyMissing
        case copilotApiFailure(String)
        case copilotRateLimitExceeded
        case networkFailure(String)
        
        var errorDescription: String? {
            switch self {
            case .bufferAccessFailure:
                return "Failed to access the Xcode editor buffer"
            case .notSwiftUIFile:
                return "This doesn't appear to be a SwiftUI file. The extension works only with SwiftUI views."
            case .analysisFailure(let reason):
                return "Failed to analyze SwiftUI code: \(reason)"
            case .apiKeyMissing:
                return "GitHub Copilot API key not configured. Please run the container app to set up your API key."
            case .copilotApiFailure(let reason):
                return "Copilot API error: \(reason)"
            case .copilotRateLimitExceeded:
                return "Copilot API rate limit exceeded. Please try again later."
            case .networkFailure(let reason):
                return "Network error: \(reason)"
            }
        }
    }
    
    // MARK: - Properties
    
    private let analyzer = SwiftUIAnalyzer()
    private let generator = XCUITestGenerator()
    private let codeAnalyzer = CodeAnalyzer()
    private let unitTestGenerator = UnitTestGenerator()
    
    enum Command: String {
        case generateXCUITests = "Generate XCUITests for View"
        case generateUnitTests = "Generate Unit Tests"
    }
    
    /// Perform the command with the given invocation
    /// - Parameters:
    ///   - invocation: The command invocation
    ///   - completionHandler: The completion handler to call when done
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        
        guard let command = Command(rawValue: invocation.commandIdentifier) else {
            
            completionHandler(nil)
            return
        }
        
        switch command {
        case .generateUnitTests:
            generateUnitTests(with: invocation, completionHandler: completionHandler)
        case .generateXCUITests:
            generateXCUITests(with: invocation, completionHandler: completionHandler)
        }
    }
    
    // MARK: - Unit Test Generation
    
    private func generateUnitTests(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let buffer = invocation.buffer
        let code = buffer.completeBuffer
        
        let analysisResult = codeAnalyzer.analyze(code)
        
        switch analysisResult {
        case .success(let testableUnits):
            let testCode = unitTestGenerator.generateTests(for: testableUnits)
            insertTestCode(testCode, into: buffer, testType: .unit)
            completionHandler(nil)
        case .failure(let error):
            NSLog("Code analysis failed: \(error.localizedDescription)")
            completionHandler(CommandError.analysisFailure(error.localizedDescription))
        }
    }
    
    // MARK: - XCUI Test Generation
    
    private func generateXCUITests(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let buffer = invocation.buffer
        let swiftUICode = buffer.completeBuffer
        
        guard isSwiftUIViewFile(swiftUICode) else {
            completionHandler(CommandError.notSwiftUIFile)
            return
        }
        
        
        processSwiftUIFile(swiftUICode: swiftUICode, buffer: buffer, completionHandler: completionHandler)
    }
    
    private func processSwiftUIFile(swiftUICode: String, buffer: XCSourceTextBuffer, completionHandler: @escaping (Error?) -> Void) {
        let analysisResult = swiftUIAnalyzer.analyze(swiftUICode)
        
        switch analysisResult {
        case .success(let viewInfo):
            do {
                // Generate tests using our local generator
                let testCode = try generator.generateTests(for: viewInfo)
                
                
                insertTestCode(testCode, into: buffer, forView: viewInfo.name)
                completionHandler(nil)
            } catch {
                // If local generation fails, fall back to Copilot
                fallBackToCopilotAnalysis(swiftUICode: swiftUICode, buffer: buffer, completionHandler: completionHandler)
            }
            
        case .failure(let error):
            // Log the error
            NSLog("SwiftUI analysis failed: \(error.localizedDescription)")
            
            // Fall back to Copilot
            fallBackToCopilotAnalysis(swiftUICode: swiftUICode, buffer: buffer, completionHandler: completionHandler)
        }
    }
    
    /// Fall back to Copilot when local analysis fails
    /// - Parameters:
    ///   - swiftUICode: The SwiftUI code to analyze
    ///   - buffer: The source buffer
    ///   - completionHandler: The completion handler to call when done
    private func fallBackToCopilotAnalysis(swiftUICode: String, buffer: XCSourceTextBuffer, completionHandler: @escaping (Error?) -> Void) {
        
        // Get the API key from shared UserDefaults
        guard let apiKey = getApiKey(), !apiKey.isEmpty else {
            completionHandler(CommandError.apiKeyMissing)
            return
        }
        
        // Create Copilot service
        let copilotService = CopilotService(apiKey: apiKey)
        
        // Prepare the prompt
        let prompt = buildPrompt(for: swiftUICode)

        // Generate code with Copilot
        copilotService.generateCode(with: prompt) { [weak self] result in
            switch result {
            case .success(let response):
                // Extract code from the response
                let extractedCode = copilotService.extractCodeFromResponse(response.text)
                
                // Insert the code into the buffer on the main thread
                DispatchQueue.main.async {
                    self?.insertTestCode(extractedCode, into: buffer, testType: .xcui, forView: viewInfo.name)
                    completionHandler(nil)
                }
                
            case .failure(let copilotError):
                // Map Copilot errors to our domain-specific errors
                let mappedError: Error
                
                switch copilotError {
                case .invalidAPIKey:
                    mappedError = CommandError.apiKeyMissing
                case .rateLimitExceeded:
                    mappedError = CommandError.copilotRateLimitExceeded
                case .networkError(let details):
                    mappedError = CommandError.networkFailure(details)
                case .invalidRequest, .requestFailed, .invalidResponse, .parsingError, .unknownError:
                    mappedError = CommandError.copilotApiFailure(copilotError.localizedDescription)
                }
                
                completionHandler(mappedError)
            }
        }
    }
    
    /// Get the API key from shared storage
    /// - Returns: The API key, if available
    private func getApiKey() -> String? {
        // Try to get the API key from shared UserDefaults
        if let userDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
            return userDefaults.string(forKey: "copilotApiKey")
        }
        
        // Fall back to keychain if UserDefaults doesn't have it
        do {
            let keychainManager = KeychainManager(serviceName: Constants.keychainServiceName)
            return try keychainManager.getString(forAccount: Constants.apiKeyAccount)
        } catch {
            NSLog("Failed to get API key from keychain: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if this is a SwiftUI file
    private func isSwiftUIViewFile(_ code: String) -> Bool {
        return code.contains("import SwiftUI") &&
        (code.contains("struct") && code.contains(": View")) &&
        code.contains("var body")
    }
    
    enum TestType {
        case unit
        case xcui
    }
    
    private func insertTestCode(_ testCode: String, into buffer: XCSourceTextBuffer, testType: TestType, forView viewName: String? = nil) {
        let commentHeader: String
        let suggestedFileName: String
        
        switch testType {
        case .unit:
            commentHeader = "\n// MARK: - Generated Unit Tests\n"
            suggestedFileName = "GeneratedUnitTests.swift"
        case .xcui:
            commentHeader = "\n// MARK: - Generated XCUITests\n"
            suggestedFileName = viewName != nil ? "\(viewName!)Tests.swift" : "GeneratedTests.swift"
        } 
        
        buffer.lines.add(commentHeader)
        
        if testType == .xcui {
            buffer.lines.add("// Suggestion: Move these tests to a separate file named '\(suggestedFileName)'\n")
        }
        
        insertCode(testCode: testCode, buffer: buffer, commentHeader: commentHeader, suggestionComment: "")
    }
    
    /// Build a prompt for Copilot
    /// - Parameter swiftUICode: The SwiftUI code to analyze
    private func buildPrompt(for swiftUICode: String) -> String {
        return """
        You are an expert iOS developer specializing in XCUITest automation. 
        Given the following SwiftUI code, generate appropriate XCUITest test cases that would verify the functionality and UI elements of this view.
        
        Focus on:
        1. Identifying UI elements and adding accessibility identifiers if missing
        2. Testing user interactions (taps, text entry)
        3. Verifying state changes and UI updates
        4. Navigation testing if applicable
        5. Handling edge cases like empty states or error conditions
        
        Important guidelines:
        - Always use proper XCTest assertions
        - Use the app's launch arguments to set up the environment if needed
        - Focus on testability and maintainability
        - Add clear comments explaining test strategy and assumptions
        - Suggest accessibility identifiers for UI elements that don't have them
        
        SwiftUI Code:
        ```swift
        \(swiftUICode)
        ```
        
        Please respond with only the XCUITest code, wrapped in ```swift and ``` tags.
        The code should be complete and ready to use in an Xcode test target.
        """
    }
    
    private func insertCode(testCode: String, buffer: XCSourceTextBuffer, commentHeader: String, suggestionComment: String) {
        
        buffer.lines.add(commentHeader)
        
        if !suggestionComment.isEmpty {
            buffer.lines.add(suggestionComment)
        }
        
        
        buffer.lines.add(testCode)
    }
}
