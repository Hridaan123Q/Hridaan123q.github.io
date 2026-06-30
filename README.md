# PromptArchitect

**PromptArchitect** is a cross-platform (iOS, iPadOS, macOS, visionOS) Swift application that acts as an elite, production-grade Prompt Engineer. It takes vague user ideas and refines them into highly structured, detailed app specification prompts ready to be used by an LLM.

Powered by Google's **Gemini 1.5 Flash**, the app connects directly to the OpenAI-compatible endpoint (`generativelanguage.googleapis.com`) to deliver lightning-fast prompt transformations.

## 🚀 Features

- **Cross-Platform Interface**: Built with SwiftUI for a seamless native experience across Apple devices.
- **Gemini Integration**: Uses Google's Gemini 1.5 Flash model for high-speed, intelligent prompt engineering.
- **5-Pillar Architectural Layout**: Enforces a strict output format detailing `original_problem_statement`, `user_choices`, `key_functionalities`, `app_type`, and `constraints`.
- **Interactive Refinement**: The AI can ask clarifying questions if the initial input is too vague before generating the final prompt.
- **Sandbox Mode**: Toggle between live API calls and a local mock simulation for UI testing.
- **One-Click Copy**: Easily copy the generated structured prompt to your clipboard.

## 🛠️ Setup Instructions

1. Clone this repository.
2. Open `PromptArchitect.xcodeproj` in Xcode 16 or later.
3. Build and run the app on your preferred simulator or physical device.
4. When the app launches, click the **Settings** icon (gear).
5. Enter your Google Gemini API Key.
6. Ensure "Enable Sandbox Mode LLM" is turned **OFF** to use the live API.
7. Start engineering your prompts!

## 📝 Example Output

Give it a vague prompt like: *"create a platform style naruto game with pixel art."*

And PromptArchitect will return a detailed spec:
```markdown
## Context
Adapt any user input into a comprehensive app specification prompt. ...

## Task
...
original_problem_statement: "create a platform style naruto game with pixel art."
user_choices:
- Character selection: multiple playable characters (Naruto, Sasuke, Sakura)
- ...
```

## 🎨 Design

The app includes a custom logo generated procedurally for this project, featuring a sleek, dark-themed prompt box with an accent of vibrant green and yellow sparkles, representing the magic of AI prompt generation.

## 📦 Releases

This repository uses **GitHub Actions** for CI/CD.
Whenever you push a tag (e.g., `v1.0`), the workflow will automatically compile the macOS `.app` binary and publish it directly to the GitHub Releases page as a `.zip` archive. No manual build steps required!
