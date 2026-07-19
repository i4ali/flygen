import SwiftUI
import SwiftData
import MessageUI
import StoreKit

struct ProfileTab: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var entitlementService: EntitlementService
    @Environment(\.modelContext) private var modelContext
    @Query private var savedFlyers: [SavedFlyer]
    @Query private var userProfiles: [UserProfile]
    @Query private var brandKits: [BrandKit]
    @State private var showingSettings = false
    @State private var showingSubscriptionPaywall = false
    @State private var showingManageSubscriptions = false
    @State private var showingBrandKit = false
    @State private var showingMailComposer = false
    @State private var showingMailAlert = false

    /// The current default flyer language (falls back to English until a profile exists). Seeded by
    /// the onboarding language pick; used to pre-select the review-card language row on each flyer.
    private var defaultLanguage: FlyerLanguage {
        userProfiles.first?.defaultFlyerLanguageEnum ?? .english
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Profile section
                    profileHeader

                    // Stats section
                    statsSection

                    // Subscription section
                    subscriptionSection

                    // Brand Kit section (hidden while the feature is on hold - see FeatureFlags.brandKitEnabled)
                    if FeatureFlags.brandKitEnabled {
                        brandKitSection
                    }

                    // Preferences section (default flyer language)
                    preferencesSection

                    // iCloud section
                    iCloudSection

                    // Settings section
                    settingsSection

                    // About section
                    aboutSection
                }
                .padding(.vertical, FGSpacing.lg)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBrandKit) {
                BrandKitView()
            }
            .sheet(isPresented: $showingSubscriptionPaywall) {
                SubscriptionPaywallView()
                    .environmentObject(entitlementService)
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    recipient: "ali.muhammadimran@gmail.com",
                    subject: "FlyGen Feedback",
                    body: ""
                )
            }
            .alert("Mail Not Available", isPresented: $showingMailAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please configure a mail account in Settings to send feedback.")
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

    // MARK: - Brand Kit Section

    private var brandKitSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Brand Kit")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            Button {
                showingBrandKit = true
            } label: {
                HStack(spacing: FGSpacing.md) {
                    // Logo thumbnail or placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                            .fill(FGColors.accentPrimary.opacity(0.2))
                            .frame(width: 50, height: 50)

                        if let logoData = brandKits.first?.logoImageData,
                           let uiImage = UIImage(data: logoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        } else {
                            Image(systemName: "briefcase.fill")
                                .font(.title2)
                                .foregroundColor(FGColors.accentPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                        Text(brandKits.first != nil ? "Edit Brand Kit" : "Set Up Brand Kit")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                        Text(brandKits.first?.contentSummary ?? "Save logo, contact info & QR defaults")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FGColors.textTertiary)
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

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Preferences")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                HStack {
                    Label {
                        Text("Default Flyer Language")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    Spacer()
                    Menu {
                        ForEach(FlyerLanguage.allCases, id: \.self) { language in
                            Button {
                                if let profile = userProfiles.first {
                                    profile.setDefaultFlyerLanguage(language)
                                    try? modelContext.save()
                                }
                            } label: {
                                HStack {
                                    Text(language.displayName)
                                    if defaultLanguage == language { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: FGSpacing.xxs) {
                            Text(defaultLanguage.displayName)
                                .font(FGTypography.label)
                                .foregroundColor(FGColors.textSecondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundColor(FGColors.textTertiary)
                        }
                    }
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

                Divider()
                    .background(FGColors.borderSubtle)

                Button {
                    if MailComposerView.canSendMail {
                        showingMailComposer = true
                    } else {
                        showingMailAlert = true
                    }
                } label: {
                    HStack {
                        Label {
                            Text("Send Feedback")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "envelope")
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

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            Text("Subscription")
                .font(FGTypography.h4)
                .foregroundColor(FGColors.textSecondary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: 0) {
                // Status row
                HStack {
                    Label {
                        Text("Status")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)
                    } icon: {
                        Image(systemName: entitlementService.isSubscribed ? "crown.fill" : "person.circle")
                            .foregroundColor(entitlementService.isSubscribed ? FGColors.accentPrimary : FGColors.textSecondary)
                    }
                    Spacer()
                    Text(entitlementService.isSubscribed ? "Premium" : "Free")
                        .font(FGTypography.label)
                        .foregroundColor(entitlementService.isSubscribed ? FGColors.accentPrimary : FGColors.textSecondary)
                }
                .padding(FGSpacing.cardPadding)

                // Renewal date (subscribed only)
                if entitlementService.isSubscribed, let renewalDate = entitlementService.renewalDate {
                    Divider()
                        .background(FGColors.borderSubtle)

                    HStack {
                        Label {
                            Text("Renews")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
                        Text(renewalDate, style: .date)
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(FGSpacing.cardPadding)
                }

                // Go Premium button (not subscribed only)
                if !entitlementService.isSubscribed {
                    Divider()
                        .background(FGColors.borderSubtle)

                    Button {
                        showingSubscriptionPaywall = true
                    } label: {
                        HStack {
                            Label {
                                Text("Go Premium")
                                    .font(FGTypography.body)
                                    .foregroundColor(FGColors.accentPrimary)
                            } icon: {
                                Image(systemName: "crown")
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

                Divider()
                    .background(FGColors.borderSubtle)

                // Manage Subscription
                Button {
                    showingManageSubscriptions = true
                } label: {
                    HStack {
                        Label {
                            Text("Manage Subscription")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "gear")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(FGSpacing.cardPadding)
                }

                Divider()
                    .background(FGColors.borderSubtle)

                // Restore Purchases
                Button {
                    Task { await entitlementService.restore() }
                } label: {
                    HStack {
                        Label {
                            Text("Restore Purchases")
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textPrimary)
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                        Spacer()
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
        .environmentObject(EntitlementService())
}
