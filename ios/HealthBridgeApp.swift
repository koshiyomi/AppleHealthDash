import SwiftUI

@main
struct HealthBridgeApp: App {
    @StateObject private var controller = HealthDataController()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(controller)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var controller: HealthDataController
    @State private var token: String = ""
    @State private var statusMessage: String = ""

    private var sortedMetrics: [(key: String, value: String)] {
        controller.metrics.sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            Section(header: Text("Authorization")) {
                Button("Request Health Access") {
                    Task {
                        do {
                            try await controller.requestAuthorization()
                            statusMessage = "Authorization granted"
                        } catch {
                            statusMessage = "Authorization failed: \(error.localizedDescription)"
                        }
                    }
                }
            }

            Section(header: Text("Fetch & Send")) {
                Button("Fetch Metrics") {
                    Task { await controller.loadLatestMetrics() }
                }

                VStack(alignment: .leading) {
                    Text("Session Token")
                    SecureField("Short-lived bearer token", text: $token)
                        .textContentType(.password)
                }

                Button("Send to API") {
                    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        statusMessage = "Token required"
                        return
                    }
                    Task {
                        do {
                            try await controller.sendMetrics(token: trimmed)
                            statusMessage = "Metrics sent"
                        } catch {
                            statusMessage = "Send failed: \(error.localizedDescription)"
                        }
                    }
                }
            }

            Section(header: Text("Latest Metrics")) {
                ForEach(sortedMetrics, id: \.key) { key, value in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(value)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !statusMessage.isEmpty {
                Section(header: Text("Status")) {
                    Text(statusMessage)
                }
            }
        }
        .navigationTitle("Health Bridge")
    }
}
