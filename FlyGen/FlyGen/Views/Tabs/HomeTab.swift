import SwiftUI
import SwiftData

struct HomeTab: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool
    @EnvironmentObject var entitlementService: EntitlementService
    @Query private var userProfiles: [UserProfile]
    @State private var showingTemplates = false
    @State private var showingPaywall = false
    @State private var showingDiscardDraftAlert = false
    @State private var showingChat = false

    private var profile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 9) {
                        RoundedRectangle(cornerRadius: FGSpacing.logoMarkRadius, style: .continuous)
                            .fill(FGGradients.brand)
                            .frame(width: 26, height: 26)
                        Text("FlyGen")
                            .font(FGTypography.wordmark)
                            .tracking(FGTypography.Tracking.wordmark)
                            .foregroundColor(FGColors.textPrimary)
                    }

                    Spacer()

                    // Subscription status badge
                    if entitlementService.isSubscribed, let profile {
                        StatusPill(dot: true) {
                            Text("\(entitlementService.totalActionsRemaining(for: profile)) left")
                        }
                    } else if let profile, entitlementService.legacyFlyersRemaining(for: profile) > 0 {
                        // Legacy pre-subscription credits: surface the remaining count.
                        // Tappable -> paywall so the upgrade path survives the subscription migration.
                        Button {
                            showingPaywall = true
                        } label: {
                            StatusPill(dot: true) {
                                Text("\(entitlementService.legacyFlyersRemaining(for: profile)) left")
                            }
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            StatusPill(icon: "crown.fill") {
                                Text("Subscribe")
                            }
                        }
                    }

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 21))
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(.leading, FGSpacing.sm)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
                .padding(.top, FGSpacing.md)

                Spacer()

                // Main content
                VStack(spacing: FGSpacing.xl) {
                    // Aurora hero panel: dotted-grid glass card + indigo/cyan orb
                    AuroraHeroPanel()
                        .padding(.horizontal, FGSpacing.screenHorizontal)

                    VStack(spacing: FGSpacing.xs) {
                        Text("Create stunning flyers")
                            .font(FGTypography.heroTitle)
                            .tracking(FGTypography.Tracking.heroTitle)
                            .foregroundColor(FGColors.textPrimary)

                        Text("with AI")
                            .font(FGTypography.heroTitle)
                            .tracking(FGTypography.Tracking.heroTitle)
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    .multilineTextAlignment(.center)

                    // Primary create action: the conversational chat flow, now the only
                    // way to create a flyer. Not credit-gated (see note in FeatureFlags).
                    if FeatureFlags.chatEnabled {
                        Button { showingChat = true } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "bubble.left.and.text.bubble.right")
                                Text("Chat to Create")
                            }
                            .font(FGTypography.buttonLabel)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius, style: .continuous)
                                    .fill(FGGradients.accent)
                            )
                            .auroraCTAGlow()
                        }
                        .buttonStyle(FGPrimaryButtonStyle())
                        .padding(.horizontal, FGSpacing.screenHorizontalButtons)
                        .padding(.top, FGSpacing.md)
                    }

                    // Classic step-by-step creation (Create New Flyer + Use Template),
                    // retired in favor of chat but retained behind a flag.
                    if FeatureFlags.classicCreationEnabled {
                        Button {
                            if let profile, entitlementService.access(for: profile) == .blocked {
                                showingPaywall = true
                            } else {
                                viewModel.showingCreationFlow = true
                            }
                        } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Flyer")
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
                        .padding(.horizontal, FGSpacing.xl)

                        Button {
                            if let profile, entitlementService.access(for: profile) == .blocked {
                                showingPaywall = true
                            } else {
                                showingTemplates = true
                            }
                        } label: {
                            HStack(spacing: FGSpacing.sm) {
                                Image(systemName: "doc.on.doc")
                                Text("Use Template")
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
                        .padding(.horizontal, FGSpacing.xl)
                    }

                    // Resume Draft banner - drafts belong to the classic flow, so only
                    // surface this when that flow is enabled.
                    if FeatureFlags.classicCreationEnabled && viewModel.hasPendingDraft {
                        DraftBanner(
                            categoryName: viewModel.draftCategoryName ?? "Flyer",
                            onResume: {
                                viewModel.loadDraft()
                            },
                            onDiscard: {
                                showingDiscardDraftAlert = true
                            }
                        )
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                        .padding(.top, FGSpacing.sm)
                    }

                }

                Spacer()
                Spacer()
            }
            .background(FGColors.backgroundPrimary)
            .fullScreenCover(isPresented: $viewModel.showingCreationFlow) {
                CreationFlowView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingTemplates) {
                TemplatePickerView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingChat) {
                FlyerChatView()
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionPaywallView()
            }
            .alert("Discard Draft?", isPresented: $showingDiscardDraftAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.discardDraft()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your unfinished flyer will be permanently deleted.")
            }
        }
    }
}

