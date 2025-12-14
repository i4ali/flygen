import SwiftUI
import SwiftData

struct ProfileTab: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var savedFlyers: [SavedFlyer]
    @Query private var userProfiles: [UserProfile]
    @State private var showingSettings = false
    @State private var showingCreditPurchase = false

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Profile section
                    profileHeader

                    // Stats section
                    statsSection

                    // iCloud section
                    iCloudSection

                    // Settings section
                    settingsSection

                    // About section
                    aboutSection

                    // Need More Credits section
                    creditsPromoSection
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingCreditPurchase) {
                CreditPurchaseSheet()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: FGSpacing.md) {
            ZStack {
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FGColors.accentPrimary)
            }

            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("iCloud User")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(FGColors.success)
                    Text("Synced with iCloud")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }
            }

            Spacer()
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

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Statistics")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                StatRow(icon: "doc.richtext", title: "Flyers Created", value: "\(savedFlyers.count)")
                Divider()
                    .background(FGColors.borderSubtle)
                StatRow(icon: "sparkles", title: "Credits Remaining", value: "\(credits)")
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

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("iCloud")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                HStack {
                    Label {
                        Text("Sync Status")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                    } icon: {
                        Image(systemName: "icloud")
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    Spacer()
                    Text(cloudKitService.isSignedIn ? "Connected" : "Not Connected")
                        .font(FGTypography.label)
                        .foregroundColor(cloudKitService.isSignedIn ? FGColors.success : FGColors.error)
                }
                .padding(FGSpacing.cardPadding)

                if let lastSync = userProfiles.first?.lastSyncedAt {
                    Divider()
                        .background(FGColors.borderSubtle)

                    HStack {
                        Label {
                            Text("Last Synced")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
                        Text(lastSync, style: .relative)
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(FGSpacing.cardPadding)
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

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Settings")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                Button {
                    showingSettings = true
                } label: {
                    HStack {
                        Label {
                            Text("API Settings")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "key")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(FGSpacing.cardPadding)
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

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("About")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
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

                Divider()
                    .background(FGColors.borderSubtle)

                Link(destination: URL(string: "https://openrouter.ai")!) {
                    HStack {
                        Label {
                            Text("Powered by OpenRouter")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "link")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(FGSpacing.cardPadding)
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

    // MARK: - Credits Promo Section

    private var creditsPromoSection: some View {
        Button {
            showingCreditPurchase = true
        } label: {
            HStack(spacing: FGSpacing.md) {
                ZStack {
                    Circle()
                        .fill(FGColors.accentSecondary.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(FGColors.accentSecondary)
                }

                VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                    Text("Need More Credits?")
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)
                    Text("Purchase credit packs to create more flyers")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(FGColors.textTertiary)
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.accentSecondary.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(FGColors.accentPrimary)
            }
            Spacer()
            Text(value)
                .font(FGTypography.h4)
                .foregroundColor(FGColors.accentPrimary)
        }
        .padding(FGSpacing.cardPadding)
    }
}

#Preview {
    ProfileTab()
        .environmentObject(CloudKitService())
        .environmentObject(StoreKitService())
        .environmentObject(NotificationService())
}
