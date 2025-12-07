import SwiftUI
import SwiftData

struct ProfileTab: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var savedFlyers: [SavedFlyer]
    @Query private var userProfiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingSettings = false

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

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
                            Text("iCloud User")
                                .font(.title3)
                                .fontWeight(.semibold)

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.icloud.fill")
                                    .foregroundColor(.green)
                                Text("Synced with iCloud")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats section
                Section("Statistics") {
                    StatRow(icon: "doc.richtext", title: "Flyers Created", value: "\(savedFlyers.count)")
                    StatRow(icon: "sparkles", title: "Credits Remaining", value: "\(credits)")
                }

                // iCloud section
                Section("iCloud") {
                    HStack {
                        Label("Sync Status", systemImage: "icloud")
                        Spacer()
                        Text(cloudKitService.isSignedIn ? "Connected" : "Not Connected")
                            .foregroundColor(cloudKitService.isSignedIn ? .green : .red)
                    }

                    if let lastSync = userProfiles.first?.lastSyncedAt {
                        HStack {
                            Label("Last Synced", systemImage: "clock")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
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

                // Credit Packs section (Coming Soon)
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)

                        Text("Credit Packs Coming Soon")
                            .font(.headline)

                        Text("Purchase additional credits to create more flyers. Available in a future update.")
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
        .environmentObject(CloudKitService())
}