// MARK: - Status Pill

/// Aurora status pill: surface + hairline capsule with either a cyan live-dot or a leading icon.
private struct StatusPill<Label: View>: View {
    var dot: Bool = false
    var icon: String? = nil
    @ViewBuilder var label: () -> Label

    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            if dot {
                Circle()
                    .fill(FGColors.accentSecondary)
                    .frame(width: 7, height: 7)
                    .shadow(color: FGColors.accentSecondary, radius: 4)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(FGColors.accentSecondary)
            }
            label()
                .font(FGTypography.labelLarge)
                .foregroundColor(FGColors.textPrimary)
        }
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(FGColors.surfaceDefault)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(FGColors.borderCard, lineWidth: 1))
    }
}

// MARK: - Draft Banner

/// Banner showing there's an unfinished draft that can be resumed
private struct DraftBanner: View {
    let categoryName: String
    let onResume: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: "doc.badge.clock")
                .font(.title3)
                .foregroundColor(FGColors.accentPrimary)

            VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                Text("Unfinished \(categoryName)")
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)

                Text("Continue where you left off")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            HStack(spacing: FGSpacing.xs) {
                Button {
                    onDiscard()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FGColors.textTertiary)
                        .padding(FGSpacing.xs)
                        .background(FGColors.backgroundTertiary)
                        .clipShape(Circle())
                }

                Button {
                    onResume()
                } label: {
                    Text("Resume")
                        .font(FGTypography.labelSmall)
                        .foregroundColor(FGColors.textOnAccent)
                        .padding(.horizontal, FGSpacing.md)
                        .padding(.vertical, FGSpacing.sm)
                        .background(FGColors.accentPrimary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(FGSpacing.md)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Aurora Hero Panel

/// The Home hero: a dotted/line-grid glass panel with a glowing indigo→cyan conic orb and a
/// sparkle glyph. Replaces the old animated flyer-card stack.
private struct AuroraHeroPanel: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FGSpacing.heroPanelRadius, style: .continuous)
                .fill(FGGradients.heroPanelRadial)

            // Faint indigo grid.
            GridLines(spacing: 26)
                .stroke(FGColors.accentPrimary.opacity(0.09), lineWidth: 1)

            // Orb: conic ring (dark disc masks the center) + sparkle.
            ZStack {
                Circle()
                    .fill(FGGradients.orbConic)
                    .frame(width: 92, height: 92)
                    .blur(radius: 1)
                    .opacity(0.9)
                Circle()
                    .fill(Color(hex: "0D0F18"))
                    .frame(width: 60, height: 60)
                Image(systemName: "sparkle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(FGColors.textPrimary)
            }
        }
        .frame(height: 158)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.heroPanelRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.heroPanelRadius, style: .continuous)
                .strokeBorder(FGColors.borderHairline, lineWidth: 1)
        )
    }
}

/// A light line grid used behind the hero orb.
private struct GridLines: Shape {
    var spacing: CGFloat = 26
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x: CGFloat = 0
        while x <= rect.width {
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y <= rect.height {
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }
        return p
    }
}

/// Warning banner component
private struct WarningBanner: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)
        }
        .padding(FGSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.chipRadius)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HomeTab(
        viewModel: FlyerCreationViewModel(),
        showingSettings: .constant(false)
    )
}
