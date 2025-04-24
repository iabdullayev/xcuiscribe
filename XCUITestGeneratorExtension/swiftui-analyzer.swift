import Foundation
import os.log

/// Error types for SwiftUI analysis failures
enum SwiftUIAnalyzerError: Error {
    case invalidStructure(String)
    case missingBodyProperty
    case incompatibleViewType
    case parseFailure(String)
    case viewNameNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidStructure(let details):
            return "Invalid SwiftUI structure: \(details)"
        case .missingBodyProperty:
            return "Missing body property in SwiftUI view"
        case .incompatibleViewType:
            return "Not a compatible SwiftUI view type"
        case .parseFailure(let details):
            return "Failed to parse SwiftUI code: \(details)"
        case .viewNameNotFound:
            return "Could not identify View struct name"
        }
    }
}

/// A class dedicated to analyzing SwiftUI code and extracting relevant information
/// for XCUITest generation
public class SwiftUIAnalyzer {
    
    /// Representation of a UI element found in SwiftUI code
    public struct UIElement {
        public enum ElementType {
            case button
            case textField
            case secureField
            case text
            case toggle
            case picker
            case slider
            case navigationLink
            case list
            case custom(String)
        }
        
        let type: ElementType
        let identifier: String?
        let label: String
        let modifiers: [String]  // Store modifiers like .disabled, .foregroundColor, etc.
        let hasAction: Bool
    }    
    
    /// Analyzed view information
    public struct ViewInfo {
        let name: String
        let stateVariables: [String: String]  // [name: type]
        let elements: [UIElement]
        let bodyContent: String
        let isNavigationView: Bool
        let hasTabBar: Bool
        let hasAlert: Bool
        let hasContextMenu: Bool
        let environmentObjects: [String: String]  // [name: type]
        
        // Convenience initializer with default values for optional parameters
        init(
            name: String,
            stateVariables: [String: String],
            elements: [UIElement],
            bodyContent: String = "",
            isNavigationView: Bool,
            hasTabBar: Bool,
            hasAlert: Bool,
            hasContextMenu: Bool = false,
            environmentObjects: [String: String] = [:]
        ) {
            self.name = name
            self.stateVariables = stateVariables
            self.elements = elements
            self.bodyContent = bodyContent
            self.isNavigationView = isNavigationView
            self.hasTabBar = hasTabBar
            self.hasAlert = hasAlert
            self.hasContextMenu = hasContextMenu
            self.environmentObjects = environmentObjects
        }
    }
    
    /// Analyze SwiftUI code and extract information
    /// - Parameter code: The SwiftUI code as a string
    /// - Returns: Result with analyzed view information or error
    func analyze(_ code: String) -> Result<ViewInfo, SwiftUIAnalyzerError> {
        // Check if this is a SwiftUI file
        guard code.contains("import SwiftUI") else {
            return .failure(.incompatibleViewType)
        }
        
        // Extract view name
        guard let viewName = extractViewName(from: code) else {
            return .failure(.viewNameNotFound)
        }
        
        // Ensure there's a body property
        guard code.contains("var body") || code.contains("var body:") else {
            return .failure(.missingBodyProperty)
        }
        
        // Extract the body content to analyze
        let bodyContent = extractBodyContent(from: code)
        
        // Extract state variables
        let stateVariables = extractStateVariables(from: code)
        
        // Extract UI elements
        var elements = extractUIElements(from: bodyContent)
        
        // If we didn't find elements in the body extraction, fall back to analyzing the whole file
        if elements.isEmpty {
            elements = extractUIElements(from: code)
        }
        
        // Analyze view modifiers in the entire code that might affect testing
        let (isNavigationView, hasTabBar, hasAlert, hasContextMenu) = analyzeViewModifiers(in: code)
        
        // Extract environment objects that might affect state
        let environmentObjects = extractEnvironmentObjects(from: code)
        
        return .success(ViewInfo(
            name: viewName,
            stateVariables: stateVariables,
            elements: elements,
            bodyContent: bodyContent,
            isNavigationView: isNavigationView,
            hasTabBar: hasTabBar,
            hasAlert: hasAlert,
            hasContextMenu: hasContextMenu,
            environmentObjects: environmentObjects
        ))
    }
    
