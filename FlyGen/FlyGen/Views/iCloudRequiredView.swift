import SwiftUI

struct iCloudRequiredView: View {
    @EnvironmentObject var cloudKitService: CloudKitService

    var body: some View {
        VStack(spacing: FGSpacing.xxl) {
            Spacer()

            // Icon with glow
            ZStack {
                Circle()
                    .fill(FGColors.textTertiary.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Image(systemName: "icloud.slash")
                    .font(.system(size: 70))
                    .foregroundColor(FGColors.textTertiary)
            }

            // Title
            Text("iCloud Required")
                .font(FGTypography.displaySmall)
                .foregroundColor(FGColors.textPrimary)

            // Description
            VStack(spacing: FGSpacing.md) {
                Text("FlyGen uses iCloud to sync your flyers and credits across all your devices.")
                    .font(FGTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(FGColors.textSecondary)

                Text(cloudKitService.statusMessage)
                    .font(FGTypography.label)
                    .multilineTextAlignment(.center)
                    .foregroundColor(FGColors.warning)
            }
            .padding(.horizontal, FGSpacing.xxl)

            // Why iCloud section
            VStack(alignment: .leading, spacing: FGSpacing.md) {
                iCloudFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Sync flyers across devices")
                iCloudFeatureRow(icon: "sparkles", text: "Keep your credits in sync")
                iCloudFeatureRow(icon: "lock.shield", text: "Secure cloud backup")
            }
            .padding(FGSpacing.lg)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.xl)

            Spacer()

            // Actions
            VStack(spacing: FGSpacing.md) {
                Button {
                    openSettings()
                } label: {
                    HStack(spacing: FGSpacing.sm) {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(FGTypography.buttonLarge)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                    .background(FGColors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
                }

                Button {
                    Task {
                        await cloudKitService.checkAccountStatus()
                    }
                } label: {
                    HStack(spacing: FGSpacing.sm) {
                        if cloudKitService.isChecking {
                            ProgressView()
                                .tint(FGColors.accentPrimary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check Again")
                    }
                    .font(FGTypography.button)
                    .foregroundColor(FGColors.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                            .stroke(FGColors.accentPrimary, lineWidth: 1.5)
                    )
                }
                .disabled(cloudKitService.isChecking)
            }
            .padding(.horizontal, FGSpacing.xl)
            .padding(.bottom, FGSpacing.xxl)
        }
        .background(FGColors.backgroundPrimary)
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
        HStack(spacing: FGSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(FGColors.accentPrimary)
                .frame(width: 24)
            Text(text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    iCloudRequiredView()
        .environmentObject(CloudKitService())
}
