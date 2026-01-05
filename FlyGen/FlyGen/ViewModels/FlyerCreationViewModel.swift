import SwiftUI
import PhotosUI

/// The current step in the creation flow
enum CreationStep: Int, CaseIterable {
    case category = 0
    case textContent = 1
    case visualStyle = 2
    case mood = 3
    case colors = 4
    case format = 5
    case qrCode = 6
    case extras = 7
    case review = 8

    var title: String {
        switch self {
        case .category: return "Category"
        case .textContent: return "Text Content"
        case .visualStyle: return "Visual Style"
        case .mood: return "Mood"
        case .colors: return "Colors"
        case .format: return "Format"
        case .qrCode: return "QR Code"
        case .extras: return "Extras"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .category: return "What are you creating?"
        case .textContent: return "Add your text"
        case .visualStyle: return "Choose a style"
        case .mood: return "Set the mood"
        case .colors: return "Pick colors"
        case .format: return "Select format"
        case .qrCode: return "Add scannable link"
        case .extras: return "Finishing touches"
        case .review: return "Review your flyer"
        }
    }

    var next: CreationStep? {
        CreationStep(rawValue: rawValue + 1)
    }

    var previous: CreationStep? {
        CreationStep(rawValue: rawValue - 1)
    }

    static var totalSteps: Int { allCases.count }
}

/// Generation state
enum GenerationState: Equatable {
    case idle
    case generating
    case success(UIImage)
    case error(String)

    static func == (lhs: GenerationState, rhs: GenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.generating, .generating): return true
        case (.success, .success): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Main ViewModel for the flyer creation flow
@MainActor
class FlyerCreationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: CreationStep = .category
    @Published var project: FlyerProject?
    @Published var generationState: GenerationState = .idle
    @Published var generatedImageData: Data?
    @Published var generatedFlyer: GeneratedFlyer?
    @Published var lastPrompt: String = ""
    @Published var showingCreationFlow = false
    @Published var showingResult = false

    // Intent selection (two-step flow)
    @Published var selectedIntent: Intent?
    @Published var showAllOutputTypes: Bool = false

    // Logo picker
    @Published var selectedLogoItem: PhotosPickerItem?

    // User photo picker
    @Published var selectedUserPhotoItem: PhotosPickerItem?

    // MARK: - Credit Management

    /// Callback triggered after each successful API call to deduct a credit
    var onCreditDeduction: (() -> Void)?

    // MARK: - Services

    private let openRouterService = OpenRouterService()
    private let draftService = DraftStorageService()

    // MARK: - Draft State

    @Published var hasPendingDraft: Bool = false

    // MARK: - Initialization

    init() {
        // Check for pending draft on init
        hasPendingDraft = draftService.hasDraft()
    }

    // MARK: - Computed Properties

    var canGoNext: Bool {
        guard let project = project else { return false }

        switch currentStep {
        case .category:
            return true // Category is selected when project is created
        case .textContent:
            return project.textContent.isValid
        case .visualStyle, .mood, .colors, .format, .qrCode, .extras:
            return true
        case .review:
            return project.isReadyForGeneration
        }
    }

    var canGoBack: Bool {
        // Can go back if there's a previous step OR if on category step with intent selected
        currentStep.previous != nil || (currentStep == .category && selectedIntent != nil)
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(CreationStep.totalSteps)
    }

    // MARK: - Actions

    /// Start a new flyer creation with the given category
    func startNewFlyer(category: FlyerCategory) {
        project = FlyerProject(category: category)
        currentStep = .textContent
        generationState = .idle
        generatedImageData = nil
        showingCreationFlow = true
    }

    /// Load a template and start the creation flow at Text Content step
    func loadTemplate(_ template: FlyerTemplate) {
        project = template.toProject()

        // Clear fields that won't be visible in the form for this category
        // This prevents hidden data from appearing in the generated flyer
        clearNonVisibleFields()

        currentStep = .textContent
        generationState = .idle
        generatedImageData = nil
        generatedFlyer = nil
        showingCreationFlow = true
    }

