import SwiftUI

/// Screen 4: Language preferences selection
struct LanguagePreferencesScreen: View {
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
                Text("What languages?")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Select the languages you'll create flyers in")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
                .frame(height: FGSpacing.xl)

            // Language grid (2 columns, 5 items)
            LazyVGrid(columns: columns, spacing: FGSpacing.md) {
                ForEach(FlyerLanguage.allCases, id: \.self) { language in
                    LanguageChip(
                        language: language,
                        isSelected: viewModel.selectedLanguages.contains(language)
                    ) {
                        withAnimation(FGAnimations.spring) {
                            viewModel.toggleLanguage(language)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Spacer()

            // Selection count hint
            if !viewModel.selectedLanguages.isEmpty {
                Text("\(viewModel.selectedLanguages.count) selected")
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

// MARK: - Language Chip

private struct LanguageChip: View {
    let language: FlyerLanguage
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch language {
        case .english: return "globe.americas"
        case .spanish: return "globe.americas"
        case .urdu: return "globe.asia.australia"
        case .arabic: return "globe.europe.africa"
        case .chinese: return "globe.asia.australia"
        }
    }

    private var nativeText: String {
        switch language {
        case .english: return "English"
        case .spanish: return "Español"
        case .urdu: return "اردو"
        case .arabic: return "العربية"
        case .chinese: return "中文"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.accentSecondary)

                Text(nativeText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textPrimary)

                if language != .english {
                    Text(language.displayName.components(separatedBy: " ").first ?? "")
                        .font(FGTypography.caption)
                        .foregroundColor(isSelected ? FGColors.textOnAccent.opacity(0.8) : FGColors.textSecondary)
                }
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

#Preview("Language Preferences Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        LanguagePreferencesScreen(viewModel: OnboardingViewModel())
    }
}
