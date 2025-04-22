import SwiftUI
import XCUITestGeneratorShared

// MARK: - Constants
struct Constants {
    static let keychainServiceName = "com.xcuitestgenerator.apikeys"
    static let apiKeyAccount = "anthropic-api-key"
    static let appGroupIdentifier = "group.com.xcuitestgenerator"
}

// MARK: - App Entry Point

@main
struct XCUITestGeneratorApp: App {
    // Use @AppStorage for preferences shared with the extension
    @AppStorage("showedWelcomeScreen", store: UserDefaults(suiteName: Constants.appGroupIdentifier))
    private var showedWelcomeScreen: Bool = false
    
    @State private var apiKey: String = ""
    @State private var isLoading: Bool = true
    
    // Create keychain manager
    private let keychainManager = KeychainManager(serviceName: Constants.keychainServiceName)
    
    var body: some Scene {
        WindowGroup {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        loadApiKey()
                    }
            } else {
                ContentView(
                    apiKey: $apiKey,
                    showingWelcome: Binding<Bool>(
                        get: { !showedWelcomeScreen },
                        set: { showedWelcomeScreen = !$0 }
                    ),
                    saveApiKey: saveApiKey
                )
            }
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("XCUITest Generator Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/yourusername/XCUITestGenerator/blob/main/Documentation/README.md")!)
                }
            }
        }
    }
    
    // Load API key from keychain
    private func loadApiKey() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let storedKey = try keychainManager.getString(forAccount: Constants.apiKeyAccount)
                DispatchQueue.main.async {
                    self.apiKey = storedKey
                    self.isLoading = false
                }
            } catch {
                // Key not found or error, just continue with empty string
                DispatchQueue.main.async {
                    self.apiKey = ""
                    self.isLoading = false
                }
            }
        }
    }
    
    // Save API key to keychain
    private func saveApiKey(_ key: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try keychainManager.save(string: key, forAccount: Constants.apiKeyAccount)
            } catch {
                print("Failed to save API key: \(error.localizedDescription)")
                // In a real app, we would show an error alert to the user
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Binding var apiKey: String
    @Binding var showingWelcome: Bool
    var saveApiKey: (String) -> Void
    
    var body: some View {
        if showingWelcome {
            WelcomeView(showingWelcome: $showingWelcome)
        } else {
            ConfigurationView(
                apiKey: $apiKey,
                saveApiKey: saveApiKey
            )
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Binding var showingWelcome: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("XCUITest Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Generate XCUITest Test Cases from SwiftUI Files")
                .font(.title2)
            
            Image(systemName: "wand.and.stars")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            
            Text("This extension uses AI to analyze your SwiftUI files and generate appropriate XCUITest test cases.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("To get started, you need to:")
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Enable the extension in System Preferences", systemImage: "1.circle")
                Label("Configure your Anthropic API key", systemImage: "2.circle")
                Label("Start using it in Xcode via Editor menu", systemImage: "3.circle")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            
            Button("Continue") {
                showingWelcome = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .frame(width: 500, height: 500)
    }
}

// MARK: - Configuration View

struct ConfigurationView: View {
    @Binding var apiKey: String
    var saveApiKey: (String) -> Void
    
    @State private var showingApiKeySaved = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("XCUITest Generator Configuration")
                .font(.title)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("1. Configure Anthropic API Key")
                    .font(.headline)
                
                HStack {
                    SecureField("Enter your Anthropic API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSaving)
                    
                    Button(action: {
                        saveKey()
                    }) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || apiKey.isEmpty)
                }
                
                if showingApiKeySaved {
                    Text("API Key saved successfully!")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                Divider()
                
                Text("2. Enable the Extension")
                    .font(.headline)
                
                Button("Open System Preferences Extensions") {
                    openSystemPreferencesExtensions()
                }
                .buttonStyle(.bordered)
                
                Text("In the Extensions panel, select 'Xcode Source Editor' and enable 'XCUITest Generator'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("3. Using the Extension")
                    .font(.headline)
                
                Text("Open a SwiftUI file in Xcode, then select 'Editor > Generate XCUITests for View' from the menu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("4. Testing the Extension")
                    .font(.headline)
                
                Button("Test API Key Connection") {
                    testApiKeyConnection()
                }
                .buttonStyle(.bordered)
                .disabled(apiKey.isEmpty || isSaving)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            
            Spacer()
            
            HStack {
                Button("Visit Documentation") {
                    openDocumentation()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 500, height: 550)
    }
    
    private func saveKey() {
        isSaving = true
        errorMessage = nil
        
        // Call the passed-in save function
        saveApiKey(apiKey)
        
        // Show success message
        showingApiKeySaved = true
        isSaving = false
        
        // Hide the confirmation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showingApiKeySaved = false
        }
    }
    
    private func testApiKeyConnection() {
        guard !apiKey.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        // Create a Copilot service instance
        let copilotService = CopilotService(apiKey: apiKey)
        
        // Send a simple test request
        copilotService.generateCode(with: "Say 'Connection successful'") { result in
            DispatchQueue.main.async {
                isSaving = false
                
                switch result {
                case .success:
                    showingApiKeySaved = true
                    errorMessage = nil
                    
                    // Hide the success message after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingApiKeySaved = false
                    }
                    
                case .failure(let error):
                    showingApiKeySaved = false
                    errorMessage = "API Test Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func openSystemPreferencesExtensions() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.extensions")!)
    }
    
    private func openDocumentation() {
        // Replace with your documentation URL if available
        NSWorkspace.shared.open(URL(string: "https://github.com/yourusername/XCUITestGenerator")!)
    }
}

#Preview {
    ContentView(
        apiKey: .constant(""),
        showingWelcome: .constant(true),
        saveApiKey: { _ in }
    )
}
