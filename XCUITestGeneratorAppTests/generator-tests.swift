import XCTest
@testable import XCUITestGenerator

class XCUITestGeneratorTests: XCTestCase {
    
    // The generator instance to test
    var generator: XCUITestGenerator!
    
    override func setUp() {
        super.setUp()
        generator = XCUITestGenerator()
    }
    
    override func tearDown() {
        generator = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testBasicTestGeneration() throws {
        // Create a simple view info
        let viewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "SimpleView",
            stateVariables: [:],
            elements: [
                SwiftUIAnalyzer.UIElement(
                    type: .text,
                    identifier: "greeting_text",
                    label: "Hello, World!",
                    modifiers: [],
                    hasAction: false
                ),
                SwiftUIAnalyzer.UIElement(
                    type: .button,
                    identifier: "submit_button",
                    label: "Submit",
                    modifiers: [],
                    hasAction: true
                )
            ],
            isNavigationView: false,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Generate tests
        let testCode = try generator.generateTests(for: viewInfo)
        
        // Verify the generated code
        XCTAssertTrue(testCode.contains("class SimpleViewTests: XCTestCase"))
        XCTAssertTrue(testCode.contains("func testElementsExist()"))
        XCTAssertTrue(testCode.contains("app.staticTexts[\"greeting_text\"].exists"))
        XCTAssertTrue(testCode.contains("app.buttons[\"submit_button\"].exists"))
        XCTAssertTrue(testCode.contains("func testButtonTaps()"))
    }
    
    func testGenerationWithStateVariables() throws {
        // Create a view info with state variables
        let viewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "StateView",
            stateVariables: [
                "isEnabled": "Bool",
                "username": "String"
            ],
            elements: [
                SwiftUIAnalyzer.UIElement(
                    type: .textField,
                    identifier: "username_field",
                    label: "Username",
                    modifiers: [],
                    hasAction: false
                ),
                SwiftUIAnalyzer.UIElement(
                    type: .toggle,
                    identifier: "enabled_toggle",
                    label: "Enabled",
                    modifiers: [],
                    hasAction: false
                )
            ],
            isNavigationView: false,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Generate tests
        let testCode = try generator.generateTests(for: viewInfo)
        
        // Verify the generated code
        XCTAssertTrue(testCode.contains("class StateViewTests: XCTestCase"))
        XCTAssertTrue(testCode.contains("func testElementsExist()"))
        XCTAssertTrue(testCode.contains("app.textFields[\"username_field\"].exists"))
        XCTAssertTrue(testCode.contains("app.switches[\"enabled_toggle\"].exists"))
        XCTAssertTrue(testCode.contains("func testTextInput()"))
        XCTAssertTrue(testCode.contains("func testToggles()"))
        XCTAssertTrue(testCode.contains("func testStateChanges()"))
    }
    
    func testGenerationWithNavigation() throws {
        // Create a view info with navigation
        let viewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "NavigationView",
            stateVariables: [:],
            elements: [
                SwiftUIAnalyzer.UIElement(
                    type: .navigationLink,
                    identifier: "detail_link",
                    label: "Go to Detail",
                    modifiers: [],
                    hasAction: true
                ),
                SwiftUIAnalyzer.UIElement(
                    type: .navigationLink,
                    identifier: "settings_link",
                    label: "Go to Settings",
                    modifiers: [],
                    hasAction: true
                )
            ],
            isNavigationView: true,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Generate tests
        let testCode = try generator.generateTests(for: viewInfo)
        
        // Verify the generated code
        XCTAssertTrue(testCode.contains("class NavigationViewTests: XCTestCase"))
        XCTAssertTrue(testCode.contains("func testElementsExist()"))
        XCTAssertTrue(testCode.contains("app.buttons[\"detail_link\"].exists"))
        XCTAssertTrue(testCode.contains("app.buttons[\"settings_link\"].exists"))
        XCTAssertTrue(testCode.contains("func testNavigation()"))
    }
    
    func testGenerationWithMissingIdentifiers() throws {
        // Create a view info with elements missing identifiers
        let viewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "MissingIdentifiersView",
            stateVariables: [:],
            elements: [
                SwiftUIAnalyzer.UIElement(
                    type: .text,
                    identifier: nil,
                    label: "Title",
                    modifiers: [],
                    hasAction: false
                ),
                SwiftUIAnalyzer.UIElement(
                    type: .button,
                    identifier: nil,
                    label: "Save",
                    modifiers: [],
                    hasAction: true
                )
            ],
            isNavigationView: false,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Generate tests with suggestions for missing identifiers
        let options = XCUITestGenerator.GenerationOptions(includeSuggestions: true)
        let testCode = try generator.generateTests(for: viewInfo, options: options)
        
        // Verify the generated code includes suggestions
        XCTAssertTrue(testCode.contains("ACCESSIBILITY SUGGESTIONS"))
        XCTAssertTrue(testCode.contains(".accessibility(identifier: \"title_text\")"))
        XCTAssertTrue(testCode.contains(".accessibility(identifier: \"save_button\")"))
    }
    
    func testGenerationWithCustomOptions() throws {
        // Create a simple view info
        let viewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "OptionsView",
            stateVariables: ["isEnabled": "Bool"],
            elements: [
                SwiftUIAnalyzer.UIElement(
                    type: .button,
                    identifier: "action_button",
                    label: "Action",
                    modifiers: [],
                    hasAction: true
                )
            ],
            isNavigationView: true,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Create custom options
        let options = XCUITestGenerator.GenerationOptions(
            includeSuggestions: false,
            includeStateTests: true,
            includeNavigationTests: false,
            includeComments: true,
            includeLaunchArguments: true
        )
        
        // Generate tests with custom options
        let testCode = try generator.generateTests(for: viewInfo, options: options)
        
        // Verify the generated code reflects the options
        XCTAssertTrue(testCode.contains("func testStateChanges()"))
        XCTAssertFalse(testCode.contains("func testNavigation()"))
        XCTAssertFalse(testCode.contains("ACCESSIBILITY SUGGESTIONS"))
    }
    
    func testInvalidViewInfo() {
        // Test with invalid view info (no elements)
        let emptyViewInfo = SwiftUIAnalyzer.ViewInfo(
            name: "",
            stateVariables: [:],
            elements: [],
            isNavigationView: false,
            hasTabBar: false,
            hasAlert: false
        )
        
        // Expect an error
        XCTAssertThrowsError(try generator.generateTests(for: emptyViewInfo)) { error in
            XCTAssertEqual(error as? TestGenerationError, TestGenerationError.invalidViewInfo("View name cannot be empty"))
        }
    }
}
