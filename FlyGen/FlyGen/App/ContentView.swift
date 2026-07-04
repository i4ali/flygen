import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var storeKitService: StoreKitService
    @EnvironmentObject var entitlementService: EntitlementService
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenBrandKitIntro") private var hasSeenBrandKitIntro: Bool = false
    @AppStorage("hasSeenPostOnboardingPaywall") private var hasSeenPostOnboardingPaywall: Bool = false
    @State private var showingSettings = false
    @State private var showingBrandKitIntro = false
    @State private var showPostOnboardingPaywall = false
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var brandKits: [BrandKit]

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
                ChatOnboardingView { categories, languages in
                    // Persist the two preferences the chat onboarding collects. Style/mood/color
                    // and role are no longer gathered up front - the chat decides those per flyer.
                    if let profile = userProfiles.first {
                        profile.setPreferredCategories(categories)
                        profile.setPreferredLanguages(languages)
                        try? modelContext.save()

                        // Sync categories to CloudKit (drives Explore "For You").
                        Task {
                            await cloudKitService.savePreferredCategories(categories.map { $0.rawValue })
                        }
                    }
                    hasCompletedOnboarding = true
                    // Show the paywall once, right after onboarding. This closure runs a single
                    // time, so only brand-new users see it (never existing users on relaunch).
                    // The short delay lets Home settle so the sheet slides up cleanly.
                    if !hasSeenPostOnboardingPaywall && !entitlementService.isSubscribed {
                        hasSeenPostOnboardingPaywall = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showPostOnboardingPaywall = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await ensureUserProfileExists()
            await syncCreditsFromCloud()
            await syncQuotaFromCloud()
            if let profile = userProfiles.first {
                await entitlementService.refresh(profile: profile, context: modelContext, cloudKit: cloudKitService)
            }
            // Schedule seasonal engagement notifications
            await notificationService.scheduleSeasonalNotifications()
            // Inject brand kit into view model
            viewModel.brandKit = brandKits.first
            // Show brand kit intro to existing users (one-time)
            if hasCompletedOnboarding && !hasSeenBrandKitIntro {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingBrandKitIntro = true
                }
            }
        }
        .onChange(of: cloudKitService.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                Task {
                    await ensureUserProfileExists()
                    await syncCreditsFromCloud()
                    await syncQuotaFromCloud()
                    if let profile = userProfiles.first {
                        await entitlementService.refresh(profile: profile, context: modelContext, cloudKit: cloudKitService)
                    }
                }
            }
        }
        .onChange(of: brandKits.first?.updatedAt) { _, _ in
            viewModel.brandKit = brandKits.first
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await syncCreditsFromCloud()
                    await syncQuotaFromCloud()
                    if let profile = userProfiles.first {
                        await entitlementService.refresh(profile: profile, context: modelContext, cloudKit: cloudKitService)
                    }
                }
                // Check for pending draft on app resume
                viewModel.checkForPendingDraft()
            case .background:
                // Save draft when app goes to background
                viewModel.saveDraft()
            default:
                break
            }
        }
        .sheet(isPresented: $showingBrandKitIntro) {
            BrandKitIntroSheet {
                hasSeenBrandKitIntro = true
                showingBrandKitIntro = false
            }
        }
        .sheet(isPresented: $showPostOnboardingPaywall) {
            SubscriptionPaywallView()
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

    private func syncQuotaFromCloud() async {
        guard cloudKitService.isSignedIn,
              let profile = userProfiles.first else { return }

        let synced = await cloudKitService.syncQuota(
            localUsed: profile.quotaUsedThisPeriod,
            localPeriodStart: profile.quotaPeriodStart
        )

        if synced.used != profile.quotaUsedThisPeriod || synced.periodStart != profile.quotaPeriodStart {
            profile.quotaUsedThisPeriod = synced.used
            profile.quotaPeriodStart = synced.periodStart
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

            PromptsTab()
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble.fill")
                }
                .tag(3)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitService())
        .environmentObject(NotificationService())
        .environmentObject(StoreKitService())
}
