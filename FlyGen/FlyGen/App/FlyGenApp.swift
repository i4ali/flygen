import SwiftUI
import SwiftData

@main
struct FlyGenApp: App {
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var storeKitService = StoreKitService()
    @StateObject private var reviewService = ReviewService()

    private static let iCloudContainerIdentifier = "iCloud.com.flygen.app"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedFlyer.self, UserProfile.self])
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
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0) // #0D0D0D
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.45, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 0.45, alpha: 1.0)]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 1.0) // #7C3AED
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 1.0)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 1.0)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(storeKitService)
                .environmentObject(reviewService)
        }
        .modelContainer(sharedModelContainer)
    }
}