    /// Load a saved flyer's project as a template and start the creation flow
    func loadFromSavedFlyer(_ savedFlyer: SavedFlyer) {
        guard let savedProject = savedFlyer.project else { return }

        // Create a copy with new ID and timestamps
        project = FlyerProject(copyFrom: savedProject)

        // Clear fields that won't be visible in the form for this category
        // This prevents hidden data from appearing in the generated flyer
        clearNonVisibleFields()

        currentStep = .textContent
        generationState = .idle
        generatedImageData = nil
        generatedFlyer = nil
        showingCreationFlow = true
    }

    /// Load a sample flyer as a starting point and start the creation flow
    func loadFromSample(_ sample: SampleFlyer) {
        project = sample.toProject()

        // Clear fields that won't be visible in the form for this category
        // This prevents hidden data from appearing in the generated flyer
        clearNonVisibleFields()

        currentStep = .textContent
        generationState = .idle
        generatedImageData = nil
        generatedFlyer = nil
        showingCreationFlow = true
    }

    /// Move to the next step
    func goToNextStep() {
        if let next = currentStep.next {
            currentStep = next
            saveDraft()
        }
    }

    /// Move to the previous step
    func goToPreviousStep() {
        if let previous = currentStep.previous {
            currentStep = previous
            saveDraft()
        }
    }

    /// Jump to a specific step
    func goToStep(_ step: CreationStep) {
        currentStep = step
    }

    /// Cancel the current creation
    func cancelCreation() {
        showingCreationFlow = false
        currentStep = .category
        project = nil
        generationState = .idle
        generatedImageData = nil
        generatedFlyer = nil
        selectedIntent = nil
        showAllOutputTypes = false
    }

    // MARK: - Intent Selection (Two-Step Flow)

    /// Select an intent and show filtered output types
    func selectIntent(_ intent: Intent) {
        selectedIntent = intent
        showAllOutputTypes = false
    }

    /// Go back to intent selection
    func backToIntentSelection() {
        selectedIntent = nil
        showAllOutputTypes = false
    }

    /// Toggle showing all output types regardless of intent
    func toggleShowAllTypes() {
        showAllOutputTypes.toggle()
    }

    // MARK: - Draft Management

    /// Save current project as draft
    func saveDraft() {
        guard let project = project else { return }
        draftService.saveDraft(project: project, currentStep: currentStep)
        hasPendingDraft = true
    }

    /// Load the saved draft and resume creation flow
    func loadDraft() {
        guard let (project, step) = draftService.loadDraft() else { return }

        self.project = project
        self.currentStep = step
        self.generationState = .idle
        self.generatedImageData = nil
        self.generatedFlyer = nil
        self.showingCreationFlow = true
    }

    /// Discard the saved draft
    func discardDraft() {
        draftService.clearDraft()
        hasPendingDraft = false
    }

    /// Check for pending draft (useful on app resume)
    func checkForPendingDraft() {
        hasPendingDraft = draftService.hasDraft()
    }

    /// Get draft category name for display
    var draftCategoryName: String? {
        draftService.draftCategoryName()
    }

    /// Get draft saved date for display
    var draftSavedAt: Date? {
        draftService.draftSavedAt()
    }

