import SwiftUI
import SwiftData

struct HomeTab: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool
    @AppStorage("openrouter_api_key") private var apiKey: String = ""
    @Query private var userProfiles: [UserProfile]
    @State private var showingTemplates = false

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("FlyGen")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    // Credits display
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("\(credits)")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(16)

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .padding(.leading, 8)
                }
                .padding()

                Spacer()

                // Main content
                VStack(spacing: 24) {
                    // App icon/logo area
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 8)

                    Text("Create stunning flyers\nwith AI")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    // Create button
                    Button {
                        if credits > 0 {
                            viewModel.showingCreationFlow = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Flyer")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(credits > 0 ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(credits <= 0)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                    // Use Template button
                    Button {
                        if credits > 0 {
                            showingTemplates = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Use Template")
                        }
                        .font(.headline)
                        .foregroundColor(credits > 0 ? Color.accentColor : Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(credits > 0 ? Color.accentColor : Color.gray, lineWidth: 2)
                        )
                    }
                    .disabled(credits <= 0)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    // Credits warning
                    if credits <= 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No credits remaining. Upgrade to Premium for unlimited flyers!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    // API key warning
                    else if apiKey.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Add your OpenRouter API key in Settings to generate flyers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }

                Spacer()
                Spacer()
            }
            .fullScreenCover(isPresented: $viewModel.showingCreationFlow) {
                CreationFlowView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatePickerView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    HomeTab(
        viewModel: FlyerCreationViewModel(),
        showingSettings: .constant(false)
    )
}
