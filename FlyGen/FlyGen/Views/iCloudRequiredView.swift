import SwiftUI

struct iCloudRequiredView: View {
    @EnvironmentObject var cloudKitService: CloudKitService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "icloud.slash")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            // Title
            Text("iCloud Required")
                .font(.title)
                .fontWeight(.bold)

            // Description
            VStack(spacing: 12) {
                Text("FlyGen uses iCloud to sync your flyers and credits across all your devices.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Text(cloudKitService.statusMessage)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.orange)
                    .font(.callout)
            }
            .padding(.horizontal, 32)

            // Why iCloud section
            VStack(alignment: .leading, spacing: 16) {
                iCloudFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Sync flyers across devices")
                iCloudFeatureRow(icon: "sparkles", text: "Keep your credits in sync")
                iCloudFeatureRow(icon: "lock.shield", text: "Secure cloud backup")
            }
            .padding(.horizontal, 40)

            Spacer()

            // Actions
            VStack(spacing: 16) {
                Button {
                    openSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }

                Button {
                    Task {
                        await cloudKitService.checkAccountStatus()
                    }
                } label: {
                    HStack {
                        if cloudKitService.isChecking {
                            ProgressView()
                                .tint(.accentColor)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check Again")
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(cloudKitService.isChecking)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

private struct iCloudFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    iCloudRequiredView()
        .environmentObject(CloudKitService())
}