    /// Generate the flyer
    func generateFlyer() async {
        guard let project = project else { return }

        generationState = .generating

        do {
            let result = try await openRouterService.generateImage(
                project: project
            )

            // Store the prompt for potential refinements
            let promptBuilder = PromptBuilder(project: project)
            lastPrompt = promptBuilder.build().mainPrompt

            // Apply QR code if enabled
            var finalImage = result.image
            var finalImageData = result.imageData

            if project.qrSettings.enabled {
                let qrService = QRCodeService()
                if let content = await qrService.generateContent(from: project.qrSettings),
                   let qrImage = await qrService.generateQRCode(from: content),
                   let composited = await qrService.compositeQRCode(
                       onto: finalImage,
                       qrCode: qrImage,
                       position: project.qrSettings.position
                   ) {
                    finalImage = composited
                    finalImageData = composited.pngData() ?? result.imageData
                }
            }

            generatedImageData = finalImageData
            generationState = .success(finalImage)

            // Deduct credit for successful generation
            onCreditDeduction?()

            // Create GeneratedFlyer for saving to gallery
            generatedFlyer = GeneratedFlyer(
                projectId: project.id,
                imageData: finalImageData,
                prompt: lastPrompt,
                negativePrompt: promptBuilder.build().negativePrompt,
                model: "flux-schnell"
            )

            showingResult = true

        } catch {
            generationState = .error(error.localizedDescription)
        }
    }

    /// Refine the generated flyer with feedback
    func refineFlyer(feedback: String) async {
        guard !lastPrompt.isEmpty else { return }

        generationState = .generating

        let refinedPrompt = RefinementBuilder.buildRefinement(
            originalPrompt: lastPrompt,
            userFeedback: feedback
        )

        do {
            let result = try await openRouterService.generateImage(
                prompt: refinedPrompt,
                aspectRatio: project?.output.aspectRatio ?? .portrait,
                logoImageData: project?.logoImageData,
                userPhotoData: project?.userPhotoData
            )

            lastPrompt = refinedPrompt

            // Apply QR code if enabled (preserve from original generation)
            var finalImage = result.image
            var finalImageData = result.imageData

            if let project = project, project.qrSettings.enabled {
                let qrService = QRCodeService()
                if let content = await qrService.generateContent(from: project.qrSettings),
                   let qrImage = await qrService.generateQRCode(from: content),
                   let composited = await qrService.compositeQRCode(
                       onto: finalImage,
                       qrCode: qrImage,
                       position: project.qrSettings.position
                   ) {
                    finalImage = composited
                    finalImageData = composited.pngData() ?? result.imageData
                }
            }

            generatedImageData = finalImageData
            generationState = .success(finalImage)

            // Deduct credit for successful refinement
            onCreditDeduction?()

            // Update GeneratedFlyer
            if let projectId = project?.id {
                generatedFlyer = GeneratedFlyer(
                    projectId: projectId,
                    imageData: finalImageData,
                    prompt: refinedPrompt,
                    negativePrompt: "",
                    model: "flux-schnell"
                )
            }

        } catch {
            generationState = .error(error.localizedDescription)
        }
    }

    /// Regenerate the flyer without any text
    func regenerateWithoutText() async {
        guard !lastPrompt.isEmpty else { return }

        generationState = .generating

        let noTextPrompt = RefinementBuilder.buildNoTextRefinement(originalPrompt: lastPrompt)

        do {
            let result = try await openRouterService.generateImage(
                prompt: noTextPrompt,
                aspectRatio: project?.output.aspectRatio ?? .portrait,
                logoImageData: project?.logoImageData,
                userPhotoData: project?.userPhotoData
            )

            lastPrompt = noTextPrompt

            // Apply QR code if enabled (preserve from original generation)
            var finalImage = result.image
            var finalImageData = result.imageData

            if let project = project, project.qrSettings.enabled {
                let qrService = QRCodeService()
                if let content = await qrService.generateContent(from: project.qrSettings),
                   let qrImage = await qrService.generateQRCode(from: content),
                   let composited = await qrService.compositeQRCode(
                       onto: finalImage,
                       qrCode: qrImage,
                       position: project.qrSettings.position
                   ) {
                    finalImage = composited
                    finalImageData = composited.pngData() ?? result.imageData
                }
            }

            generatedImageData = finalImageData
            generationState = .success(finalImage)

            // Deduct credit for successful regeneration
            onCreditDeduction?()

            // Update GeneratedFlyer
            if let projectId = project?.id {
                generatedFlyer = GeneratedFlyer(
                    projectId: projectId,
                    imageData: finalImageData,
                    prompt: noTextPrompt,
                    negativePrompt: "",
                    model: "flux-schnell"
                )
            }

        } catch {
            generationState = .error(error.localizedDescription)
        }
    }

