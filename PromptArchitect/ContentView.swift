// ContentView.swift
// PromptArchitect — Cross-platform (iOS · iPadOS · macOS · visionOS)

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = PromptViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        Group {
            if hSizeClass == .compact {
                CompactLayout(viewModel: viewModel)
            } else {
                WideLayout(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .preferredColorScheme(viewModel.themePreference.colorScheme)
    }
}

private struct WideLayout: View {
    @ObservedObject var viewModel: PromptViewModel

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            InputPane(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 360, ideal: 500, max: 700)
        } detail: {
            NavigationStack {
                OutputPane(viewModel: viewModel)
                    .navigationTitle("Engineered Prompt")
            }
        }
        .navigationTitle("PromptArchitect")
        #if os(macOS)
        .navigationSubtitle(viewModel.processingState.statusText)
        #endif
    }
}

private struct CompactLayout: View {
    @ObservedObject var viewModel: PromptViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InputPane(viewModel: viewModel)
                    .navigationTitle("Input Workspace")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                viewModel.transformPrompt()
                                selectedTab = 1
                            } label: {
                                Label("Transform", systemImage: "sparkles")
                            }
                            .disabled(!viewModel.canTransform)
                        }
                    }
            }
            .tabItem {
                Label("Input", systemImage: "doc.text.magnifyingglass")
            }
            .tag(0)

            NavigationStack {
                VStack(spacing: 0) {
                    OutputPane(viewModel: viewModel)

                    // Embedded Chat Interface for answering follow-up questions inline
                    if case .question = viewModel.processingState {
                        VStack(spacing: 8) {
                            Divider()
                            HStack(alignment: .bottom, spacing: 12) {
                                TextField("Type answers to clarification questions here...", text: $viewModel.inputText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(1...5)

                                Button {
                                    viewModel.transformPrompt()
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(viewModel.canTransform ? .blue : .secondary)
                                }
                                .disabled(!viewModel.canTransform)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .background(.ultraThinMaterial)
                    }
                }
                .navigationTitle("Engineered Prompt")
            }
            .tabItem {
                Label("Output", systemImage: "sparkles.rectangle.stack")
            }
            .tag(1)
        }
    }
}

private struct InputPane: View {
    @ObservedObject var viewModel: PromptViewModel

    var hintText: String {
        if case .question = viewModel.processingState {
            return "Type your answer to the clarification questions here..."
        }
        return "Paste your vague prompt here..."
    }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.inputText)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .overlay(alignment: .topLeading) {
                    if viewModel.inputText.isEmpty {
                        Text(hintText)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            #if !os(iOS)
            Divider()
            HStack {
                Button(action: viewModel.clearAll) {
                    Label("Reset Session", systemImage: "trash")
                }
                .disabled(viewModel.inputText.isEmpty && !viewModel.hasOutput && viewModel.conversationLog.isEmpty)

                Spacer()

                Button(action: viewModel.transformPrompt) {
                    HStack {
                        if case .question = viewModel.processingState {
                            Text("Submit Clarification")
                            Image(systemName: "arrow.up.circle.fill")
                        } else {
                            Text("Transform")
                            Image(systemName: "sparkles")
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!viewModel.canTransform)
            }
            .padding()
            #endif
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button(action: viewModel.clearAll) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.inputText.isEmpty && !viewModel.hasOutput && viewModel.conversationLog.isEmpty)
            }
            #endif

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
    }
}

private struct OutputPane: View {
    @ObservedObject var viewModel: PromptViewModel

    var body: some View {
        ZStack {
            if viewModel.processingState.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Analyzing Context & Formatting Layout...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            } else if case .question(let text) = viewModel.processingState {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.bubble")
                                .font(.title3)
                                .foregroundColor(.amber)
                            Text("Refinement Context Required")
                                .font(.headline)
                        }

                        Text(text)
                            .font(.body)
                            .lineSpacing(4)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)

                        Text("💡 Action Required: Please type your details into the input field below to complete configuration profiles.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else if viewModel.hasOutput {
                ScrollView {
                    Text(viewModel.outputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .safeAreaInset(edge: .bottom) {
                    if viewModel.showCopiedToast {
                        Text("Copied to Clipboard!")
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.bottom, 16)
                    }
                }
            } else if case .failed(let errorMsg) = viewModel.processingState {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error")
                        .font(.headline)
                    Text(errorMsg)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Interactive Prompt Engine Active")
                        .font(.headline)
                    Text("Enter an initial instruction stream to begin refinement.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .toolbar {
            if viewModel.hasOutput {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.copyOutput) {
                        Label("Copy Prompt", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: PromptViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyField: String = ""
    @State private var sandboxToggle: Bool = true
    @State private var draftTheme: ThemePreference = .system

    var body: some View {
        NavigationStack {
            Form {
                Section("Environment Matrix") {
                    Toggle("Enable Sandbox Mode LLM", isOn: $sandboxToggle)
                        .disabled(false)

                    Text(sandboxToggle ? "Forced Sandbox Mode active. Multi-turn local routing validation loop is running." : "Production routing active. Ready for live API deployment calls.")
                        .font(.caption)
                        .foregroundColor(sandboxToggle ? .blue : .secondary)
                }

                Section("OpenAI Profile Framework") {
                    SecureField("OpenAI API Key", text: $apiKeyField)
                }

                Section("Interface Preferences") {
                    Picker("Theme", selection: $draftTheme) {
                        ForEach(ThemePreference.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
            }
            .navigationTitle("Configuration Controls")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        viewModel.themePreference = draftTheme
                        APIConfiguration.shared.useMockService = sandboxToggle
                        APIConfiguration.shared.apiKey = apiKeyField
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKeyField = APIConfiguration.shared.apiKey
                sandboxToggle = APIConfiguration.shared.useMockService
                draftTheme = viewModel.themePreference
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 450)
        #endif
    }
}

// MARK: - Structural Design System Extensions
extension Color {
    /// Custom asset color definition matching native amber system profiles
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.0)
}
