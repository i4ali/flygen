import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlyerCreationViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingSettings = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView(viewModel: viewModel, showingSettings: $showingSettings)
        } else {
            OnboardingContainerView {
                hasCompletedOnboarding = true
            }
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
}
