import Foundation

/// Configuration for project build settings
struct ProjectConfiguration {
    
    /// Development team identifier
    static let teamIdentifier = "YOUR_TEAM_ID"
    
    /// Organization name for the project
    static let organizationName = "Your Organization"
    
    /// Bundle identifier prefix (reverse domain)
    static let bundleIdPrefix = "com.xcuitestgenerator"
    
    /// Project version
    static let projectVersion = "1.0.0"
    
    /// Build version
    static let buildVersion = "1"
    
    /// Minimum macOS version supported
    static let minMacOSVersion = "12.0"
    
    /// Swift version
    static let swiftVersion = "5.0"
    
    /// Target Framework
    static let framework = "AppKit"
    
    /// Entitlements for the main app
    struct Entitlements {
        static let appSandbox = true
        static let appGroups = ["group.com.xcuitestgenerator"]
        static let keychainAccess = true
        static let networkConnections = true
    }
    
    /// Build configurations
    struct BuildConfigurations {
        static let debug = "Debug"
        static let release = "Release"
    }
    
    /// Target names
    struct Targets {
        static let app = "XCUITestGenerator"
        static let extensionName = "XCUITestGeneratorExtension"
        static let tests = "XCUITestGeneratorTests"
    }
    
    /// File structure
    struct FileStructure {
        static let sourceDir = "Sources"
        static let resourcesDir = "Resources"
        static let testsDir = "Tests"
    }
}

/// Helper for generating common file paths
class ProjectPathHelper {
    
    /// Get the path for source files within the project
    /// - Parameters:
    ///   - target: The target name
    ///   - subdirectory: Optional subdirectory within the source directory
    /// - Returns: The full path
    static func sourcePath(for target: String, subdirectory: String? = nil) -> String {
        var path = "\(ProjectConfiguration.FileStructure.sourceDir)/\(target)"
        if let subdirectory = subdirectory {
            path += "/\(subdirectory)"
        }
        return path
    }
    
    /// Get the path for resource files within the project
    /// - Parameters:
    ///   - target: The target name
    ///   - subdirectory: Optional subdirectory within the resources directory
    /// - Returns: The full path
    static func resourcePath(for target: String, subdirectory: String? = nil) -> String {
        var path = "\(ProjectConfiguration.FileStructure.resourcesDir)/\(target)"
        if let subdirectory = subdirectory {
            path += "/\(subdirectory)"
        }
        return path
    }
    
    /// Get the path for test files within the project
    /// - Parameters:
    ///   - target: The target name
    ///   - subdirectory: Optional subdirectory within the tests directory
    /// - Returns: The full path
    static func testPath(for target: String, subdirectory: String? = nil) -> String {
        var path = "\(ProjectConfiguration.FileStructure.testsDir)/\(target)"
        if let subdirectory = subdirectory {
            path += "/\(subdirectory)"
        }
        return path
    }
}
