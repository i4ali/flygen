import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Notifications Section
                    notificationsSection

                    // Generation Settings Section
                    generationSettingsSection

                    // About Section
                    aboutSection
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FGColors.accentPrimary)
                }
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Notifications")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                // Credit notifications toggle
                HStack {
                    VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                        Text("Credit Alerts")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                        Text("Get notified when credits are low")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationService.creditNotificationsEnabled },
                        set: { newValue in
                            Task {
                                await notificationService.setCreditNotificationsEnabled(newValue)
                            }
                        }
                    ))
                    .tint(FGColors.accentPrimary)
                    .labelsHidden()
                }
                .padding(FGSpacing.cardPadding)

                Divider()
                    .background(FGColors.borderSubtle)

                // Re-engagement notifications toggle
                HStack {
                    VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                        Text("Reminders")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                        Text("Get reminded to create new flyers")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationService.engagementNotificationsEnabled },
                        set: { newValue in
                            Task {
                                await notificationService.setEngagementNotificationsEnabled(newValue)
                            }
                        }
                    ))
                    .tint(FGColors.accentPrimary)
                    .labelsHidden()
                }
                .padding(FGSpacing.cardPadding)

                // Show permission status if denied
                if notificationService.authorizationStatus == .denied {
                    Divider()
                        .background(FGColors.borderSubtle)

                    Button {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(FGColors.warning)
                            Text("Notifications disabled in Settings")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.warning)
                            Spacer()
                            Text("Open Settings")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        .padding(FGSpacing.cardPadding)
                    }
                }
            }
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - Generation Settings Section

    private var generationSettingsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Generation Settings")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                HStack {
                    Text("Model")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                    Spacer()
                    Text("Gemini 3 Pro")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.cardPadding)

                Divider()
                    .background(FGColors.borderSubtle)

                HStack {
                    Text("Provider")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                    Spacer()
                    Text("OpenRouter")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.cardPadding)
            }
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("About")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            HStack {
                Text("Version")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationService())
}