    /// Regenerate with a different aspect ratio
    func reformatFlyer(newRatio: AspectRatio) async {
        guard !lastPrompt.isEmpty else { return }

        generationState = .generating

        do {
            let result = try await openRouterService.generateImage(
                prompt: lastPrompt,
                aspectRatio: newRatio,
                logoImageData: project?.logoImageData,
                userPhotoData: project?.userPhotoData
            )

            project?.output.aspectRatio = newRatio

            // Apply QR code if enabled (preserve from original generation)
            var finalImage = result.image
            var finalImageData = result.imageData

            if let project = project, project.qrSettings.enabled {
                let qrService = QRCodeService()
                if let content = await qrService.generateContent(from: project.qrSettings),
                   let qrImage = await qrService.generateQRCode(from: content),
                   let composited = await qrService.compositeQRCode(
                       onto: finalImage,
                       qrCode: qrImage,
                       position: project.qrSettings.position
                   ) {
                    finalImage = composited
                    finalImageData = composited.pngData() ?? result.imageData
                }
            }

            generatedImageData = finalImageData
            generationState = .success(finalImage)

            // Deduct credit for successful reformat
            onCreditDeduction?()

            // Update GeneratedFlyer
            if let projectId = project?.id {
                generatedFlyer = GeneratedFlyer(
                    projectId: projectId,
                    imageData: finalImageData,
                    prompt: lastPrompt,
                    negativePrompt: "",
                    model: "flux-schnell"
                )
            }

        } catch {
            generationState = .error(error.localizedDescription)
        }
    }

    /// Save the generated flyer to photos
    func saveToPhotos() async throws {
        guard let imageData = generatedImageData,
              let image = UIImage(data: imageData) else {
            throw PhotoLibraryError.unknown
        }

        try await PhotoLibraryService.saveImage(image)
    }

