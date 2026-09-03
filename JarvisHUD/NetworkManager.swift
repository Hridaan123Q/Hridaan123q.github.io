import Foundation
import Combine

class NetworkManager: ObservableObject {
    @Published var responseText: String = "System Ready."

    // Targeting the FastAPI backend over Tailscale/Local network
    // Server PC's Tailscale IP
    private let endpointURL = URL(string: "http://100.120.119.86:8000/execute")!

    struct CommandRequest: Codable {
        let command: String
    }

    struct CommandResponse: Codable {
        let status: String
        let result: String
    }

    @MainActor
    func sendCommand(_ command: String) async {
        responseText = "Executing: \(command)..."

        let requestBody = CommandRequest(command: command)

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                self.responseText = "Error: Invalid response from backend."
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                self.responseText = "Error: Server returned status code \(httpResponse.statusCode)."
                return
            }

            let decodedResponse = try JSONDecoder().decode(CommandResponse.self, from: data)
            self.responseText = decodedResponse.result

        } catch {
            self.responseText = "Execution failed: \(error.localizedDescription)"
        }
    }
}
