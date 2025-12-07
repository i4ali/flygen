import SwiftUI
import SwiftData

@main
struct FlyGenApp: App {
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var storeKitService = StoreKitService()

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
        // Set default API key if not already configured
        if UserDefaults.standard.string(forKey: "openrouter_api_key") == nil {
            UserDefaults.standard.set("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", forKey: "openrouter_api_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitService)
                .environmentObject(storeKitService)
        }
        .modelContainer(sharedModelContainer)
    }
}