    /// Load logo from PhotosPickerItem
    func loadLogo() async {
        guard let item = selectedLogoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                project?.logoImageData = data
            }
        } catch {
            print("Failed to load logo: \(error)")
        }
    }

    /// Clear the selected logo
    func clearLogo() {
        selectedLogoItem = nil
        project?.logoImageData = nil
    }

    /// Load user photo from PhotosPickerItem
    func loadUserPhoto() async {
        guard let item = selectedUserPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                project?.userPhotoData = data
                // Clear imagery description since modes are mutually exclusive
                project?.imageryDescription = nil
            }
        } catch {
            print("Failed to load user photo: \(error)")
        }
    }

    /// Clear the selected user photo
    func clearUserPhoto() {
        selectedUserPhotoItem = nil
        project?.userPhotoData = nil
    }

    /// Set imagery description and clear photo (mutually exclusive)
    func setImageryDescription(_ description: String?) {
        project?.imageryDescription = description?.isEmpty == true ? nil : description
        if project?.imageryDescription != nil {
            // Clear photo since modes are mutually exclusive
            clearUserPhoto()
        }
    }

    // MARK: - Text Content Helpers

    /// Clear text fields that won't be visible in the form for the current category
    /// This prevents hidden data from the original flyer from appearing in the generated output
    private func clearNonVisibleFields() {
        guard let category = project?.category else { return }

        let visibleFields = Set(CategoryConfiguration.fieldsFor(category))

        // Clear date/time if not visible (category uses scheduleEntries instead)
        if !visibleFields.contains(.date) {
            project?.textContent.date = nil
        }
        if !visibleFields.contains(.time) {
            project?.textContent.time = nil
        }

        // Clear scheduleEntries (additionalInfo) if not visible
        if !visibleFields.contains(.scheduleEntries) {
            project?.textContent.additionalInfo = nil
        }

        // Clear other optional fields if not visible
        if !visibleFields.contains(.subheadline) {
            project?.textContent.subheadline = nil
        }
        if !visibleFields.contains(.bodyText) {
            project?.textContent.bodyText = nil
        }
        if !visibleFields.contains(.venueName) {
            project?.textContent.venueName = nil
        }
        if !visibleFields.contains(.address) {
            project?.textContent.address = nil
        }
        if !visibleFields.contains(.price) {
            project?.textContent.price = nil
        }
        if !visibleFields.contains(.discountText) {
            project?.textContent.discountText = nil
        }
        if !visibleFields.contains(.ctaText) {
            project?.textContent.ctaText = nil
        }
        if !visibleFields.contains(.phone) {
            project?.textContent.phone = nil
        }
        if !visibleFields.contains(.email) {
            project?.textContent.email = nil
        }
        if !visibleFields.contains(.website) {
            project?.textContent.website = nil
        }
        if !visibleFields.contains(.socialHandle) {
            project?.textContent.socialHandle = nil
        }
        if !visibleFields.contains(.finePrint) {
            project?.textContent.finePrint = nil
        }
    }

    /// Get binding for a text field
    func binding(for field: TextFieldType) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.getValue(for: field) ?? ""
            },
            set: { [weak self] newValue in
                self?.setValue(newValue, for: field)
            }
        )
    }

    /// Get binding for additionalInfo (used by ScheduleEntriesField)
    var additionalInfoBinding: Binding<[String]?> {
        Binding(
            get: { [weak self] in
                self?.project?.textContent.additionalInfo
            },
            set: { [weak self] newValue in
                self?.project?.textContent.additionalInfo = newValue
            }
        )
    }

    /// Get binding for language selection
    var languageBinding: Binding<FlyerLanguage> {
        Binding(
            get: { [weak self] in
                self?.project?.language ?? .english
            },
            set: { [weak self] newValue in
                self?.project?.language = newValue
            }
        )
    }

    private func getValue(for field: TextFieldType) -> String {
        guard let text = project?.textContent else { return "" }
        switch field {
        case .headline: return text.headline
        case .subheadline: return text.subheadline ?? ""
        case .bodyText: return text.bodyText ?? ""
        case .date: return text.date ?? ""
        case .time: return text.time ?? ""
        case .venueName: return text.venueName ?? ""
        case .address: return text.address ?? ""
        case .price: return text.price ?? ""
        case .discountText: return text.discountText ?? ""
        case .ctaText: return text.ctaText ?? ""
        case .phone: return text.phone ?? ""
        case .email: return text.email ?? ""
        case .website: return text.website ?? ""
        case .socialHandle: return text.socialHandle ?? ""
        case .finePrint: return text.finePrint ?? ""
        case .scheduleEntries: return "" // Handled by additionalInfoBinding
        }
    }

    private func setValue(_ value: String, for field: TextFieldType) {
        guard project != nil else { return }
        let optionalValue: String? = value.isEmpty ? nil : value

        switch field {
        case .headline: project?.textContent.headline = value
        case .subheadline: project?.textContent.subheadline = optionalValue
        case .bodyText: project?.textContent.bodyText = optionalValue
        case .date: project?.textContent.date = optionalValue
        case .time: project?.textContent.time = optionalValue
        case .venueName: project?.textContent.venueName = optionalValue
        case .address: project?.textContent.address = optionalValue
        case .price: project?.textContent.price = optionalValue
        case .discountText: project?.textContent.discountText = optionalValue
        case .ctaText: project?.textContent.ctaText = optionalValue
        case .phone: project?.textContent.phone = optionalValue
        case .email: project?.textContent.email = optionalValue
        case .website: project?.textContent.website = optionalValue
        case .socialHandle: project?.textContent.socialHandle = optionalValue
        case .finePrint: project?.textContent.finePrint = optionalValue
        case .scheduleEntries: break // Handled by additionalInfoBinding
        }
    }
}
