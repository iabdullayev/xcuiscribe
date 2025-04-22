//
//  XCUITestGeneratorAppApp.swift
//  XCUITestGeneratorApp
//
//  Created by Abdullayev, Iskandar on 4/7/25.
//

import SwiftUI

@main
struct XCUITestGeneratorAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                apiKey: .constant(""),
                showingWelcome: .constant(true),
                saveApiKey: { _ in }
            )
        }
    }
}
