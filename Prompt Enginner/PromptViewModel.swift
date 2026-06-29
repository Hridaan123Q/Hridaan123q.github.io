// PromptViewModel.swift
// Prompt Engineer — Cross-platform (iOS · iPadOS · macOS · visionOS)

import Foundation
import SwiftUI
import Combine

// MARK: - Processing State
enum ProcessingState: Equatable {
    case idle
    case loading
    case question(text: String)
    case success
    case failed(message: String)

    var isLoading: Bool { self == .loading }

    var statusText: String {
        switch self {
        case .idle:               return "Ready"
        case .loading:            return "Analyzing & refining prompt…"
        case .question:           return "Awaiting clarification…"
        case .success:            return "Engineered successfully ✓"
        case .failed(let msg):    return "Error — \(msg)"
        }
    }
}

// MARK: - Theme Preference
enum ThemePreference: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - View Model
@MainActor
final class PromptViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var conversationLog: [ChatMessage] = [] // Tracks system-compliant conversational history logs
    @Published var processingState: ProcessingState = .idle
    @Published var isShowingSettings: Bool = false
    @Published var showCopiedToast: Bool = false
    @AppStorage("com.promptengineer.theme") var themePreference: ThemePreference = .system

    private var transformTask: Task<Void, Never>?
    private let service: LLMServiceProtocol

    var canTransform: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !processingState.isLoading
    }

    var hasOutput: Bool {
        !outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Dependency injection defaulting to production layout wrapper
    init(service: LLMServiceProtocol = ProductionLLMService()) {
        self.service = service
    }

    func transformPrompt() {
        guard canTransform else { return }

        let currentInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Wrap input structurally inside the engineering template profile wrapper before shipping
        let structuredUserMessage = PromptTemplate.userMessage(for: currentInput)
        conversationLog.append(ChatMessage(role: "user", content: structuredUserMessage))

        processingState = .loading
        inputText = "" // Clear input field for next follow-up message

        transformTask = Task {
            do {
                // Pass structured chat array down to the engine
                let response = try await service.engineerPrompt(history: conversationLog)
                guard !Task.isCancelled else { return }

                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

                // If the engine prefixes its choice with a question flag, trap it in interactive state
                if trimmedResponse.hasPrefix("QUESTION:") {
                    let cleanedQuestion = trimmedResponse.replacingOccurrences(of: "QUESTION:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

                    // Retain the AI's question output back in history context logs
                    conversationLog.append(ChatMessage(role: "assistant", content: response))
                    processingState = .question(text: cleanedQuestion)
                } else {
                    outputText = trimmedResponse
                    processingState = .success
                }
            } catch {
                processingState = .failed(message: error.localizedDescription)
            }
        }
    }

    func cancel() {
        transformTask?.cancel()
        transformTask = nil
        processingState = .idle
    }

    func copyOutput() {
        guard hasOutput else { return }
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        #else
        UIPasteboard.general.string = outputText
        #endif
        Task {
            showCopiedToast = true
            try? await Task.sleep(for: .seconds(2))
            showCopiedToast = false
        }
    }

    func clearAll() {
        cancel()
        inputText = ""
        outputText = ""
        conversationLog.removeAll()
        processingState = .idle
    }
}
