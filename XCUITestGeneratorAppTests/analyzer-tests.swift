import XCTest
@testable import XCUITestGenerator

class SwiftUIAnalyzerTests: XCTestCase {
    
    // The analyzer instance to test
    var analyzer: SwiftUIAnalyzer!
    
    override func setUp() {
        super.setUp()
        analyzer = SwiftUIAnalyzer()
    }
    
    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testBasicViewAnalysis() {
        // A basic SwiftUI view with text and a button
        let swiftUICode = """
        import SwiftUI
        
        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Hello, World!")
                    Button("Tap Me") {
                        print("Button tapped")
                    }
                }
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(swiftUICode)
        
        // Check the result
        switch result {
        case .success(let viewInfo):
            // Verify the view name
            XCTAssertEqual(viewInfo.name, "TestView")
            
            // Verify that elements were extracted
            XCTAssertEqual(viewInfo.elements.count, 2)
            
            // Verify the text element
            let textElement = viewInfo.elements.first { $0.type == .text }
            XCTAssertNotNil(textElement)
            XCTAssertEqual(textElement?.label, "Hello, World!")
            
            // Verify the button element
            let buttonElement = viewInfo.elements.first { $0.type == .button }
            XCTAssertNotNil(buttonElement)
            XCTAssertEqual(buttonElement?.label, "Tap Me")
            XCTAssertTrue(buttonElement?.hasAction ?? false)
            
        case .failure(let error):
            XCTFail("Analysis failed with error: \(error.localizedDescription)")
        }
    }
    
    func testAccessibilityIdentifiers() {
        // A SwiftUI view with accessibility identifiers
        let swiftUICode = """
        import SwiftUI
        
        struct AccessibilityTestView: View {
            var body: some View {
                VStack {
                    Text("Hello, World!")
                        .accessibility(identifier: "greeting_text")
                    
                    Button("Login") {
                        print("Login tapped")
                    }
                    .accessibility(identifier: "login_button")
                    
                    TextField("Username", text: .constant(""))
                        .accessibility(identifier: "username_field")
                }
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(swiftUICode)
        
        // Check the result
        switch result {
        case .success(let viewInfo):
            // Verify the view name
            XCTAssertEqual(viewInfo.name, "AccessibilityTestView")
            
            // Verify that elements were extracted with accessibility identifiers
            XCTAssertEqual(viewInfo.elements.count, 3)
            
            // Verify the text element with identifier
            let textElement = viewInfo.elements.first { $0.type == .text }
            XCTAssertNotNil(textElement)
            XCTAssertEqual(textElement?.identifier, "greeting_text")
            
            // Verify the button element with identifier
            let buttonElement = viewInfo.elements.first { $0.type == .button }
            XCTAssertNotNil(buttonElement)
            XCTAssertEqual(buttonElement?.identifier, "login_button")
            
            // Verify the text field element with identifier
            let textFieldElement = viewInfo.elements.first { $0.type == .textField }
            XCTAssertNotNil(textFieldElement)
            XCTAssertEqual(textFieldElement?.identifier, "username_field")
            
        case .failure(let error):
            XCTFail("Analysis failed with error: \(error.localizedDescription)")
        }
    }
    
    func testInvalidCode() {
        // Non-SwiftUI code
        let nonSwiftUICode = """
        import Foundation
        
        class TestClass {
            func test() {
                print("Hello, World!")
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(nonSwiftUICode)
        
        // Check the result - should fail
        switch result {
        case .success:
            XCTFail("Analysis should have failed for non-SwiftUI code")
            
        case .failure(let error):
            // Verify the correct error was returned
            XCTAssertEqual(error, SwiftUIAnalyzerError.incompatibleViewType)
        }
    }
    
    func testComplexView() {
        // A more complex SwiftUI view with multiple elements and state
        let swiftUICode = """
        import SwiftUI
        
        struct ComplexView: View {
            @State private var username = ""
            @State private var password = ""
            @State private var isLoggedIn = false
            @State private var showError = false
            
            var body: some View {
                NavigationView {
                    VStack(spacing: 20) {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibility(identifier: "username_field")
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibility(identifier: "password_field")
                        
                        Button("Login") {
                            if username.isEmpty || password.isEmpty {
                                showError = true
                            } else {
                                isLoggedIn = true
                            }
                        }
                        .accessibility(identifier: "login_button")
                        
                        if showError {
                            Text("Please enter both username and password")
                                .foregroundColor(.red)
                                .accessibility(identifier: "error_message")
                        }
                        
                        if isLoggedIn {
                            Text("Welcome, \\(username)!")
                                .font(.title)
                                .accessibility(identifier: "welcome_message")
                        }
                    }
                    .padding()
                    .navigationTitle("Login")
                }
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(swiftUICode)
        
        // Check the result
        switch result {
        case .success(let viewInfo):
            // Verify the view name
            XCTAssertEqual(viewInfo.name, "ComplexView")
            
            // Verify that state variables were extracted
            XCTAssertEqual(viewInfo.stateVariables.count, 4)
            XCTAssertEqual(viewInfo.stateVariables["username"], "String")
            XCTAssertEqual(viewInfo.stateVariables["password"], "String")
            XCTAssertEqual(viewInfo.stateVariables["isLoggedIn"], "Bool")
            XCTAssertEqual(viewInfo.stateVariables["showError"], "Bool")
            
            // Verify that it's a navigation view
            XCTAssertTrue(viewInfo.isNavigationView)
            
            // Verify elements with identifiers
            XCTAssertGreaterThanOrEqual(viewInfo.elements.count, 5)
            
            // Verify specific elements
            XCTAssertNotNil(viewInfo.elements.first { $0.identifier == "username_field" })
            XCTAssertNotNil(viewInfo.elements.first { $0.identifier == "password_field" })
            XCTAssertNotNil(viewInfo.elements.first { $0.identifier == "login_button" })
            
        case .failure(let error):
            XCTFail("Analysis failed with error: \(error.localizedDescription)")
        }
    }
}
            XCTFail("Analysis failed with error: \(error.localizedDescription)")
        }
    }
    
    func testViewWithStateVariables() {
        // A SwiftUI view with state variables
        let swiftUICode = """
        import SwiftUI
        
        struct StateTestView: View {
            @State private var isActive = false
            @State private var text = ""
            
            var body: some View {
                VStack {
                    TextField("Enter text", text: $text)
                    Toggle("Is Active", isOn: $isActive)
                    
                    if isActive {
                        Text("Active")
                    }
                }
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(swiftUICode)
        
        // Check the result
        switch result {
        case .success(let viewInfo):
            // Verify the view name
            XCTAssertEqual(viewInfo.name, "StateTestView")
            
            // Verify that state variables were extracted
            XCTAssertEqual(viewInfo.stateVariables.count, 2)
            XCTAssertEqual(viewInfo.stateVariables["isActive"], "Bool")
            XCTAssertEqual(viewInfo.stateVariables["text"], "String")
            
            // Verify that elements were extracted
            XCTAssertEqual(viewInfo.elements.count, 3) // TextField, Toggle, and conditional Text
            
            // Verify the text field
            let textField = viewInfo.elements.first { $0.type == .textField }
            XCTAssertNotNil(textField)
            XCTAssertEqual(textField?.label, "Enter text")
            
            // Verify the toggle
            let toggle = viewInfo.elements.first { $0.type == .toggle }
            XCTAssertNotNil(toggle)
            XCTAssertEqual(toggle?.label, "Is Active")
            
        case .failure(let error):
            XCTFail("Analysis failed with error: \(error.localizedDescription)")
        }
    }
    
    func testNavigationView() {
        // A SwiftUI view with navigation
        let swiftUICode = """
        import SwiftUI
        
        struct NavigationTestView: View {
            var body: some View {
                NavigationView {
                    List {
                        NavigationLink("Go to Detail") {
                            Text("Detail View")
                        }
                        NavigationLink("Go to Settings") {
                            Text("Settings View")
                        }
                    }
                    .navigationTitle("Home")
                }
            }
        }
        """
        
        // Analyze the code
        let result = analyzer.analyze(swiftUICode)
        
        // Check the result
        switch result {
        case .success(let viewInfo):
            // Verify the view name
            XCTAssertEqual(viewInfo.name, "NavigationTestView")
            
            // Verify that it's a navigation view
            XCTAssertTrue(viewInfo.isNavigationView)
            
            // Verify that elements were extracted
            XCTAssertGreaterThanOrEqual(viewInfo.elements.count, 2) // At least 2 navigation links
            
            // Verify the navigation links
            let navLinks = viewInfo.elements.filter { $0.type == .navigationLink }
            XCTAssertEqual(navLinks.count, 2)
            
            // Verify the navigation link labels
            let linkLabels = navLinks.map { $0.label }
            XCTAssertTrue(linkLabels.contains("Go to Detail"))
            XCTAssertTrue(linkLabels.contains("Go to Settings"))
            
        case .failure(let error):