import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedFlyers: [SavedFlyer]
    @AppStorage("userCredits") private var credits: Int = 3
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guest User")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Sign in to sync your flyers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats section
                Section("Statistics") {
                    StatRow(icon: "doc.richtext", title: "Flyers Created", value: "\(savedFlyers.count)")
                    StatRow(icon: "sparkles", title: "Credits Remaining", value: "\(credits)")
                }

                // Account section
                Section("Account") {
                    Button {
                        // Coming soon
                    } label: {
                        Label("Sign In", systemImage: "person.badge.plus")
                    }

                    Button {
                        // Coming soon
                    } label: {
                        Label("Create Account", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                // Settings section
                Section("Settings") {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("API Settings", systemImage: "key")
                    }

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Show Onboarding Again", systemImage: "arrow.counterclockwise")
                    }
                }

                // About section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://openrouter.ai")!) {
                        Label("Powered by OpenRouter", systemImage: "link")
                    }
                }

                // Coming Soon section
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("Full Profile Coming Soon")
                            .font(.headline)

                        Text("Account management, cloud sync, and more features will be available in a future update.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
}

#Preview {
    ProfileTab()
}
