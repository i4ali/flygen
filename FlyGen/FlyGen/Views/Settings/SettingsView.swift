import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("openrouter_api_key") private var apiKey: String = ""
    @State private var editedKey: String = ""
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenRouter API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            if showingKey {
                                TextField("sk-or-...", text: $editedKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .monospaced))
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-or-...", text: $editedKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .monospaced))
                            }

                            Button {
                                showingKey.toggle()
                            } label: {
                                Image(systemName: showingKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        if editedKey != apiKey {
                            Button("Save") {
                                apiKey = editedKey
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Get your API key from openrouter.ai")
                        Link("Open OpenRouter", destination: URL(string: "https://openrouter.ai/keys")!)
                            .font(.subheadline)
                    }
                }

                Section {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text("Gemini Flash")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Provider")
                        Spacer()
                        Text("OpenRouter")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Generation Settings")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedKey = apiKey
            }
        }
    }
}

#Preview {
    SettingsView()
}
