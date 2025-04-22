import Foundation

/// Errors that can occur during test generation
enum TestGenerationError: Error {
    case invalidViewInfo(String)
    case unsupportedViewType
    case generationFailure(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidViewInfo(let details):
            return "Invalid view information: \(details)"
        case .unsupportedViewType:
            return "Unsupported view type for test generation"
        case .generationFailure(let details):
            return "Failed to generate tests: \(details)"
        }
    }
}

/// A class responsible for generating XCUITest code based on analyzed SwiftUI code
public class XCUITestGenerator {
    
    /// Test generation configuration options
    public struct GenerationOptions {
        /// Whether to include suggestions for missing accessibility identifiers
        var includeSuggestions: Bool = true
        
        /// Whether to generate tests for state changes
        var includeStateTests: Bool = true
        
        /// Whether to generate navigation tests
        var includeNavigationTests: Bool = true
        
        /// Whether to include comprehensive comments
        var includeComments: Bool = true
        
        /// Whether to generate launchArguments for UI testing
        var includeLaunchArguments: Bool = true
        
        /// Static default options
        public static let `default` = GenerationOptions()
    }
    
    /// Generates XCUITest code for the given view info.
    /// - Parameters:
    ///   - viewInfo: The analyzed view information
    ///   - options: Options for test generation
    /// - Returns: XCUITest code as a string
    /// - Throws: TestGenerationError if generation fails
    public func generateTests(for viewInfo: SwiftUIAnalyzer.ViewInfo, options: GenerationOptions = .default) throws -> String {
        var testCode =  """
        import XCTest
        
        class \(viewInfo.name)Tests: XCTestCase {
            
            let app = XCUIApplication()
            
            override func setUpWithError() throws {
                continueAfterFailure = false
                // Launch the app and wait for it to be ready
                app.launch()
                
                // Navigate to \(viewInfo.name) if needed
                // This depends on your app's structure
            }
            
            /// Test that verifies all UI elements exist
            func testElementsExist() throws {
        """
        
        // Add element existence checks
        if viewInfo.elements.isEmpty {
            testCode += "\n        // No UI elements found to test\n"
        } else {
            for element in viewInfo.elements {
                let identifier = element.identifier ?? self.identifierForElement(element)
                
                if !identifier.isEmpty {
                    let elementType = xcuiElementType(for: element.type)
                    
                    testCode += """
                    
                        // Check that \(element.label) exists
                        XCTAssertTrue(app.\(elementType)s["\(identifier)"].exists)
                    """
                }
            }
        }
        
        testCode += """
        
            }
        """
        
        // Generate interaction tests based on element types
        testCode += generateInteractionTests(for: viewInfo)
        
        // If there are state variables that affect the UI, generate state change tests
        if !viewInfo.stateVariables.isEmpty {
            testCode += generateStateChangeTests(for: viewInfo)
        }
        
        // If it's a navigation view, generate navigation tests
        if viewInfo.isNavigationView {
            testCode += generateNavigationTests(for: viewInfo)
        }
        
        testCode += """
        
        }
        """
        
        // Add suggested accessibility identifiers if missing
        testCode += generateAccessibilityIdentifierSuggestions(for: viewInfo)
        
        return testCode
    }
    
    // MARK: - Helper Methods
    
    /// Generates a default identifier for an element if none is provided.
    private func identifierForElement(_ element: SwiftUIAnalyzer.UIElement) -> String {
        let words = element.label
            .lowercased()
            .components(separatedBy: " ")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        
        switch element.type {
        case .button:
            return "\(sanitizedLabel)_button"
        case .textField:
            return words.map { String($0.prefix(1)) }.joined() + "_field"
        case .secureField:
            return words.map { String($0.prefix(1)) }.joined() + "_sf"
        case .text:
            return words.map { String($0.prefix(1)) }.joined() + "_text"
        case .toggle:
            return words.map { String($0.prefix(1)) }.joined() + "_toggle"
        case .picker:
            return words.map { String($0.prefix(1)) }.joined() + "_picker"
        case .slider:
            return words.map { String($0.prefix(1)) }.joined() + "_slider"
        case .navigationLink:
            return words.map { String($0.prefix(1)) }.joined() + "_link"
        case .list:
            return words.map { String($0.prefix(1)) }.joined() + "_list"
        case .custom(let customType):
            return words.map { String($0.prefix(1)) }.joined() + "_\(customType.lowercased())"
        }
        
        let sanitizedLabel = words.joined(separator: "")
        return "\(sanitizedLabel)_\(String(describing: element.type).lowercased())"
    }
    
    /// Returns the XCUIElement type string for a UI element type.
    /// - Parameter elementType: The type of the UI element.
    /// - Returns: The corresponding XCUIElement type string.
    private func xcuiElementType(for elementType: SwiftUIAnalyzer.UIElement.ElementType) -> String {
        switch elementType {
        case .button, .navigationLink:
            return "button"
        case .textField:
        case .secureField:
            return "secureTextField"
        case .text:
            return "staticText"
        case .toggle:
            return "switch"
        case .picker:
            return "picker"
        case .slider:
            return "slider"
        case .list:
            return "table"
        case .custom(_):
            return "any"
        }
    }
    
