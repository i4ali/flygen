import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingSettings = false

    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        Group {
            if cloudKitService.isChecking {
                // Show loading while checking iCloud status
                ProgressView("Checking iCloud...")
            } else if !cloudKitService.isSignedIn {
                // Require iCloud sign-in
                iCloudRequiredView()
            } else if hasCompletedOnboarding {
                MainTabView(viewModel: viewModel, showingSettings: $showingSettings)
            } else {
                OnboardingContainerView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .onAppear {
            ensureUserProfileExists()
        }
        .onChange(of: cloudKitService.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                ensureUserProfileExists()
            }
        }
    }

    private func ensureUserProfileExists() {
        // Only create profile if signed in and none exists
        guard cloudKitService.isSignedIn else { return }

        if userProfiles.isEmpty {
            // Migrate credits from UserDefaults if they exist
            let existingCredits = UserDefaults.standard.integer(forKey: "userCredits")
            let profile = UserProfile()
            if existingCredits > 0 {
                profile.credits = existingCredits
            }
            modelContext.insert(profile)
            try? modelContext.save()
        }
    }
}

struct MainTabView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool

    var body: some View {
        TabView {
            HomeTab(viewModel: viewModel, showingSettings: $showingSettings)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            GalleryTab()
                .tabItem {
                    Label("My Flyers", systemImage: "square.grid.2x2.fill")
                }

            PremiumTab()
                .tabItem {
                    Label("Premium", systemImage: "crown.fill")
                }

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitService())
}
