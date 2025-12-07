import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("openrouter_api_key") private var apiKey: String = ""
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            HomeView(viewModel: viewModel, showingSettings: $showingSettings)
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
    }
}

#Preview {
    ContentView()
}
