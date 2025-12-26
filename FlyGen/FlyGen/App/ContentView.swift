import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var storeKitService: StoreKitService
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenNewUserOffer") private var hasSeenNewUserOffer: Bool = false
    @State private var showingSettings = false
    @State private var showingCreditPurchase = false
    @State private var showingNewUserOffer = false
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    private var credits: Int {
        userProfiles.first?.credits ?? 0
    }

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
                OnboardingContainerView { selectedCategories in
                    // Save selected categories to user profile
                    if let profile = userProfiles.first {
                        profile.setPreferredCategories(selectedCategories)
                        try? modelContext.save()

                        // Sync to CloudKit
                        Task {
                            await cloudKitService.savePreferredCategories(selectedCategories.map { $0.rawValue })
                        }
                    }
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
            if newPhase == .active {
                // Only check credits if user profile exists (credits are loaded)
                // Avoids false "out of credits" alerts during initial data load
                if let profile = userProfiles.first {
                    notificationService.onAppBecameActive(currentCredits: profile.credits)
                }
            }
        }
        .alert("Out of Credits", isPresented: $notificationService.shouldShowInAppAlert) {
            Button("Get Credits") {
                notificationService.dismissInAppAlert()
                showingCreditPurchase = true
            }
            Button("Later", role: .cancel) {
                notificationService.dismissInAppAlert()
            }
        } message: {
            Text("You've run out of credits. Purchase more to continue creating amazing flyers!")
        }
        .sheet(isPresented: $showingCreditPurchase, onDismiss: {
            // Reset promo mode when sheet is dismissed
            storeKitService.isPromoModeActive = false
        }) {
            CreditPurchaseSheet()
        }
        .sheet(isPresented: $showingNewUserOffer) {
            NewUserOfferSheet(
                onClaimOffer: {
                    hasSeenNewUserOffer = true
                    showingNewUserOffer = false
                    // Small delay before showing credit purchase in promo mode
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        storeKitService.isPromoModeActive = true
                        showingCreditPurchase = true
                    }
                },
                onDecline: {
                    hasSeenNewUserOffer = true
                    showingNewUserOffer = false
                }
            )
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            // Show new user offer after onboarding completes
            if completed && !hasSeenNewUserOffer {
                // Small delay for smoother UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !hasSeenNewUserOffer {
                        showingNewUserOffer = true
                    }
                }
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

            ExploreTab(viewModel: viewModel)
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
        .environmentObject(StoreKitService())
}
