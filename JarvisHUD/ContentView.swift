import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var command: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("JARVIS")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            ScrollView {
                Text(networkManager.responseText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)

            HStack {
                TextField("Enter command...", text: $command)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendCommand()
                    }

                Button(action: sendCommand) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(command.isEmpty ? .gray : .blue)
                }
                .disabled(command.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 400)
    }

    private func sendCommand() {
        guard !command.isEmpty else { return }
        let currentCommand = command
        command = "" // clear input immediately

        Task {
            await networkManager.sendCommand(currentCommand)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
