// LLMService.swift
// PromptArchitect — Cross-platform (iOS · iPadOS · macOS · visionOS)

import Foundation

enum LLMError: LocalizedError {
    case generalError
    case invalidURL
    case invalidResponse
    case authenticationError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .generalError: return "An unexpected error occurred in the sandbox runtime loop."
        case .invalidURL: return "The endpoint configuration URL is invalid."
        case .invalidResponse: return "The server returned an unparseable response structure."
        case .authenticationError: return "Authentication failed. Please verify your OpenAI API Key in Settings."
        case .apiError(let msg): return "API Error: \(msg)"
        }
    }
}

protocol LLMServiceProtocol: Sendable {
    func engineerPrompt(history: [ChatMessage]) async throws -> String
}

// MARK: - OpenAI Payload Formats
struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let max_tokens: Int
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Production Implementation
final class ProductionLLMService: LLMServiceProtocol, @unchecked Sendable {
    init() {}

    func engineerPrompt(history: [ChatMessage]) async throws -> String {
        // Fallback safely to Mock Simulation if sandbox is explicitly checked
        if APIConfiguration.shared.useMockService {
            let mockService = MockLLMService()
            return try await mockService.engineerPrompt(history: history)
        }

        let config = APIConfiguration.shared
        guard let url = URL(string: config.endpoint.absoluteString) else {
            throw LLMError.invalidURL
        }

        // Inject System Architecture guidelines ahead of the user history stream
        var payloadMessages = [ChatMessage(role: "system", content: PromptTemplate.systemPrompt)]
        payloadMessages.append(contentsOf: history)

        let requestBody = ChatCompletionRequest(
            model: config.model,
            messages: payloadMessages,
            max_tokens: config.maxTokens
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw LLMError.authenticationError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw LLMError.apiError("Server responded with status code \(httpResponse.statusCode).")
        }

        let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let rawReply = decodedResponse.choices.first?.message.content else {
            throw LLMError.invalidResponse
        }

        return rawReply
    }
}

// MARK: - Context-Aware Interactive Simulation Service
struct MockLLMService: LLMServiceProtocol {
    var simulatedDelay: Double = 0.6

    func engineerPrompt(history: [ChatMessage]) async throws -> String {
        try? await Task.sleep(for: .seconds(simulatedDelay))

        // Pull context from the very first user message inside history matrix
        let initialInput = history.first?.content ?? ""
        let lowercasedInput = initialInput.lowercased()
        let dynamicDomain: String
        let structuralType: String

        if lowercasedInput.contains("voice") || lowercasedInput.contains("audio") || lowercasedInput.contains("speech") {
            dynamicDomain = "AI Voice Processing & Multi-Modal Generative Imaging Pipelines"
            structuralType = "Audio-to-Image Generation Application"
        } else if lowercasedInput.contains("game") || lowercasedInput.contains("voxel") || lowercasedInput.contains("render") {
            dynamicDomain = "3D Engine Architecture & Procedural Generation Graphics Topologies"
            structuralType = "Voxel Engine Framework"
        } else if lowercasedInput.contains("stop-motion") || lowercasedInput.contains("lego") || lowercasedInput.contains("video") {
            dynamicDomain = "Digital Asset Animation Automation & Frame Sequence Rendering"
            structuralType = "Stop-Motion Video Sequencing Script"
        } else {
            dynamicDomain = "Advanced Native System Architectures & Full-Stack Toolkits"
            structuralType = "Software Implementation Blueprint"
        }

        // TURN 1: If history contains only 1 user statement, ask context questions
        if history.count <= 1 {
            if structuralType == "Audio-to-Image Generation Application" {
                return """
                QUESTION: The provided configuration setup for the Voice-to-Image application layout is structurally vague. To refine this into an elite production framework, please clarify:
                1. Which core runtime engine or cloud API endpoints should handle the speech-to-text decoding and diffusion image generation (e.g., local Whisper model, CoreML, OpenAI DALL-E 3, or Midjourney APIs)?
                2. How should brush rendering styles (oil, pencil, pen) be handled—via text-prompt structural injections, or real-time style-transfer model pipelines?
                """
            } else {
                return """
                QUESTION: The provided asset setup instruction for this \(structuralType) environment is structurally vague. To transform it into a professional production template, please clarify:
                1. What specific target runtime SDK environment or framework dependencies should this master persona prioritize?
                2. Do you require explicit architectural error handling routines or modular structural constraints for this custom setup?
                """
            }
        }

        // TURN 2: Generate mock compilation blueprint based on historical refinement answers
        else {
            let refinementDetails = history.last?.content ?? ""

            let dynamicConstraints: String
            if structuralType == "Audio-to-Image Generation Application" {
                dynamicConstraints = """
                • Enforce a strict asynchronous architecture to avoid blocking the main user interface thread during heavy AI model rendering cycles.
                • Disallow any unfiltered raw user transcription inputs; include a preprocessing layer to optimize speech tokens before image generation.
                • Implement robust network timeout fallbacks and elegant service-unavailable states for real-time API request matrices.
                """
            } else {
                dynamicConstraints = """
                • Enforce strict, compile-time type-safety metrics, eliminating implicit optional wrappers throughout execution.
                • Disallow all secondary thread side-effects by isolating mutating data loops within strict actor topologies.
                • Enforce structured error propagation boundaries across all remote network operations.
                """
            }

            return """
            You are an elite, senior-level Expert Systems Engineer and Principal Prompt Architect specializing in \(dynamicDomain).

            ## Context
            The engineering team is deploying a high-performance, cross-platform architectural matrix for a comprehensive \(structuralType). The implementation details must accommodate the following developer parameters and runtime refinements: "\(refinementDetails)".

            ## Task
            Optimize the following initial functional requirement stream into an impeccably designed, production-ready system configuration profile blueprint:
            "\(initialInput)"

            ## Constraints
            \(dynamicConstraints)

            ## Output Format
            Return an optimized, enterprise-grade system declaration blueprint enclosed cleanly inside markdown code blocks. Include clean architectural flow summaries and code-base sequence blueprints.
            """
        }
    }
}
