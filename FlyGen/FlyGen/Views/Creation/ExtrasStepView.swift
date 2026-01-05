import SwiftUI
import PhotosUI

struct ExtrasStepView: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @State private var includeElementsText: String = ""
    @State private var avoidElementsText: String = ""
    @State private var imageryMode: ImageryMode = .none

    enum ImageryMode: String, CaseIterable {
        case none = "none"
        case uploadPhoto = "upload"
        case describeImagery = "describe"

        var label: String {
            switch self {
            case .none: return "None"
            case .uploadPhoto: return "Upload Photo"
            case .describeImagery: return "Describe"
            }
        }
    }

    private var suggestedElements: [String] {
        viewModel.aiElementSuggestions
    }

    private var suggestedAvoidElements: [String] {
        guard let category = viewModel.project?.category else { return CategoryConfiguration.commonAvoidElements }
        return CategoryConfiguration.avoidSuggestionsFor(category)
    }

    private var suggestedSpecialInstructions: [String] {
        viewModel.aiSuggestions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpacing.xl) {
                // Header
                FGStepHeader(
                    title: "Fine-tune details",
                    subtitle: "Add specific elements, audience info, and optional logo",
                    tooltipText: "These extras help the AI understand exactly what you want"
                )

                // Include elements section
                includeElementsSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Avoid elements section
                avoidElementsSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Divider
                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Target audience section
                targetAudienceSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Special instructions section
                specialInstructionsSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Divider
                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Custom imagery section
                imagerySection
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Divider
                Rectangle()
                    .fill(FGColors.borderSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Logo upload section
                logoUploadSection
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .padding(.vertical, FGSpacing.lg)
        }
        .background(FGColors.backgroundPrimary)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // Initialize local state from project data
            if let elements = viewModel.project?.visuals.includeElements, !elements.isEmpty {
                includeElementsText = elements.joined(separator: ", ")
            }
            if let elements = viewModel.project?.visuals.avoidElements, !elements.isEmpty {
                avoidElementsText = elements.joined(separator: ", ")
            }

            // Load AI-generated suggestions if not already loaded
            if viewModel.aiSuggestions.isEmpty {
                Task {
                    await viewModel.loadAISuggestions()
                }
            }
        }
    }

    // MARK: - Include Elements Section

    private var includeElementsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Elements to Include")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGTooltip(text: "Specific visual elements you want in your flyer")
            }

            FGTextField(
                placeholder: "e.g., balloons, confetti, stars",
                text: $includeElementsText,
                icon: "plus.circle"
            )
            .onChange(of: includeElementsText) { _, newValue in
                viewModel.project?.visuals.includeElements = newValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }

            // Suggestions
            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("Suggestions")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)

                if viewModel.isLoadingSuggestions {
                    HStack(spacing: FGSpacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating suggestions...")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(.vertical, FGSpacing.sm)
                } else if !suggestedElements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FGSpacing.xs) {
                            ForEach(suggestedElements, id: \.self) { element in
                                SuggestionChip(text: element, isAdded: includeElementsText.contains(element)) {
                                    addSuggestion(element)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Avoid Elements Section

    private var avoidElementsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Elements to Avoid")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGTooltip(text: "Things you don't want in your design")
            }

            FGTextField(
                placeholder: "e.g., people, faces, hands",
                text: $avoidElementsText,
                icon: "minus.circle"
            )
            .onChange(of: avoidElementsText) { _, newValue in
                viewModel.project?.visuals.avoidElements = newValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }

            // Category-specific avoidance suggestions
            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("Suggestions")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FGSpacing.xs) {
                        ForEach(suggestedAvoidElements, id: \.self) { element in
                            SuggestionChip(
                                text: element,
                                isAdded: avoidElementsText.contains(element),
                                style: .avoid
                            ) {
                                addAvoidSuggestion(element)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Target Audience Section

    private var targetAudienceSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Target Audience")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGTooltip(text: "Who is this flyer designed for?")
            }

            FGTextField(
                placeholder: "e.g., Young professionals, families",
                text: Binding(
                    get: { viewModel.project?.targetAudience ?? "" },
                    set: { viewModel.project?.targetAudience = $0.isEmpty ? nil : $0 }
                ),
                icon: "person.2"
            )
        }
    }

    // MARK: - Special Instructions Section

    private var specialInstructionsSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Special Instructions")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGTooltip(text: "Any additional guidance for the AI")
            }

            TextEditor(text: Binding(
                get: { viewModel.project?.specialInstructions ?? "" },
                set: { viewModel.project?.specialInstructions = $0.isEmpty ? nil : $0 }
            ))
            .font(FGTypography.body)
            .foregroundColor(FGColors.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100)
            .padding(FGSpacing.sm)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )

            // Suggestion chips for special instructions
            VStack(alignment: .leading, spacing: FGSpacing.xs) {
                Text("Suggestions")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)

                if viewModel.isLoadingSuggestions {
                    HStack(spacing: FGSpacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating suggestions...")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(.vertical, FGSpacing.sm)
                } else if !suggestedSpecialInstructions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FGSpacing.xs) {
                            ForEach(suggestedSpecialInstructions, id: \.self) { suggestion in
                                SuggestionChip(
                                    text: suggestion,
                                    isAdded: viewModel.project?.specialInstructions?.contains(suggestion) ?? false
                                ) {
                                    addSpecialInstructionSuggestion(suggestion)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Custom Imagery Section

    private var imagerySection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Custom Imagery")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGInfoBadge(text: "Optional")
            }

            Text("Add your own photo or describe imagery for AI to generate")
                .font(FGTypography.bodySmall)
                .foregroundColor(FGColors.textTertiary)

            // Mode selector
            Picker("Imagery Mode", selection: $imageryMode) {
                ForEach(ImageryMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: imageryMode) { _, newMode in
                handleImageryModeChange(newMode)
            }

            // Content based on mode
            switch imageryMode {
            case .none:
                EmptyView()
            case .uploadPhoto:
                userPhotoUploadView
            case .describeImagery:
                imageryDescriptionView
            }
        }
        .onAppear {
            // Initialize mode based on existing data
            if viewModel.project?.userPhotoData != nil {
                imageryMode = .uploadPhoto
            } else if viewModel.project?.imageryDescription != nil {
                imageryMode = .describeImagery
            }
        }
    }

    private var userPhotoUploadView: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            if let photoData = viewModel.project?.userPhotoData,
               let uiImage = UIImage(data: photoData) {
                // Show uploaded photo
                HStack(spacing: FGSpacing.md) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                        Text("Photo uploaded")
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textPrimary)

                        Text("AI will stylize and incorporate this photo")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }

                    Spacer()

                    Button {
                        withAnimation(FGAnimations.spring) {
                            viewModel.clearUserPhoto()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FGColors.statusError)
                    }
                }
                .padding(FGSpacing.cardPadding)
                .background(FGColors.surfaceDefault)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                        .stroke(FGColors.borderSubtle, lineWidth: 1)
                )
            } else {
                PhotosPicker(selection: $viewModel.selectedUserPhotoItem, matching: .images) {
                    HStack(spacing: FGSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .fill(FGColors.backgroundTertiary)
                                .frame(width: 48, height: 48)

                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(FGColors.accentPrimary)
                        }

                        VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                            Text("Upload a Photo")
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)

                            Text("Products, people, pets, or places work great")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(FGSpacing.cardPadding)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                }
                .onChange(of: viewModel.selectedUserPhotoItem) { _, _ in
                    Task {
                        await viewModel.loadUserPhoto()
                    }
                }
            }
        }
    }

    private var imageryDescriptionView: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            TextEditor(text: Binding(
                get: { viewModel.project?.imageryDescription ?? "" },
                set: { viewModel.setImageryDescription($0) }
            ))
            .font(FGTypography.body)
            .foregroundColor(FGColors.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 80)
            .padding(FGSpacing.sm)
            .background(FGColors.surfaceDefault)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )

            Text("Example: \"A golden retriever playing fetch in a sunny park\"")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
        }
    }

    private func handleImageryModeChange(_ newMode: ImageryMode) {
        switch newMode {
        case .none:
            viewModel.clearUserPhoto()
            viewModel.setImageryDescription(nil)
        case .uploadPhoto:
            viewModel.setImageryDescription(nil)
        case .describeImagery:
            viewModel.clearUserPhoto()
        }
    }

    // MARK: - Logo Upload Section

    private var logoUploadSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Text("Logo")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                FGInfoBadge(text: "Optional")
            }

            if let logoData = viewModel.project?.logoImageData,
               let uiImage = UIImage(data: logoData) {
                // Show uploaded logo
                HStack(spacing: FGSpacing.md) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                        Text("Logo uploaded")
                            .font(FGTypography.label)
                            .foregroundColor(FGColors.textPrimary)

                        Text("Will be incorporated into design")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }

                    Spacer()

                    Button {
                        withAnimation(FGAnimations.spring) {
                            viewModel.clearLogo()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(FGColors.statusError)
                    }
                }
                .padding(FGSpacing.cardPadding)
                .background(FGColors.surfaceDefault)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                        .stroke(FGColors.borderSubtle, lineWidth: 1)
                )
            } else {
                PhotosPicker(selection: $viewModel.selectedLogoItem, matching: .images) {
                    HStack(spacing: FGSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                                .fill(FGColors.backgroundTertiary)
                                .frame(width: 48, height: 48)

                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(FGColors.accentPrimary)
                        }

                        VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                            Text("Add Your Logo")
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)

                            Text("PNG or JPG, transparent background works best")
                                .font(FGTypography.caption)
                                .foregroundColor(FGColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FGColors.textTertiary)
                    }
                    .padding(FGSpacing.cardPadding)
                    .background(FGColors.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .stroke(FGColors.borderSubtle, lineWidth: 1)
                    )
                }
                .onChange(of: viewModel.selectedLogoItem) { _, _ in
                    Task {
                        await viewModel.loadLogo()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func addSuggestion(_ element: String) {
        if includeElementsText.isEmpty {
            includeElementsText = element
        } else if !includeElementsText.contains(element) {
            includeElementsText += ", \(element)"
        }
    }

    private func addAvoidSuggestion(_ element: String) {
        if avoidElementsText.isEmpty {
            avoidElementsText = element
        } else if !avoidElementsText.contains(element) {
            avoidElementsText += ", \(element)"
        }
    }

    private func addSpecialInstructionSuggestion(_ suggestion: String) {
        let currentInstructions = viewModel.project?.specialInstructions ?? ""
        if currentInstructions.isEmpty {
            viewModel.project?.specialInstructions = suggestion
        } else if !currentInstructions.contains(suggestion) {
            viewModel.project?.specialInstructions = currentInstructions + ". " + suggestion
        }
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let isAdded: Bool
    var style: ChipStyle = .include
    let action: () -> Void

    enum ChipStyle {
        case include
        case avoid
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpacing.xxs) {
                if isAdded {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(text)
                    .font(FGTypography.captionBold)
            }
            .padding(.horizontal, FGSpacing.sm)
            .padding(.vertical, FGSpacing.xs)
            .background(chipBackground)
            .foregroundColor(chipForeground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(chipBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var chipBackground: Color {
        if isAdded {
            return style == .include ? FGColors.accentPrimary.opacity(0.2) : FGColors.statusError.opacity(0.2)
        }
        return FGColors.backgroundTertiary
    }

    private var chipForeground: Color {
        if isAdded {
            return style == .include ? FGColors.accentPrimary : FGColors.statusError
        }
        return FGColors.textSecondary
    }

    private var chipBorder: Color {
        if isAdded {
            return style == .include ? FGColors.accentPrimary.opacity(0.5) : FGColors.statusError.opacity(0.5)
        }
        return FGColors.borderSubtle
    }
}

#Preview {
    let vm = FlyerCreationViewModel()
    vm.startNewFlyer(category: .partyCelebration)
    return ExtrasStepView(viewModel: vm)
}
