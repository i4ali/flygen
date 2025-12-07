import SwiftUI

@main
struct FlyGenApp: App {

    init() {
        // Set default API key if not already configured
        if UserDefaults.standard.string(forKey: "openrouter_api_key") == nil {
            UserDefaults.standard.set("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", forKey: "openrouter_api_key")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
