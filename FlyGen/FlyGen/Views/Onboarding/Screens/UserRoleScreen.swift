import SwiftUI

/// Screen 1: User role selection - "Who are you?"
struct UserRoleScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false

    private let columns = [
        GridItem(.flexible(), spacing: FGSpacing.md),
        GridItem(.flexible(), spacing: FGSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: FGSpacing.xl)

            // Header
            VStack(spacing: FGSpacing.sm) {
                Text("Who are you?")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Help us personalize your experience")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
                .frame(height: FGSpacing.xl)

            // Role grid (2 columns, 6 items)
            LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                ForEach(UserRole.allCases) { role in
                    RoleCard(
                        role: role,
                        isSelected: viewModel.selectedUserRole == role
                    ) {
                        withAnimation(FGAnimations.spring) {
                            if viewModel.selectedUserRole == role {
                                viewModel.selectedUserRole = nil
                            } else {
                                viewModel.selectedUserRole = role
                            }
                        }
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Spacer()

            // Selection hint
            if let role = viewModel.selectedUserRole {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: role.icon)
                        .font(.system(size: 14))
                    Text(role.displayName)
                        .font(FGTypography.caption)
                }
                .foregroundColor(FGColors.accentPrimary)
                .padding(.bottom, FGSpacing.md)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Role Card

private struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.sm) {
                // Icon
                Image(systemName: role.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.accentPrimary)

                // Title
                Text(role.displayName)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                // Subtitle
                Text(role.subtitle)
                    .font(FGTypography.caption)
                    .foregroundColor(isSelected ? FGColors.textOnAccent.opacity(0.8) : FGColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .padding(.horizontal, FGSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .fill(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(
                        isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? FGColors.accentPrimary.opacity(0.4) : .clear,
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("User Role Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        UserRoleScreen(viewModel: OnboardingViewModel())
    }
}
