import SwiftUI
import SwiftData

struct ResultView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var showingRefinementSheet = false
    @State private var showingReformatSheet = false
    @State private var showingSaveSuccess = false
    @State private var saveError: String?
    @State private var hasSavedToGallery = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image display
                if case .generating = viewModel.generationState {
                    GenerationView(viewModel: viewModel)
                } else if case .success(let image) = viewModel.generationState {
                    ScrollView {
                        VStack(spacing: FGSpacing.lg) {
                            // Generated image with glow
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                                .shadow(color: FGColors.accentPrimary.opacity(0.3), radius: 16)
                                .padding(FGSpacing.screenHorizontal)

                            // Action buttons
                            HStack(spacing: FGSpacing.md) {
                                ActionButton(
                                    title: "Refine",
                                    icon: "arrow.triangle.2.circlepath",
                                    color: FGColors.warning
                                ) {
                                    showingRefinementSheet = true
                                }

                                ActionButton(
                                    title: "Resize",
                                    icon: "aspectratio",
                                    color: FGColors.accentPrimary
                                ) {
                                    showingReformatSheet = true
                                }

                                ActionButton(
                                    title: "Save",
                                    icon: "square.and.arrow.down",
                                    color: FGColors.success
                                ) {
                                    saveToPhotos()
                                }
                            }
                            .padding(.horizontal, FGSpacing.screenHorizontal)

                            // Save feedback
                            if showingSaveSuccess {
                                HStack(spacing: FGSpacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Saved to Photos!")
                                }
                                .font(FGTypography.label)
                                .foregroundColor(FGColors.success)
                                .padding(FGSpacing.sm)
                                .background(FGColors.success.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                            }

                            if let error = saveError {
                                Text(error)
                                    .font(FGTypography.caption)
                                    .foregroundColor(FGColors.error)
                                    .padding(FGSpacing.sm)
                            }
                        }
                        .padding(.vertical, FGSpacing.lg)
                    }

                    // Done button
                    Button {
                        saveToGalleryAndDismiss()
                    } label: {
                        Text("Done")
                            .font(FGTypography.buttonLarge)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(FGSpacing.screenHorizontal)
                    .padding(.bottom, FGSpacing.md)

                } else if case .error(let message) = viewModel.generationState {
                    VStack(spacing: FGSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(FGColors.warning.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(FGColors.warning)
                        }

                        VStack(spacing: FGSpacing.sm) {
                            Text("Generation Failed")
                                .font(FGTypography.h2)
                                .foregroundColor(FGColors.textPrimary)

                            Text(message)
                                .font(FGTypography.body)
                                .foregroundColor(FGColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FGSpacing.xl)
                        }

                        Button {
                            Task {
                                await viewModel.generateFlyer()
                            }
                        } label: {
                            Text("Try Again")
                                .font(FGTypography.button)
                                .foregroundColor(FGColors.textOnAccent)
                                .padding(.horizontal, FGSpacing.xxl)
                                .padding(.vertical, FGSpacing.md)
                                .background(FGColors.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        }
                        .padding(.top, FGSpacing.md)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Your Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showingResult = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(FGColors.textSecondary)
                    }
                }

                if case .success = viewModel.generationState {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview("My Flyer", image: shareImage)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(FGColors.accentPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingRefinementSheet) {
                RefinementSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingReformatSheet) {
                ReformatSheet(viewModel: viewModel)
            }
            .onAppear {
                // Wire up credit deduction callback - called after each successful API call
                viewModel.onCreditDeduction = { [self] in
                    deductCredit()
                }
            }
        }
    }

    private func deductCredit() {
        if let profile = userProfiles.first, profile.credits > 0 {
            profile.credits -= 1
            profile.lastSyncedAt = Date()
            try? modelContext.save()
            print("Credit deducted. Remaining credits: \(profile.credits)")

            // Sync credits to CloudKit
            Task {
                await cloudKitService.saveCredits(profile.credits)
            }
        }
    }

    private var shareImage: Image {
        if case .success(let uiImage) = viewModel.generationState {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    private func saveToPhotos() {
        Task {
            do {
                try await viewModel.saveToPhotos()
                showingSaveSuccess = true
                saveError = nil

                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showingSaveSuccess = false
                }
            } catch {
                saveError = error.localizedDescription
                showingSaveSuccess = false
            }
        }
    }

    private func saveToGalleryAndDismiss() {
        // Save to gallery if not already saved
        if !hasSavedToGallery {
            saveToGallery()
        }

        viewModel.cancelCreation()
        dismiss()
    }

    private func saveToGallery() {
        guard let project = viewModel.project,
              let generatedFlyer = viewModel.generatedFlyer else {
            return
        }

        let savedFlyer = SavedFlyer(project: project, generatedFlyer: generatedFlyer)
        modelContext.insert(savedFlyer)

        do {
            try modelContext.save()
            hasSavedToGallery = true
        } catch {
            print("Failed to save flyer to gallery: \(error)")
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FGSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(FGTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.md)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.generationState = .success(UIImage(systemName: "doc.richtext")!)
    return ResultView(viewModel: vm)
}
