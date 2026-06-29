// PromptEngineerApp.swift
// PromptArchitect — Cross-platform (iOS · iPadOS · macOS · visionOS)

import SwiftUI

@main
struct PromptEngineerApp: App {

    init() {
        // Default to real API for live environment
        APIConfiguration.shared.useMockService = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1_100, height: 700)
        #endif
    }
}
