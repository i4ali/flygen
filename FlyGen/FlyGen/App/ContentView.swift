import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingSettings = false
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        Group {
            if cloudKitService.isChecking {
                // Show loading while checking iCloud status
                VStack {
                    ProgressView()
                        .tint(FGColors.accentPrimary)
                    Text("Checking iCloud...")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                        .padding(.top, FGSpacing.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FGColors.backgroundPrimary)
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
        .preferredColorScheme(.dark)
        .task {
            await ensureUserProfileExists()
            await syncCreditsFromCloud()
        }
        .onChange(of: cloudKitService.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                Task {
                    await ensureUserProfileExists()
                    await syncCreditsFromCloud()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                notificationService.appDidBecomeActive()
            case .background:
                notificationService.appDidEnterBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    private func ensureUserProfileExists() async {
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
        } else if let profile = userProfiles.first {
            // Migration: Reset users with old credit amounts to new default of 10
            // This handles users from the old system (1 credit per generation)
            // who have less than 10 credits - give them the new default
            if profile.credits < 10 {
                profile.credits = 10
                profile.lastSyncedAt = Date()
                try? modelContext.save()

                // Sync the reset credits to CloudKit
                Task {
                    await cloudKitService.saveCredits(profile.credits)
                }
            }
        }
    }

    private func syncCreditsFromCloud() async {
        guard cloudKitService.isSignedIn,
              let profile = userProfiles.first else { return }

        let syncedCredits = await cloudKitService.syncCredits(localCredits: profile.credits)

        if syncedCredits != profile.credits {
            profile.credits = syncedCredits
            profile.lastSyncedAt = Date()
            try? modelContext.save()
        }
    }
}

struct MainTabView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab(viewModel: viewModel, showingSettings: $showingSettings)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            GalleryTab(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("My Flyers", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            ExploreTab()
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }
                .tag(2)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitService())
        .environmentObject(NotificationService())
}
