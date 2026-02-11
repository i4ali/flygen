import SwiftUI
import PhotosUI

/// Screen 7: Optional quick brand setup
struct QuickBrandSetupScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: FGSpacing.xl)

            // Header
            VStack(spacing: FGSpacing.sm) {
                Text("Set up your brand")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Optional - you can do this later")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
                .frame(height: FGSpacing.xxl)

            // Form fields
            VStack(spacing: FGSpacing.lg) {
                // Business name
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    Text("Business Name")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    TextField("Your business or brand name", text: $viewModel.quickBusinessName)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .padding(FGSpacing.md)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

                // Website / Social
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    Text("Website or Social Handle")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    TextField("www.example.com or @handle", text: $viewModel.quickWebsite)
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textPrimary)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .padding(FGSpacing.md)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

                // Logo upload
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    Text("Logo")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: FGSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(FGColors.surfaceHover)
                                    .frame(width: 60, height: 60)

                                if let logoData = viewModel.quickLogoData,
                                   let uiImage = UIImage(data: logoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(FGColors.accentPrimary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.quickLogoData != nil ? "Logo uploaded" : "Add your logo")
                                    .font(FGTypography.body)
                                    .foregroundColor(FGColors.textPrimary)

                                Text(viewModel.quickLogoData != nil ? "Tap to change" : "PNG or JPG recommended")
                                    .font(FGTypography.caption)
                                    .foregroundColor(FGColors.textSecondary)
                            }

                            Spacer()

                            if viewModel.quickLogoData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(FGColors.accentPrimary)
                            }
                        }
                        .padding(FGSpacing.md)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.quickLogoData != nil ? FGColors.accentPrimary.opacity(0.5) : FGColors.borderSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Spacer()

            // Progress hint
            if hasAnyInput {
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(FGColors.accentPrimary)

                    Text("Brand info saved")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(.bottom, FGSpacing.md)
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.quickLogoData = data
                }
            }
        }
    }

    private var hasAnyInput: Bool {
        !viewModel.quickBusinessName.isEmpty ||
        !viewModel.quickWebsite.isEmpty ||
        viewModel.quickLogoData != nil
    }
}

#Preview("Quick Brand Setup Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        QuickBrandSetupScreen(viewModel: OnboardingViewModel())
    }
}
