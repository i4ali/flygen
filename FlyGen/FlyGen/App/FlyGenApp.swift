import SwiftUI
import SwiftData

/// App-wide feature flags. Central place to toggle features that are built but
/// intentionally not exposed to users yet, so they can be enabled in one spot.
enum FeatureFlags {
    /// Conversational "Chat" flyer flow - the primary and only way to create a flyer.
    /// The Chat code is retained and compiled; setting this to `false` would leave the
    /// app with no creation entry point unless `classicCreationEnabled` is also on.
    static let chatEnabled = true

    /// Classic step-by-step creation wizard and its entry points (Create New Flyer,
    /// Use Template, Resume Draft, Use as Template). Retired in favor of chat; the code
    /// is retained and still compiled - set this to `true` to bring the entry points back.
    static let classicCreationEnabled = false

    /// Brand Kit - the reusable logo / contact-info / QR defaults saved in Profile and
    /// auto-applied to new flyers, plus its two nudges (the one-time existing-user intro
    /// sheet and the in-creation "Apply Brand Kit?" prompt). Hidden while the feature is
    /// on hold; the setup screens, `BrandKit` model, and CloudKit-synced data are all
    /// retained - set this to `true` to bring the entry point and prompts back as they were.
    static let brandKitEnabled = false
}

@main
struct FlyGenApp: App {
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var storeKitService = StoreKitService()
    @StateObject private var entitlementService = EntitlementService()
    @StateObject private var reviewService = ReviewService()
    @StateObject private var notificationService = NotificationService()

    private static let iCloudContainerIdentifier = "iCloud.com.flygen.app"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedFlyer.self, UserProfile.self, BrandKit.self, SavedPrompt.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(FlyGenApp.iCloudContainerIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Configure global dark mode appearance
        configureAppearance()
    }

    private func configureAppearance() {
        // Aurora palette (UIKit): base #0A0B0F, indigo #7C8CF8, tertiary #565C6B, near-white #EDEFF4
        let base = UIColor(red: 0.039, green: 0.043, blue: 0.059, alpha: 1.0)   // #0A0B0F
        let indigo = UIColor(red: 0.486, green: 0.549, blue: 0.973, alpha: 1.0) // #7C8CF8
        let tertiary = UIColor(red: 0.337, green: 0.361, blue: 0.420, alpha: 1.0) // #565C6B
        let nearWhite = UIColor(red: 0.929, green: 0.937, blue: 0.957, alpha: 1.0) // #EDEFF4

        // Tab bar appearance (the app renders a custom AuroraTabBar; this keeps any native
        // bar on-brand as a fallback).
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = base
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = tertiary
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: tertiary]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = indigo
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: indigo]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation bar appearance (Space Grotesk titles)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = base
        var titleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: nearWhite]
        if let titleFont = UIFont(name: "SpaceGrotesk-Bold", size: 17) { titleAttrs[.font] = titleFont }
        navBarAppearance.titleTextAttributes = titleAttrs
        var largeAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: nearWhite]
        if let largeFont = UIFont(name: "SpaceGrotesk-Bold", size: 32) { largeAttrs[.font] = largeFont }
        navBarAppearance.largeTitleTextAttributes = largeAttrs
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = indigo
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(storeKitService)
                .environmentObject(entitlementService)
                .environmentObject(reviewService)
                .environmentObject(notificationService)
        }
        .modelContainer(sharedModelContainer)
    }
}