    /// Extract the content of the body property
    /// - Parameter code: The SwiftUI code
    /// - Returns: The content of the body property or the original code if extraction fails
    private func extractBodyContent(from code: String) -> String {        
        // Find the body property
        let pattern = "var\\s+body\\s*:\\s*some\\s+View\\s*\\{(.+?)\\s*\\}\\s*\\}"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: code.utf16.count)
            
            if let match = regex.firstMatch(in: code, options: [], range: range),
               let bodyRange = Range(match.range(at: 1), in: code) {
                return String(code[bodyRange])
            }
        } catch {
            // If regex fails, return the original code to allow fallback analysis
            print("Failed to extract body content: \(error.localizedDescription)")
        }
        
        return code
    }
    
    /// Analyze view modifiers in the code
    /// - Parameter code: The SwiftUI code
    /// - Returns: Tuple containing analysis of common view modifiers
    private func analyzeViewModifiers(in code: String) -> (isNavigationView: Bool, hasTabBar: Bool, hasAlert: Bool, hasContextMenu: Bool) {
        // Check for navigation views (including newer APIs)
        let isNavigationView = code.contains("NavigationView") || 
                               code.contains("NavigationStack") || 
                               code.contains("NavigationSplitView")
        
        // Check for TabBar
        let hasTabBar = code.contains("TabView")
        
        // Check for alert
        let hasAlert = code.contains(".alert(")
        
        // Check for context menu
        let hasContextMenu = code.contains(".contextMenu")
        
        return (isNavigationView, hasTabBar, hasAlert, hasContextMenu)
    }
    
    /// Extract environment objects from the code
    /// - Parameter code: The SwiftUI code
    /// - Returns: Dictionary of environment object names and types
    private func extractEnvironmentObjects(from code: String) -> [String: String] {        
        var environmentObjects = [String: String]()
        
        // Pattern to match environment objects and observed objects
        let patterns = [
            "@EnvironmentObject\\s+var\\s+([A-Za-z0-9_]+)\\s*:\\s*([A-Za-z0-9_<>]+)",
            "@ObservedObject\\s+var\\s+([A-Za-z0-9_]+)\\s*:\\s*([A-Za-z0-9_<>]+)(?!@StateObject)"
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: code.utf16.count)
                
                let matches = regex.matches(in: code, options: [], range: range)
                
                for match in matches {
                    if match.numberOfRanges >= 3,
                       let nameRange = Range(match.range(at: 1), in: code),
                       let typeRange = Range(match.range(at: 2), in: code) {
                        
                        let name = String(code[nameRange])
                        let type = String(code[typeRange])
                        
                        environmentObjects[name] = type
                    }
                }
            } catch {
                print("Failed to extract environment objects: \(error.localizedDescription)")
            }
        }
        
        return environmentObjects
    }
    
    // MARK: - Helper Methods
    
    /// Extract the view name from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractViewName(from code: String) -> String? {
        // Look for a struct that conforms to View
        let pattern = "struct\\s+([A-Za-z0-9_]+)\\s*:\\s*View"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count)) else {
            return nil
        }
        
        if let range = Range(match.range(at: 1), in: code) {
            return String(code[range])
        }
        
        return nil
    }
    
    /// Extract state variables from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractStateVariables(from code: String) -> [String: String] {
        var stateVariables = [String: String]()
        
        // Look for @State, @Binding, @ObservedObject, etc.
        let pattern = "@(State|Binding|ObservedObject|StateObject|Published)\\s+(private\\s+)?var\\s+([A-Za-z0-9_]+)\\s*:\\s*([A-Za-z0-9_<>]+)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return stateVariables
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            guard let nameRange = Range(match.range(at: 3), in: code),
                  let typeRange = Range(match.range(at: 4), in: code) else {
                continue
            }
            
            let name = String(code[nameRange])
            let type = String(code[typeRange])
            
            stateVariables[name] = type
        }
        
        return stateVariables
    }
    
    /// Extract UI elements from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractUIElements(from code: String) -> [UIElement] {
        var elements = [UIElement]()
        
        // Extract buttons
        elements.append(contentsOf: extractButtons(from: code))
        
        // Extract text fields
        elements.append(contentsOf: extractTextFields(from: code))
        
        // Extract texts
        elements.append(contentsOf: extractTexts(from: code))
        
        // Extract toggles
        elements.append(contentsOf: extractToggles(from: code))
        
        // Extract navigation links
        elements.append(contentsOf: extractNavigationLinks(from: code))
        
        return elements
    }
    
    /// Extract buttons from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractButtons(from code: String) -> [UIElement] {
        var buttons = [UIElement]()
        
        // Look for Button("label") { ... } or Button(action: { ... }) { Text("label") }
        let pattern = "Button\\s*\\(?\\s*(?:action:\\s*\\{.*?\\}|\\s*\"(.+?)\"\\s*\\))?\\s*(?:\\{|\\)\\s*\\{\\s*(?:Text\\s*\\(\\s*\"(.+?)\"\\s*\\))?)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return buttons
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            var label = ""
            
            if let labelRange = Range(match.range(at: 1), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
            } else if let labelRange = Range(match.range(at: 2), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
            } else {
                continue
            }
            
            // Try to find identifier in the same block
            let buttonRange = match.range
            let endOfButtonDeclaration = min(buttonRange.location + buttonRange.length + 100, code.count)
            let buttonCodeRange = NSRange(location: buttonRange.location, length: endOfButtonDeclaration - buttonRange.location)
            
            if let buttonCodeRange = Range(buttonCodeRange, in: code) {
                let buttonCode = String(code[buttonCodeRange])
                let identifier = extractAccessibilityIdentifier(from: buttonCode)
                
                buttons.append(UIElement(
                    type: .button,
                    identifier: identifier,
                    label: label,
                    modifiers: extractModifiers(from: buttonCode),
                    hasAction: true
                ))
            }
        }
        
        return buttons
    }
    
    /// Extract text fields from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractTextFields(from code: String) -> [UIElement] {
        var textFields = [UIElement]()
        
        // Look for TextField("label", text: $binding)
        let pattern = "TextField\\(\\s*\"(.+?)\"\\s*,\\s*text:\\s*\\$([A-Za-z0-9_]+)\\s*\\)|SecureField\\(\\s*\"(.+?)\"\\s*,\\s*text:\\s*\\$([A-Za-z0-9_]+)\\s*\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return textFields
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            var label = ""
            var isSecure = false
            
            if let labelRange = Range(match.range(at: 1), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
            } else if let labelRange = Range(match.range(at: 3), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
                isSecure = true
            } else {
                continue
            }
            
            // Try to find identifier in the same block
            let textFieldRange = match.range
            let endOfTextFieldDeclaration = min(textFieldRange.location + textFieldRange.length + 100, code.count)
            let textFieldCodeRange = NSRange(location: textFieldRange.location, length: endOfTextFieldDeclaration - textFieldRange.location)
            if let textFieldCodeRange = Range(textFieldCodeRange, in: code) {
                let textFieldCode = String(code[textFieldCodeRange])
                let identifier = extractAccessibilityIdentifier(from: textFieldCode)
                
                textFields.append(UIElement(
                    type: isSecure ? .secureField : .textField,
                    identifier: identifier,
                    label: label,
                    modifiers: extractModifiers(from: textFieldCode),
                    hasAction: false
                ))
            }
        }
        
        return textFields
    }
    
    /// Extract text elements from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractTexts(from code: String) -> [UIElement] {
        var texts = [UIElement]()
        
        // Look for Text("text")
        let pattern = "Text\\(\\s*\"(.+?)\"\\s*\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return texts
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            guard let labelRange = Range(match.range(at: 1), in: code) else {
                continue
            }
            
            let label = String(code[labelRange])
            
            // Try to find identifier in the same block
            let textRange = match.range
            let endOfTextDeclaration = min(textRange.location + textRange.length + 100, code.count)
            let textCodeRange = NSRange(location: textRange.location, length: endOfTextDeclaration - textRange.location)
            
            if let textCodeRange = Range(textCodeRange, in: code) {
                let textCode = String(code[textCodeRange])
                let identifier = extractAccessibilityIdentifier(from: textCode)
                
                texts.append(UIElement(
                    type: .text,
                    identifier: identifier,
                    label: label,
                    modifiers: extractModifiers(from: textCode),
                    hasAction: false
                ))
            }
        }
        
        return texts
    }
    
    /// Extract toggles from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractToggles(from code: String) -> [UIElement] {
        var toggles = [UIElement]()
        
        // Look for Toggle("label", isOn: $binding)
        let pattern = "Toggle\\(\\s*\"(.+?)\"\\s*,\\s*isOn:\\s*\\$([A-Za-z0-9_]+)\\s*\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return toggles
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            guard let labelRange = Range(match.range(at: 1), in: code) else {
                continue
            }
            
            let label = String(code[labelRange])
            
            // Try to find identifier in the same block
            let toggleRange = match.range
            let endOfToggleDeclaration = min(toggleRange.location + toggleRange.length + 100, code.count)
            let toggleCodeRange = NSRange(location: toggleRange.location, length: endOfToggleDeclaration - toggleRange.location)
            
            if let toggleCodeRange = Range(toggleCodeRange, in: code) {
                let toggleCode = String(code[toggleCodeRange])
                let identifier = extractAccessibilityIdentifier(from: toggleCode)
                
                toggles.append(UIElement(
                    type: .toggle,
                    identifier: identifier,
                    label: label,
                    modifiers: extractModifiers(from: toggleCode),
                    hasAction: false
                ))
            }
        }
        
        return toggles
    }
    
    /// Extract navigation links from the SwiftUI code
    /// - Parameter code: The SwiftUI code
    private func extractNavigationLinks(from code: String) -> [UIElement] {
        var navigationLinks = [UIElement]()
        
        // Look for NavigationLink("label") { ... } or NavigationLink(destination: ...) { Text("label") }
        let pattern = "NavigationLink\\s*\\(?\\s*(?:destination:\\s*.+?\\s*\\)?\\s*\\{)?\\s*(?:\"(.+?)\"|Text\\s*\\(\\s*\"(.+?)\"\\s*\\))\\s*\\)?"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return navigationLinks
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            var label = ""
            
            if let labelRange = Range(match.range(at: 1), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
            } else if let labelRange = Range(match.range(at: 2), in: code), !code[labelRange].isEmpty {
                label = String(code[labelRange])
            } else {
                continue
            }
            
            // Try to find identifier in the same block
            let navLinkRange = match.range
            let endOfNavLinkDeclaration = min(navLinkRange.location + navLinkRange.length + 100, code.count)
            let navLinkCodeRange = NSRange(location: navLinkRange.location, length: endOfNavLinkDeclaration - navLinkRange.location)
            
            if let navLinkCodeRange = Range(navLinkCodeRange, in: code) {
                let navLinkCode = String(code[navLinkCodeRange])
                let identifier = extractAccessibilityIdentifier(from: navLinkCode)
                
                navigationLinks.append(UIElement(
                    type: .navigationLink,
                    identifier: identifier,
                    label: label,
                    modifiers: extractModifiers(from: navLinkCode),
                    hasAction: true
                ))
            }
        }
        
        return navigationLinks
    }
    
    /// Extract accessibility identifier from a code snippet
    /// - Parameter code: The SwiftUI code
    private func extractAccessibilityIdentifier(from code: String) -> String? {
        // Look for .accessibility(identifier: "id")
        let pattern = "\\.accessibility\\(identifier:\\s*\"(.+?)\"\\s*\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count)),
              let range = Range(match.range(at: 1), in: code) else {
            return nil
        }
        
        return String(code[range])
    }
    
    /// Extract view modifiers from a code snippet
    /// - Parameter code: The SwiftUI code
    private func extractModifiers(from code: String) -> [String] {
        var modifiers = [String]()
        
        // Look for .modifier()
        let pattern = "\\.([a-zA-Z0-9_]+)\\s*\\("
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return modifiers
        }
        
        let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
        
        for match in matches {
            guard let range = Range(match.range(at: 1), in: code) else {
                continue
            }
            
            let modifier = String(code[range])
            modifiers.append(modifier)
        }
        
        return modifiers
    }
}

extension SwiftUIAnalyzer.UIElement.ElementType: Equatable {
    public static func == (lhs: SwiftUIAnalyzer.UIElement.ElementType, rhs: SwiftUIAnalyzer.UIElement.ElementType) -> Bool {
        switch (lhs, rhs) {
        case (.button, .button),
            (.textField, .textField),
            (.secureField, .secureField),
            (.text, .text),
            (.toggle, .toggle),
            (.picker, .picker),
            (.slider, .slider),
            (.navigationLink, .navigationLink),
            (.list, .list):
            return true
        case (.custom(let lhsValue), .custom(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}