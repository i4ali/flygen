import SwiftUI

/// Screen 3: Category preferences selection
struct CategoryPreferencesScreen: View {
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
                Text("What do you create?")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Select the types you create most often")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
                .frame(height: FGSpacing.xl)

            // Preference grid (2 columns, 6 items)
            LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                ForEach(UserPreferenceType.allCases) { preference in
                    PreferenceChip(
                        preference: preference,
                        isSelected: viewModel.selectedPreferences.contains(preference)
                    ) {
                        withAnimation(FGAnimations.spring) {
                            viewModel.togglePreference(preference)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Spacer()

            // Selection count hint
            if !viewModel.selectedPreferences.isEmpty {
                Text("\(viewModel.selectedPreferences.count) selected")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.accentSecondary)
                    .padding(.bottom, FGSpacing.md)
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Preference Chip

private struct PreferenceChip: View {
    let preference: UserPreferenceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.sm) {
                Image(systemName: preference.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.accentSecondary)

                Text(preference.displayName)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
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
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Category Preferences Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        CategoryPreferencesScreen(viewModel: OnboardingViewModel())
    }
}
