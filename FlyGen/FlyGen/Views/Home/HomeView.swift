import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FlyGen")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()

            Spacer()

            // Main content
            VStack(spacing: 24) {
                // App icon/logo area
                Image(systemName: "doc.richtext")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)

                Text("Create stunning flyers\nwith AI")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                // Create button
                Button {
                    viewModel.showingCreationFlow = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Flyer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }

            Spacer()
            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.showingCreationFlow) {
            CreationFlowView(viewModel: viewModel)
        }
    }
}

#Preview {
    HomeView(
        viewModel: FlyerCreationViewModel(),
        showingSettings: .constant(false)
    )
}
