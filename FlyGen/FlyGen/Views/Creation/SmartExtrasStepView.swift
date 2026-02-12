import SwiftUI
import SwiftData
import PhotosUI

struct SmartExtrasStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var isLoading = true
    @State private var loadError: String?

    private let suggestionsService = SmartSuggestionsService()

    private var credits: Int {
        userProfiles.first?.credits ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.xl) {
                // Personalized Header
                FGStepHeader(
                    title: headerTitle,
                    subtitle: "Add photos and elements to enhance your flyer",
                    tooltipText: "Smart suggestions based on your flyer content"
                )

                if isLoading {
                    loadingView
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                } else if let error = loadError {
                    errorView(error)
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                } else {
                    // Photo Suggestions Section
                    if !photoSuggestions.isEmpty {
                        photoSuggestionsSection
                    }

                    // Visual Elements Section
                    if !elementSuggestions.isEmpty {
                        visualElementsSection
                    }
                }

                // Divider
                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Additional Notes (always visible)
                additionalNotesSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            loadSmartSuggestions()
        }
    }

    // MARK: - Computed Properties

    private var headerTitle: String {
        viewModel.project?.smartExtras.headerTitle ?? defaultHeaderTitle
    }

    private var defaultHeaderTitle: String {
        guard let category = viewModel.project?.category else { return "Finishing touches" }

        switch category {
        case .restaurantFood: return "Make it appetizing"
        case .musicConcert: return "Set the stage"
        case .realEstate: return "Showcase the property"
        case .partyCelebration: return "Make it festive"
        case .salePromo: return "Boost the urgency"
        case .grandOpening: return "Create excitement"
        case .fitnessWellness: return "Inspire action"
        case .jobPosting: return "Attract talent"
        case .classWorkshop: return "Highlight the experience"
        case .nonprofitCharity: return "Inspire action"
        default: return "Finishing touches"
        }
    }

    private var photoSuggestions: [PhotoSuggestion] {
        viewModel.project?.smartExtras.photoSuggestions ?? []
    }

    private var elementSuggestions: [ElementSuggestion] {
        viewModel.project?.smartExtras.elementSuggestions ?? []
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FGSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your flyer...")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)

            Text("Generating personalized suggestions")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FGSpacing.xxl)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: FGSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(FGColors.statusWarning)

            Text("Couldn't load suggestions")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)

            Text(error)
                .font(FGTypography.bodySmall)
                .foregroundColor(FGColors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                loadSmartSuggestions()
            } label: {
                Text("Try Again")
                    .font(FGTypography.button)
                    .foregroundColor(FGColors.accentPrimary)
            }
            .padding(.top, FGSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FGSpacing.xxl)
    }

    // MARK: - Photo Suggestions Section

    private var photoSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            Text("Photo Suggestions")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.sm) {
                ForEach(Array(photoSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                    PhotoSuggestionCard(
                        suggestion: suggestion,
                        onToggle: { isEnabled in
                            viewModel.project?.smartExtras.photoSuggestions[index].isEnabled = isEnabled
                            syncToLegacyFields()
                        },
                        onPhotoAdded: { data in
                            viewModel.project?.smartExtras.photoSuggestions[index].uploadedPhotosData.append(data)
                            syncToLegacyFields()
                        },
                        onPhotoRemoved: { photoIndex in
                            if let photoIndex = photoIndex {
                                // Remove specific photo
                                viewModel.project?.smartExtras.photoSuggestions[index].uploadedPhotosData.remove(at: photoIndex)
                            } else {
                                // Clear all photos
                                viewModel.project?.smartExtras.photoSuggestions[index].uploadedPhotosData.removeAll()
                            }
                            syncToLegacyFields()
                        },
                        onAIPromptEntered: { prompt in
                            viewModel.project?.smartExtras.photoSuggestions[index].aiGenerationPrompt = prompt
                            syncToLegacyFields()
                        },
                        onClearAIPrompt: {
                            viewModel.project?.smartExtras.photoSuggestions[index].aiGenerationPrompt = nil
                            syncToLegacyFields()
                        }
                    )
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - Visual Elements Section

    private var visualElementsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Visual Elements")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGTooltip(text: "Decorative elements to enhance your design")
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Text("Tap to include in your flyer")
                .font(FGTypography.bodySmall)
                .foregroundColor(FGColors.textTertiary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            // Flowing chip layout
            FlowLayout(spacing: FGSpacing.xs) {
                ForEach(Array(elementSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                    ElementChip(
                        suggestion: suggestion,
                        onToggle: {
                            viewModel.project?.smartExtras.elementSuggestions[index].isEnabled.toggle()
                            syncToLegacyFields()
                        }
                    )
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)
        }
    }

    // MARK: - Additional Notes Section

    private var additionalNotesSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Anything else?")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGInfoBadge(text: "Optional")
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { viewModel.project?.smartExtras.additionalNotes ?? "" },
                    set: { viewModel.project?.smartExtras.additionalNotes = $0.isEmpty ? nil : $0 }
                ))
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(FGSpacing.sm)

                if (viewModel.project?.smartExtras.additionalNotes ?? "").isEmpty {
                    Text("Special requests, specific styles, or details we should know...")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textTertiary)
                        .padding(FGSpacing.sm)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Data Loading

    private func loadSmartSuggestions() {
        guard let project = viewModel.project else { return }

        // Check if already loaded
        if !project.smartExtras.photoSuggestions.isEmpty || !project.smartExtras.elementSuggestions.isEmpty {
            isLoading = false
            return
        }

        // Check credits before API call
        guard credits >= 5 else {
            loadError = "Not enough credits (need 5)"
            isLoading = false
            return
        }

        isLoading = true
        loadError = nil

        Task {
            do {
                let smartExtras = try await suggestionsService.generateSuggestions(for: project)
                await MainActor.run {
                    viewModel.project?.smartExtras = smartExtras
                    deductCredits(5)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    loadError = "We couldn't generate personalized suggestions. You can still add notes below."
                    isLoading = false
                }
            }
        }
    }

    private func deductCredits(_ amount: Int) {
        if let profile = userProfiles.first, profile.credits >= amount {
            profile.credits -= amount
            profile.lastSyncedAt = Date()
            try? modelContext.save()
            Task { await cloudKitService.saveCredits(profile.credits) }
        }
    }

    // MARK: - Sync to Legacy Fields

    private func syncToLegacyFields() {
        guard let smartExtras = viewModel.project?.smartExtras else { return }

        // Sync enabled elements to visuals.includeElements
        viewModel.project?.visuals.includeElements = smartExtras.enabledElements

        // Sync all uploaded photos to userPhotosData
        let allPhotos = smartExtras.allUploadedPhotosData
        viewModel.project?.userPhotosData = allPhotos

        // Sync first AI prompt to imageryDescription (only if no photos uploaded)
        if allPhotos.isEmpty, let aiPrompt = smartExtras.firstAIGenerationPrompt {
            viewModel.project?.imageryDescription = aiPrompt
        } else if allPhotos.isEmpty {
            viewModel.project?.imageryDescription = nil
        }

        // Sync additional notes to specialInstructions
        viewModel.project?.specialInstructions = smartExtras.additionalNotes
    }
}

// MARK: - Photo Suggestion Card

struct PhotoSuggestionCard: View {
    let suggestion: PhotoSuggestion
    let onToggle: (Bool) -> Void
    let onPhotoAdded: (Data) -> Void
    let onPhotoRemoved: (Int?) -> Void  // nil means clear all
    let onAIPromptEntered: (String) -> Void
    let onClearAIPrompt: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?

    private var uploadedCount: Int {
        suggestion.uploadedPhotosData.count
    }

    private var hasMultipleSlots: Bool {
        suggestion.allowsMultiplePhotos && suggestion.photoCount > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Main card content
            HStack(spacing: FGSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(suggestion.isEnabled ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
                        .frame(width: 48, height: 48)

                    Image(systemName: suggestion.icon)
                        .font(.system(size: 20))
                        .foregroundColor(suggestion.isEnabled ? FGColors.accentPrimary : FGColors.textSecondary)
                }

                // Text content
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack(spacing: FGSpacing.xs) {
                        Text(suggestion.title)
                            .font(FGTypography.labelLarge)
                            .foregroundColor(FGColors.textPrimary)

                        // Show photo count badge for multi-photo suggestions
                        if hasMultipleSlots && suggestion.isEnabled {
                            Text("\(uploadedCount)/\(suggestion.photoCount)")
                                .font(FGTypography.captionSmall)
                                .foregroundColor(uploadedCount > 0 ? FGColors.statusSuccess : FGColors.textTertiary)
                                .padding(.horizontal, FGSpacing.xs)
                                .padding(.vertical, 2)
                                .background(uploadedCount > 0 ? FGColors.statusSuccess.opacity(0.1) : FGColors.backgroundTertiary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(suggestion.description)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)

                    // Detected items chips
                    if let items = suggestion.detectedItems, !items.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FGSpacing.xxs) {
                                ForEach(items.prefix(4), id: \.self) { item in
                                    Text(item)
                                        .font(FGTypography.captionSmall)
                                        .foregroundColor(FGColors.accentSecondary)
                                        .padding(.horizontal, FGSpacing.xs)
                                        .padding(.vertical, 2)
                                        .background(FGColors.accentSecondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, FGSpacing.xxs)
                    }
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { suggestion.isEnabled },
                    set: { onToggle($0) }
                ))
                .tint(FGColors.accentPrimary)
                .labelsHidden()
            }

            // Expanded action area when enabled
            if suggestion.isEnabled {
                VStack(spacing: FGSpacing.sm) {
                    // Multi-photo grid for people-based categories
                    if hasMultipleSlots {
                        // Show AI prompt preview if set
                        if let aiPrompt = suggestion.aiGenerationPrompt, !aiPrompt.isEmpty {
                            aiPromptPreview(aiPrompt)
                        } else {
                            multiPhotoGrid

                            // Show AI generation option for food categories (allows both upload and AI)
                            if suggestion.allowsAIGeneration && suggestion.uploadedPhotosData.isEmpty {
                                Button {
                                    if let items = suggestion.detectedItems, !items.isEmpty {
                                        onAIPromptEntered(items.joined(separator: ", "))
                                    } else {
                                        onAIPromptEntered(suggestion.title)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 14))
                                        Text("Or generate with AI")
                                            .font(FGTypography.caption)
                                    }
                                    .foregroundColor(FGColors.accentSecondary)
                                    .padding(.vertical, FGSpacing.xs)
                                }
                            }
                        }
                    }
                    // Single photo or AI generation
                    else if let photoData = suggestion.uploadedPhotosData.first,
                            let uiImage = UIImage(data: photoData) {
                        singlePhotoPreview(uiImage)
                    } else if let aiPrompt = suggestion.aiGenerationPrompt, !aiPrompt.isEmpty {
                        aiPromptPreview(aiPrompt)
                    } else {
                        // Action buttons for single photo
                        HStack(spacing: FGSpacing.sm) {
                            if suggestion.allowsUpload {
                                PhotosPicker(
                                    selection: $selectedPhotoItem,
                                    matching: .images
                                ) {
                                    actionButton(
                                        icon: "photo.badge.plus",
                                        title: "Upload Photo",
                                        isPrimary: true
                                    )
                                }
                            }

                            if suggestion.allowsAIGeneration {
                                Button {
                                    if let items = suggestion.detectedItems, !items.isEmpty {
                                        onAIPromptEntered(items.joined(separator: ", "))
                                    } else {
                                        onAIPromptEntered(suggestion.title)
                                    }
                                } label: {
                                    actionButton(
                                        icon: "wand.and.stars",
                                        title: "Generate with AI",
                                        isPrimary: false
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.top, FGSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(suggestion.isEnabled ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: suggestion.isEnabled ? 2 : 1)
        )
        .animation(FGAnimations.spring, value: suggestion.isEnabled)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    onPhotoAdded(data)
                    selectedPhotoItem = nil
                }
            }
        }
    }

    // MARK: - Multi-Photo Grid

    private var multiPhotoGrid: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Progress text
            if uploadedCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FGColors.statusSuccess)
                        .font(.system(size: 14))
                    Text("\(uploadedCount) of \(suggestion.photoCount) photos added")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)

                    Spacer()

                    if uploadedCount > 0 {
                        Button {
                            onPhotoRemoved(nil)  // Clear all
                        } label: {
                            Text("Clear all")
                                .font(FGTypography.captionSmall)
                                .foregroundColor(FGColors.statusError)
                        }
                    }
                }
            }

            // Photo grid - adaptive columns based on count
            let columns = gridColumns(for: suggestion.photoCount)
            LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                // Show uploaded photos
                ForEach(Array(suggestion.uploadedPhotosData.enumerated()), id: \.offset) { index, photoData in
                    if let uiImage = UIImage(data: photoData) {
                        photoSlot(image: uiImage, index: index)
                    }
                }

                // Show remaining empty slots (up to photoCount)
                let remainingSlots = suggestion.photoCount - uploadedCount
                if remainingSlots > 0 {
                    ForEach(0..<remainingSlots, id: \.self) { _ in
                        emptyPhotoSlot
                    }
                }
            }
        }
    }

    private func gridColumns(for count: Int) -> [GridItem] {
        let columnCount: Int
        switch count {
        case 1: columnCount = 1
        case 2: columnCount = 2
        case 3: columnCount = 3
        case 4: columnCount = 2
        case 5, 6: columnCount = 3
        default: columnCount = min(4, count)
        }
        return Array(repeating: GridItem(.flexible(), spacing: FGSpacing.sm), count: columnCount)
    }

    private func photoSlot(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))

            Button {
                onPhotoRemoved(index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(4)
        }
    }

    private var emptyPhotoSlot: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .fill(FGColors.backgroundTertiary)
                    .frame(height: 80)

                VStack(spacing: FGSpacing.xxs) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(FGColors.textTertiary)
                    Text("Add photo")
                        .font(FGTypography.captionSmall)
                        .foregroundColor(FGColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Single Photo Preview

    private func singlePhotoPreview(_ image: UIImage) -> some View {
        HStack(spacing: FGSpacing.md) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))

            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text("Photo ready")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.statusSuccess)

                Text("Will be incorporated into your flyer")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)
            }

            Spacer()

            Button {
                selectedPhotoItem = nil
                onPhotoRemoved(0)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(FGColors.textTertiary)
            }
        }
    }

    // MARK: - AI Prompt Preview

    private func aiPromptPreview(_ prompt: String) -> some View {
        HStack(spacing: FGSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .fill(FGColors.accentPrimary.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 24))
                    .foregroundColor(FGColors.accentPrimary)
            }

            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text("AI will generate photos")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.accentPrimary)

                Text(prompt)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                onClearAIPrompt()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(FGColors.textTertiary)
            }
        }
    }

    // MARK: - Action Button

    private func actionButton(icon: String, title: String, isPrimary: Bool) -> some View {
        HStack(spacing: FGSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
            Text(title)
                .font(FGTypography.buttonSmall)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FGSpacing.sm)
        .background(isPrimary ? FGColors.accentPrimary : FGColors.backgroundTertiary)
        .foregroundColor(isPrimary ? FGColors.textOnAccent : FGColors.textSecondary)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
    }
}

// MARK: - Element Chip

struct ElementChip: View {
    let suggestion: ElementSuggestion
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: FGSpacing.xxs) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 12))

                Text(suggestion.element)
                    .font(FGTypography.captionBold)

                if suggestion.isEnabled {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, FGSpacing.sm)
            .padding(.vertical, FGSpacing.xs)
            .background(suggestion.isEnabled ? FGColors.accentPrimary.opacity(0.2) : FGColors.backgroundTertiary)
            .foregroundColor(suggestion.isEnabled ? FGColors.accentPrimary : FGColors.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(suggestion.isEnabled ? FGColors.accentPrimary.opacity(0.5) : FGColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(FGAnimations.spring, value: suggestion.isEnabled)
    }
}

// MARK: - Preview

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .restaurantFood)
    vm.project?.textContent.headline = "Mario's Italian Kitchen"
    vm.project?.textContent.bodyText = "Margherita Pizza $14, Caesar Salad $9, Chicken Parmesan $18"
    return SmartExtrasStepView(viewModel: vm)
}
