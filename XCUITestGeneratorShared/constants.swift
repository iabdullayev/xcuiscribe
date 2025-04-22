import Foundation

/// Shared constants used across the app and extension
public struct Constants {
    // App information
    public static let appName = "XCUITest Generator"
    public static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    public static let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // Shared app group and keychain access
    public static let appGroupIdentifier = "group.com.xcuitestgenerator"
    public static let keychainServiceName = "com.xcuitestgenerator.apikeys"
    public static let apiKeyAccount = "anthropic-api-key"

    // Copilot API
    public static let copilotApiEndpoint = "https://api.github.com/copilot_internal/v2/completions"
    public static let copilotApiModel = "copilot-codex"
    public static let copilotApiMaxTokens = 2000
    
    // User defaults keys
    public static let userDefaultsShowedWelcomeScreen = "showedWelcomeScreen"
    
    // Extension identifiers
    public static let extensionBundleIdentifier = "com.xcuitestgenerator.XCUITestGeneratorExtension"
    public static let extensionCommandIdentifier = "com.xcuitestgenerator.XCUITestGeneratorExtension.GenerateXCUITests"
    
    // Error messages
    public struct ErrorMessages {
        public static let apiKeyMissing = "GitHub Copilot API key not configured. Please run the container app to set up your API key."
        public static let notSwiftUIFile = "This doesn't appear to be a SwiftUI file. The extension works only with SwiftUI views."
        public static let analysisFailed = "Failed to analyze SwiftUI code. Try using a simpler view or check for syntax errors."
        public static let networkError = "Network error. Please check your internet connection and try again."
    }
    
    // Success messages
    public struct SuccessMessages {
        public static let apiKeySaved = "API Key saved successfully!"
        public static let testGenerated = "XCUITest code generated successfully!"
        public static let apiTestSuccessful = "API connection test successful!"
    }
    
    // Documentation URLs
    public struct URLs {
        public static let documentation = "https://github.com/yourusername/XCUITestGenerator"
        public static let anthropicApiDocs = "https://docs.github.com/en/copilot"
        public static let xcuiTestDocs = "https://developer.apple.com/documentation/xctest/user_interface_tests"
    }
}