    /// Generate tests for element interactions
    private func generateInteractionTests(for viewInfo: SwiftUIAnalyzer.ViewInfo) -> String {
        var interactionTests = ""
        
        // Test text fields
        let textFields = viewInfo.elements.filter { 
            $0.type == .textField || $0.type == .secureField 
        }
        
        if !textFields.isEmpty {
            interactionTests += """
            
                /// Test text input
                func testTextInput() throws {
            """
            
            for textField in textFields {
                let identifier = textField.identifier ?? self.identifierForElement(textField)
                let elementType = textField.type == .textField ? "textField" : "secureTextField"
                let text = "test input"
                    interactionTests += """
                
                    // Test input for \(textField.label)
                    let \(identifier)Field = app.\(elementType)s["\(identifier)"]
                    XCTAssertTrue(\(identifier)Field.exists)
                    \(identifier)Field.tap()
                    \(identifier)Field.typeText("test input")
                    XCTAssertEqual(\(identifier)Field.value as? String, "\(text)")
                    // Verify field contains text - note that secure fields won't show the actual text
                """
            }
            
            interactionTests += """
            
                }
            """
        }
        
        // Test buttons
        let buttons = viewInfo.elements.filter { 
            $0.type == .button && $0.hasAction 
        }
        
        if !buttons.isEmpty {
            interactionTests += """
            
                /// Test button taps
                func testButtonTaps() throws {
            """
            
            for button in buttons {
                let identifier = button.identifier ?? self.identifierForElement(button)
                    interactionTests += """

                    // Test tap on \(button.label) button
                    let \(identifier) = app.buttons["\(identifier)"]
                    XCTAssertTrue(\(identifier).exists)
                    \(identifier).tap()
                    // Add assertions for the expected result of tapping this button
                """
            }
            
            interactionTests += """
            
                }
            """
        }
        
        // Test toggles
        let toggles = viewInfo.elements.filter { $0.type == .toggle }
        
        if !toggles.isEmpty {
            interactionTests += """
            
                /// Test toggles
                func testToggles() throws {
            """
            
            for toggle in toggles {
                let identifier = toggle.identifier ?? self.identifierForElement(toggle)
                interactionTests += """
                
                    // Test \(toggle.label) toggle
                    let \(identifier) = app.switches["\(identifier)"]
                    XCTAssertTrue(\(identifier).exists)
                    
                    // Get initial value
                    let initialValue = \(identifier).value as? String
                    
                    // Toggle the switch
                    \(identifier).tap()
                    
                    // Verify value changed
                    let newValue = \(identifier).value as? String
                    XCTAssertNotEqual(initialValue, newValue)
                """
            }
            
            interactionTests += """
            
                }
            """
        }
        
        return interactionTests
    }
    
    /// Generate tests for state changes
    private func generateStateChangeTests(for viewInfo: SwiftUIAnalyzer.ViewInfo) -> String {
        var stateTests = """
        
            /// Test UI state changes
            func testStateChanges() throws {
        """
        
        // For boolean state variables that might affect UI visibility
        let booleanStates = viewInfo.stateVariables.filter { $0.value == "Bool" }
        
        for (stateName, _) in booleanStates {
            // Look for elements that might be conditionally shown based on this state
            let conditionalElements = viewInfo.elements.filter { element in
                // This is a simplistic approach - in reality, we'd need more sophisticated code analysis
                element.label.contains(stateName) || 
                element.modifiers.contains(where: { $0.contains(stateName) })
            }
            
            if !conditionalElements.isEmpty {
                for element in conditionalElements {
                    let identifier = element.identifier ?? self.identifierForElement(element)
                    let elementType = xcuiElementType(for: element.type)
                    
                    stateTests += """
                    
                        // Find elements that may be affected by \(stateName) state
                        // This test assumes elements appear/disappear based on state
                        // You'll need to modify this based on your app's actual behavior
                        
                        // Try to trigger the state change
                        // (This is app-specific - replace with actual trigger mechanism)
                        
                        // Verify state-dependent UI changes
                        // Example: XCTAssertTrue(app.\(elementType)s["\(identifier)"].exists)
                    """
                }
            }
        }
        
        stateTests += """
        
            }
        """
        
        return stateTests
    }
    
    /// Generate tests for navigation
    private func generateNavigationTests(for viewInfo: SwiftUIAnalyzer.ViewInfo) -> String {
        var navigationTests = """
        
            /// Test navigation
            func testNavigation() throws {
        """
        
        // Find navigation links
        let navigationLinks = viewInfo.elements.filter { $0.type == .navigationLink }
        
        if !navigationLinks.isEmpty {
            for navLink in navigationLinks {
                let identifier = navLink.identifier ?? self.identifierForElement(navLink)
                
                navigationTests += """
                
                    // Test navigation for \(navLink.label)
                    let \(identifier) = app.buttons["\(identifier)"]
                    XCTAssertTrue(\(identifier).exists)
                    \(identifier).tap()
                    
                    // Verify navigation occurred
                    // (This is app-specific - replace with actual destination verification)
                    // Example: XCTAssertTrue(app.navigationBars["Destination"].exists)
                    
                    // Navigate back
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                """
            }
        } else {
            navigationTests += """
            
                // No navigation links found in this view
                // Add custom navigation test code here
            """
        }
        
        navigationTests += """
        
            }
        """
        
        return navigationTests
    }
    
    /// Generate suggestions for missing accessibility identifiers
    private func generateAccessibilityIdentifierSuggestions(for viewInfo: SwiftUIAnalyzer.ViewInfo) -> String {
        let elementsWithoutIdentifiers = viewInfo.elements.filter { $0.identifier == nil }
        
        if elementsWithoutIdentifiers.isEmpty {
            return ""
        }
        
        var suggestions = """
        
        /* ACCESSIBILITY SUGGESTIONS
         The following UI elements are missing accessibility identifiers.
         Consider adding them to improve testability:
        """
        
        for element in elementsWithoutIdentifiers {
            let suggestedIdentifier = identifierForElement(element)
            
            suggestions += """
            
            - \(element.label) (\(element.type)): 
              .accessibility(identifier: "\(suggestedIdentifier)")
            """
        }
        
        suggestions += """
        
         */
        """
        
        return suggestions
    }
}
