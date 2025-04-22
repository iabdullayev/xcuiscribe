# XCUITest Generator

An Xcode extension that automatically generates XCUITest code for your SwiftUI views, using a combination of static analysis and AI assistance.

## Features

- 🔍 Analyzes SwiftUI view code to identify UI elements, state variables, and navigation patterns
- 🤖 Generates appropriate XCUITest code tailored to your specific view
- 🧪 Creates comprehensive test cases for UI elements, user interactions, and state changes
- 🧪 Generates unit test code for classes and functions
- 🧩 Suggests accessibility identifiers for elements that don't have them
- 🔄 Integrates with Xcode via the Editor menu
- 🧠 Uses GitHub Copilot AI for complex or ambiguous code patterns

## Installation

### Requirements

- macOS 12.0+
- Xcode 14.0+
- A GitHub Copilot API key

### Steps

1. Download the latest release from GitHub
2. Copy the app to your Applications folder
3. Launch the XCUITest Generator app
4. Follow the onboarding to:
   - Enable the extension in System Preferences
5. Restart Xcode

## Usage

1. Open a SwiftUI file in Xcode
2. Select "Editor > Generate XCUITests for View" from the menu
3. The extension will analyze your code and generate XCUITest code
4. The generated code will be inserted at the end of your file with a suggestion to move it to a proper test file

To generate Unit tests:
1. Open a Swift file in Xcode.
2. Select "Editor > Generate Unit Tests" from the menu.
3. The extension will analyze your code and generate Unit Test code.
4. The generated code will be inserted at the end of your file with a suggestion to move it to a proper test file.


## How It Works

1. The extension first attempts to analyze your SwiftUI code using built-in static analysis
2. For simple views, it generates test code directly based on the detected UI elements
3. For complex views or ambiguous patterns, it falls back to GitHub Copilot AI for more sophisticated analysis
4. The generated tests include:
   - Element existence checks
   - User interaction tests (taps, text input)
   - State change tests
   - Navigation tests
   - Suggestions for accessibility identifiers
5. For swift files, it generates unit test based on the detected functions

## Privacy & Security

- Your API key is stored securely in the keychain
- SwiftUI code is processed locally when possible
- When code is sent to GitHub Copilot API, only the specific SwiftUI view code is sent
- No personal or project information is collected or transmitted

## Development

### Project Structure

- **XCUITestGenerator**: The main container app for configuration
- **XCUITestGeneratorExtension**: The Xcode Source Editor extension
- **Shared**: Code shared between the app and extension

### Building from Source

1. Clone this repository
2. Open the Xcode project
3. Update the signing identities for both targets
4. Build the project

## Troubleshooting

- **Extension not appearing in Xcode**: Make sure it's enabled in System Preferences > Extensions > Xcode Source Editor
- **API Key issues**: Try testing the connection in the main app
- **Analysis failures**: For complex views, try simplifying the view or breaking it into smaller components

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [GitHub Copilot](https://github.com/features/copilot) for the AI assistant capabilities
- [XcodeKit](https://developer.apple.com/documentation/xcodekit) for the extension framework
- The SwiftUI and XCUITest community for inspiration
