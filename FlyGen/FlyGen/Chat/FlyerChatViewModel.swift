import SwiftUI
import PhotosUI
import UIKit

// MARK: - Transcript model

struct ChatBubble: Identifiable {
    let id: UUID
    let kind: Kind
    init(_ kind: Kind, id: UUID = UUID()) { self.kind = kind; self.id = id }
    enum Kind {
        case user(String)
        case userPhotos([Data])
        case assistant(String)
        case photoSuggestion(String, Bool)   // (message, resolved) - the brain's "add a photo of X" nudge; resolved hides the choices
        case qrOffer(QROfferDTO, resolved: Bool)   // proactive "add a QR?" offer; resolved hides the Yes/No choices
        case referenceNudge                  // "reuse a flyer you already have" - inline upload picker, shown once at start
        case typing(String)
        case parsedFields(ExtractedBriefDTO)
        case questions([QuestionDTO], String)
        case designBrief(DesignBriefDTO)
        case review(ReviewProposalDTO)
        case referenceImage(ConceptDTO)                  // the user's UPLOADED flyer (the edit starting point): image only, no save/resize
        case concepts([ConceptDTO], heading: String?)   // heading overrides the card title (e.g. a seeded "Starting point")
        case error(String)
    }
}

@MainActor
final class FlyerChatViewModel: ObservableObject {
    @Published var transcript: [ChatBubble] = []
    @Published var composerText: String = ""
    @Published var isStreaming: Bool = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var attachedPhotos: [Data] = []
    @Published var referencePickerItems: [PhotosPickerItem] = []   // the "reuse a flyer" upload
    @Published var annotationEditor: AnnotationEditorRequest?      // drives the full-screen annotation editor
    /// The flyer's target language for this session. Seeded from the profile default
    /// (see FlyerChatView.onAppear), changeable on the review card, sticky across edits.
    @Published var selectedLanguage: FlyerLanguage = .english
    /// Cards (questions / review) whose turn COMPLETED successfully - only these stay disabled.
    /// A card used to latch itself off before dispatch, so a network blip, paywall hit, or empty
    /// submit bricked it forever; now the latch lives here and is only set on success.
    @Published private(set) var resolvedCardIDs: Set<UUID> = []
    /// The card whose action is currently in flight (disabled while pending, re-enabled on failure).
    @Published private(set) var inFlightCardID: UUID?

    private let client = FlyerChatClient()
    private var brief: ExtractedBriefDTO?
    private var qr: QRSettingsDTO?              // standalone QR state, echoed on every action; no UI
    private var answers: [String: String] = [:]
    private var photoNudged = false
    // Reuse-a-flyer mode: once the user picks a flyer to edit, the composer AND the refine box route
    // to the `reference` action (image + the user's words -> Nano Banana), editing the current image
    // instead of starting a new flyer. Published so the composer can reflect the mode.
    @Published private(set) var inReferenceMode = false
    private var currentReferenceB64: String?    // the latest edited flyer image; the composer edits this
    private var pendingAnnotationDraft: AnnotationDraft?   // in-flight marked-up edit; kept so a failed turn can reopen the editor intact
    private var generationPhotos: [Data] = []   // photos committed to this flyer; sent at generation
    // Photo-suggestion gating: hold the review card until the user adds a photo or declines, so the
    // turn reads as a conversation instead of the LLM dumping everything (fields + review) at once.
    private var pendingReview: ReviewProposalDTO?
    private var awaitingPhotoChoice = false
    private var photoSuggestionID: UUID?
    private var turnHadError = false            // set by error events / failed generations within a turn
    private var restoreOnFailedTurn: (() -> Void)?   // puts pre-send state back if the turn dies before any event
    private var clearPhotosOnSuccess = false    // approve turn only: staged photos survive a failed turn for retry

    /// Fires once per SUCCESSFUL image generation (create / refine / resize) so the view can consume
    /// one unit of subscription quota. Mirrors FlyerCreationViewModel.onCreditDeduction; wired in
    /// FlyerChatView. Without this, chat generations bypass the quota entirely.
    var onCreditDeduction: (() -> Void)?

    func start(seed: SampleFlyer? = nil) {
        guard transcript.isEmpty else { return }
        if let seed = seed {
            seedFromSample(seed)
        } else {
            transcript.append(ChatBubble(.assistant("Tell me about the flyer you want — one sentence is plenty.")))
            transcript.append(ChatBubble(.referenceNudge))   // or upload a flyer to reuse
        }
    }

    // MARK: Seed from an Explore sample

    /// Open the chat already holding an Explore flyer: load its facts into the brief and show its
    /// image as the current design, so the user refines that exact flyer through the normal refine
    /// path (the refine box on the concept card -> action "refine" with this image as prior_image).
    private func seedFromSample(_ sample: SampleFlyer) {
        let seeded = Self.seedBrief(from: sample)
        brief = seeded
        transcript.append(ChatBubble(.assistant(
            "Here's \(sample.name) as your starting point. Tell me what to change under the image - the text, colors, or layout - and I'll edit this exact design.")))
        transcript.append(ChatBubble(.parsedFields(seeded)))
        // The bundled sample image becomes the "current concept" that the refine box edits.
        if let image = UIImage(named: sample.imageName),
           let jpeg = image.jpegData(compressionQuality: 0.9) {
            let concept = ConceptDTO(version_id: "seed-\(sample.id)",
                                     image_base64: jpeg.base64EncodedString(), error: nil)
            transcript.append(ChatBubble(.concepts([concept], heading: "Starting point")))
        }
    }

    /// Maps an Explore SampleFlyer into the chat's brief - the inverse of `chatFlyerProject()` - so
    /// the engine understands the flyer's content when it refines the seeded image. Visual look isn't
    /// carried here (it lives in the seeded image itself; the engine picks visuals server-side).
    static func seedBrief(from sample: SampleFlyer) -> ExtractedBriefDTO {
        let t = sample.textContent
        var extras = t.additionalInfo ?? []
        if let fine = t.finePrint, !fine.isEmpty { extras.append(fine) }
        // A sample's content is authored/known, so every mapped field reads as "stated".
        let sourced = ["category", "headline", "subheadline", "body_text", "date", "time",
                       "venue_name", "address", "price", "discount_text", "cta_text",
                       "phone", "email", "website", "social_handle"]
        let sources = Dictionary(uniqueKeysWithValues: sourced.map { ($0, "stated") })
        return ExtractedBriefDTO(
            category: sample.category.rawValue,
            headline: t.headline.isEmpty ? nil : t.headline,
            subheadline: t.subheadline,
            body_text: t.bodyText,
            date: t.date,
            time: t.time,
            venue_name: t.venueName,
            address: t.address,
            price: t.price,
            discount_text: t.discountText,
            cta_text: t.ctaText,
            phone: t.phone,
            email: t.email,
            website: t.website,
            social_handle: t.socialHandle,
            additional_info: extras.isEmpty ? nil : extras,
            purpose: sample.specialInstructions,
            destination: nil,
            field_sources: sources,
            photo_suggestion: nil)
    }

    // MARK: Photos

    /// Load the current PhotosPicker selection into raw Data (reused on every selection change).
    func loadAttachedPhotos() async {
        var loaded: [Data] = []
        for item in photoPickerItems {
            guard let raw = try? await item.loadTransferable(type: Data.self) else { continue }
            // Normalize to JPEG — the picker can yield HEIC, which the image model can't read.
            loaded.append(UIImage(data: raw)?.jpegData(compressionQuality: 0.9) ?? raw)
        }
        attachedPhotos = loaded
        if !attachedPhotos.isEmpty { commitSuggestedPhotos() }   // the suggestion bubble is the only photo entry
    }

    func removePhoto(at index: Int) {
        guard attachedPhotos.indices.contains(index) else { return }
        attachedPhotos.remove(at: index)
        if photoPickerItems.indices.contains(index) { photoPickerItems.remove(at: index) }
    }

    // MARK: Reuse a flyer

    /// The user picked a flyer to reuse: load it and enter reference-edit mode.
    func loadReference() async {
        guard let item = referencePickerItems.first,
              let raw = try? await item.loadTransferable(type: Data.self) else { return }
        referencePickerItems = []
        // Normalize to JPEG — the picker can yield HEIC, which the image model can't read.
        let jpeg = UIImage(data: raw)?.jpegData(compressionQuality: 0.9) ?? raw
        enterReferenceMode(with: jpeg)
    }

    /// Enter reference-edit mode from an in-app image already in hand - a saved flyer's
    /// `imageData` or an Explore sample rendered to JPEG. Same path as an uploaded photo.
    func useReference(imageData: Data) { enterReferenceMode(with: imageData) }

    /// User tapped "No thanks" on the reuse nudge: remove it so the chat starts clean.
    func dismissReferenceNudge() {
        transcript.removeAll { if case .referenceNudge = $0.kind { return true } else { return false } }
    }

    /// Show the uploaded flyer as the current design and invite edits under it. From here every
    /// refine routes to the `reference` action (image + the user's words -> Nano Banana): no brief,
    /// no questions, no review card - just edit and show, mirroring the seed-from-sample flow.
    private func enterReferenceMode(with imageData: Data) {
        inReferenceMode = true
        brief = nil; qr = nil; answers = [:]
        let b64 = imageData.base64EncodedString()
        currentReferenceB64 = b64
        // The upload is the starting point, not a generated result - show it as a plain image
        // (no Save/My Flyers/Resize); all editing happens via the composer.
        transcript.append(ChatBubble(.referenceImage(ConceptDTO(version_id: "reference-upload", image_base64: b64, error: nil))))
        transcript.append(ChatBubble(.assistant(
            "Here's your flyer. Tell me what to change — a name, a date, the wording — and I'll edit it while keeping the design.")))
    }

    /// Leave reuse-a-flyer mode so the composer starts a fresh flyer again.
    func startNewFlyer() {
        inReferenceMode = false; currentReferenceB64 = nil
        brief = nil; qr = nil; answers = [:]; composerText = ""
        transcript.append(ChatBubble(.assistant("Sure — describe a new flyer and I'll start fresh.")))
    }

    /// Once per flyer, surface the brain's photo suggestion (it names the subject) as a chat nudge.
    private func maybeNudgePhotos(_ b: ExtractedBriefDTO, typingID: UUID) {
        guard !photoNudged, attachedPhotos.isEmpty, generationPhotos.isEmpty,
              let msg = b.photo_suggestion, !msg.isEmpty else { return }
        photoNudged = true
        awaitingPhotoChoice = true                          // hold this turn's review until the user chooses
        let bubble = ChatBubble(.photoSuggestion(msg, false))
        photoSuggestionID = bubble.id
        insertBeforeTyping(bubble, typingID: typingID)
    }

    /// User tapped "No thanks" on the photo suggestion: acknowledge and reveal the held review.
    func declinePhotoSuggestion() {
        guard awaitingPhotoChoice else { return }
        transcript.append(ChatBubble(.user("No thanks")))
        resolvePhotoSuggestion()
    }

    /// User picked photo(s) from the suggestion: commit them (shown as a sent bubble, queued for
    /// generation) and reveal the held review.
    private func commitSuggestedPhotos() {
        guard !attachedPhotos.isEmpty else { return }
        let photos = attachedPhotos
        attachedPhotos = []; photoPickerItems = []
        generationPhotos.append(contentsOf: photos)
        transcript.append(ChatBubble(.userPhotos(photos)))
        let n = photos.count
        transcript.append(ChatBubble(.assistant(
            "Added \(n) photo\(n == 1 ? "" : "s") — I'll feature \(n == 1 ? "it" : "them") when we generate.")))
        resolvePhotoSuggestion()
    }

    /// Mark the suggestion answered (hides its choices) and reveal the held review card, once.
    private func resolvePhotoSuggestion() {
        awaitingPhotoChoice = false
        if let id = photoSuggestionID, let i = transcript.firstIndex(where: { $0.id == id }),
           case .photoSuggestion(let msg, _) = transcript[i].kind {
            transcript[i] = ChatBubble(.photoSuggestion(msg, true), id: id)
        }
        if let r = pendingReview { transcript.append(ChatBubble(.review(r))); pendingReview = nil }
    }

    // MARK: QR offer

    /// User tapped "Yes, add it" on the proactive QR offer. Enable the QR locally - it composites
    /// at the next generation because every request echoes `qr` - and mark the card answered. No
    /// engine round-trip and no quota cost; the paid step is the generation the QR rides on.
    func acceptQROffer(_ offer: QROfferDTO, bubbleID: UUID) {
        qr = QRSettingsDTO(enabled: true, kind: offer.kind, value: offer.value,
                           corner: offer.corner ?? "bottom_right")
        transcript.append(ChatBubble(.user("Yes, add the QR")))
        let target = offer.value.map { " that opens \($0)" } ?? ""
        transcript.append(ChatBubble(.assistant(
            "Done - I'll add a scannable QR\(target) to the flyer when you generate.")))
        resolveQROffer(bubbleID)
    }

    /// User declined. Record an explicit {enabled:false} (echoed next turn) so the brain sees a
    /// decision and never re-offers, and mark the card answered.
    func declineQROffer(_ offer: QROfferDTO, bubbleID: UUID) {
        qr = QRSettingsDTO(enabled: false, kind: offer.kind, value: offer.value, corner: offer.corner)
        transcript.append(ChatBubble(.user("No thanks")))
        resolveQROffer(bubbleID)
    }

    /// Flip the specific offer card to resolved so its Yes/No choices hide (message stays).
    private func resolveQROffer(_ bubbleID: UUID) {
        guard let i = transcript.firstIndex(where: { $0.id == bubbleID }),
              case .qrOffer(let offer, _) = transcript[i].kind else { return }
        transcript[i] = ChatBubble(.qrOffer(offer, resolved: true), id: bubbleID)
    }

    // MARK: Intents

    /// The first thing the user typed in this chat - the "prompt" worth saving to the library.
    var firstUserPrompt: String? {
        for bubble in transcript {
            if case .user(let text) = bubble.kind { return text }
        }
        return nil
    }

    /// True when closing the chat would destroy something costly: a generation in flight, or
    /// generated flyers that exist only in this transcript. Seeded "Starting point" cards don't
    /// count (the sample still lives in Explore); nothing here is persisted anywhere else.
    var hasUnsavedWork: Bool {
        if isStreaming { return true }
        return transcript.contains { bubble in
            if case .concepts(_, let heading) = bubble.kind, heading == nil { return true }
            return false
        }
    }

    /// Send is enabled when there's text to describe OR a photo to attach.
    var canSend: Bool {
        !isStreaming && (!composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         || !attachedPhotos.isEmpty)
    }

    /// True when the next `send()` calls the engine and therefore costs money: typed text runs
    /// either a reference edit (a paid image generation) or a describe turn (the gate + design
    /// brain LLM calls). The composer gates these on access like every other engine action.
    /// A photos-only send just commits photos to the tray locally, so it stays ungated.
    var sendReachesEngine: Bool {
        !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send() {
        guard !isStreaming else { return }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let photos = attachedPhotos
        guard !text.isEmpty || !photos.isEmpty else { return }

        // Reuse-a-flyer: the bottom composer edits the CURRENT flyer rather than starting a new one.
        // (It's the obvious input, so a typed change must edit here — otherwise it silently runs the
        // from-scratch describe flow, which is the "why is it asking me to approve 3 concepts?" bug.)
        if inReferenceMode, !text.isEmpty, let b64 = currentReferenceB64 {
            composerText = ""
            transcript.append(ChatBubble(.user(text)))
            run(ChatRequest(message: text, action: "reference", reference_image_b64: b64),
                thinking: "Editing your flyer…")
            return
        }

        // Commit attached photos to this flyer: show them as a sent bubble and queue them for
        // generation. They're held until the "Approve & generate" turn consumes them.
        if !photos.isEmpty {
            attachedPhotos = []; photoPickerItems = []
            generationPhotos.append(contentsOf: photos)
            transcript.append(ChatBubble(.userPhotos(photos)))
            let n = photos.count
            transcript.append(ChatBubble(.assistant(
                "Added \(n) photo\(n == 1 ? "" : "s") — I'll feature \(n == 1 ? "it" : "them") when we generate your concepts.")))
        }

        // Text describes a flyer, which starts a fresh one. Photos just committed carry into it.
        if !text.isEmpty {
            composerText = ""
            // Clearing here keeps the request's new-flyer semantics, but the old state must
            // survive a turn that dies before ANY event arrives - otherwise one network blip
            // converts a built-up brief (answers, QR choice, reference mode) into nothing.
            let (b, q, a, nudged, refMode) = (brief, qr, answers, photoNudged, inReferenceMode)
            restoreOnFailedTurn = { [weak self] in
                guard let self else { return }
                self.brief = b; self.qr = q; self.answers = a
                self.photoNudged = nudged; self.inReferenceMode = refMode
            }
            brief = nil; qr = nil; answers = [:]
            inReferenceMode = false                     // composing a new flyer leaves reuse-a-flyer mode
            photoNudged = !generationPhotos.isEmpty     // already have photos -> skip the nudge
            transcript.append(ChatBubble(.user(text)))
            run(ChatRequest(message: text, action: "describe"), thinking: "Reading your idea…")
        } else {
            photoNudged = true                          // photos sent on their own
        }
    }

    func submitAnswers(_ provided: [String: String], order: [String], stage: String, cardID: UUID) {
        let cleaned = provided.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !cleaned.isEmpty, !isStreaming else { return }
        answers.merge(cleaned) { _, new in new }
        // Summarize in the order the questions were asked — a [String: String] is unordered,
        // so mapping it directly would scramble the recap.
        let keys = order.filter { cleaned[$0] != nil } + cleaned.keys.filter { !order.contains($0) }.sorted()
        let summary = keys.compactMap { k in
            cleaned[k].map { "\(k.replacingOccurrences(of: "_", with: " ")): \($0)" }
        }.joined(separator: ", ")
        transcript.append(ChatBubble(.user(summary)))
        inFlightCardID = cardID                     // resolved on success, re-enabled on failure
        let isDesign = stage == "design"
        run(ChatRequest(action: "answers", stage: isDesign ? "design" : nil, brief: brief, answers: cleaned),
            thinking: isDesign ? "Finalizing…" : "Designing…")
    }

    func approve(fieldOverrides: [String: String], decisionOverrides: [String: String],
                 selectedElements: [String]?, cardID: UUID) {
        guard !isStreaming else { return }
        // Everything committed via send, plus anything still staged in the tray.
        let photos = (generationPhotos + attachedPhotos).map { $0.base64EncodedString() }
        let label = photos.isEmpty ? "Looks good — generate concepts."
            : "Looks good — generate concepts (with \(photos.count) photo\(photos.count == 1 ? "" : "s"))."
        transcript.append(ChatBubble(.user(label)))
        inFlightCardID = cardID                     // resolved on success, re-enabled on failure
        // Photos stay staged until the turn SUCCEEDS (cleared in the concepts success branch):
        // clearing here made a failed approve lose them with no way to re-attach.
        clearPhotosOnSuccess = true
        // selectedElements: nil => no creative ideas were offered (engine uses its safe defaults);
        // [] => offered but user turned them all off; [..] => the exact elements to include.
        run(ChatRequest(action: "approve", brief: brief, answers: answers,
                        field_overrides: fieldOverrides.isEmpty ? nil : fieldOverrides,
                        decision_overrides: decisionOverrides.isEmpty ? nil : decisionOverrides,
                        user_photos_b64: photos.isEmpty ? nil : photos,
                        selected_elements: selectedElements),
            thinking: "Generating 3 concepts — about a minute…")
    }

    func refine(concept: ConceptDTO, instruction: String) {
        guard let b64 = concept.image_base64, !isStreaming else { return }
        if inReferenceMode {
            // Reuse-a-flyer: edit the uploaded flyer in place from the user's own words. The image
            // being edited is the concept under which they typed, so each edit builds on the last.
            transcript.append(ChatBubble(.user(instruction)))
            run(ChatRequest(message: instruction, action: "reference", reference_image_b64: b64),
                thinking: "Editing your flyer…")
        } else {
            transcript.append(ChatBubble(.user("Refine: \(instruction)")))
            run(ChatRequest(action: "refine", brief: brief, instruction: instruction, prior_image_b64: b64),
                thinking: "Refining…")
        }
    }

    func resize(concept: ConceptDTO, aspect: AspectRatio) {
        guard let b64 = concept.image_base64, !isStreaming else { return }
        transcript.append(ChatBubble(.user("Resize to \(aspect.displayName).")))
        run(ChatRequest(action: "resize", brief: brief, prior_image_b64: b64, aspect_ratio: aspect.rawValue), thinking: "Reformatting…")
    }

    // MARK: Annotate to edit

    /// Open the full-screen annotation editor on a card's image. The caller gates on quota first
    /// (opening leads to a paid generation on Apply).
    func beginAnnotation(on imageData: Data) {
        guard !isStreaming else { return }
        annotationEditor = AnnotationEditorRequest(imageData: imageData)
    }

    /// Dispatch a marked-up edit from the annotation editor. `marked` carries the numbered circles
    /// (it's what we SEND); `instruction` is the numbered list. Reuse mode edits via the `reference`
    /// action, a generated result via `refine`; `annotated` is set only when circles were drawn (a
    /// whole-flyer-note-only edit is an ordinary edit). The draft is retained so a failed turn can
    /// reopen the editor with everything intact.
    func applyAnnotatedEdit(marked: Data, instruction: String, annotated: Bool, draft: AnnotationDraft) {
        guard !isStreaming else { return }
        annotationEditor = nil
        pendingAnnotationDraft = draft
        let b64 = marked.base64EncodedString()
        transcript.append(ChatBubble(.userPhotos([marked])))          // thumbnail of what we sent
        if !instruction.isEmpty { transcript.append(ChatBubble(.user(instruction))) }
        if inReferenceMode {
            run(ChatRequest(message: instruction, action: "reference", reference_image_b64: b64, annotated: annotated),
                thinking: "Editing your flyer…")
        } else {
            run(ChatRequest(action: "refine", brief: brief, instruction: instruction, prior_image_b64: b64, annotated: annotated),
                thinking: "Applying your edits…")
        }
    }

    /// On a failed marked-up edit, reopen the editor seeded with the same circles + notes so the
    /// user can reword and resend without redrawing.
    private func reopenAnnotationIfPending() {
        guard let draft = pendingAnnotationDraft else { return }
        pendingAnnotationDraft = nil
        annotationEditor = AnnotationEditorRequest(imageData: draft.sourceImageData, seed: draft)
    }

    /// Maps the current brief into a FlyerProject so a chat concept can be saved into My Flyers.
    /// Colors/visuals/output keep defaults (the engine chose the real look server-side and we
    /// didn't capture it); `origin = .chat` lets the gallery hide "Use as Template". Returns nil
    /// only before any brief is parsed — concepts always follow one, so in practice it's set.
    func chatFlyerProject() -> FlyerProject? {
        let category = brief?.category.flatMap { FlyerCategory(rawValue: $0) } ?? .announcement
        var project = FlyerProject(category: category, language: selectedLanguage)
        project.origin = .chat
        // A reused/edited flyer has no brief (its content lives in the image itself); save it with a
        // minimal project so the edited image still lands in My Flyers.
        guard let brief = brief else { return project }
        var text = TextContent()
        text.headline = brief.headline ?? ""
        text.subheadline = brief.subheadline
        text.bodyText = brief.body_text
        text.date = brief.date
        text.time = brief.time
        text.venueName = brief.venue_name
        text.address = brief.address
        text.price = brief.price
        text.discountText = brief.discount_text
        text.ctaText = brief.cta_text
        text.phone = brief.phone
        text.email = brief.email
        text.website = brief.website
        text.socialHandle = brief.social_handle
        text.additionalInfo = brief.additional_info
        project.textContent = text
        if let purpose = brief.purpose, !purpose.isEmpty { project.specialInstructions = purpose }
        return project
    }

    // MARK: Streaming

    /// Shown when a generation returns no image (the model failed or declined) - a friendly,
    /// actionable line instead of the raw "No image in response" on a broken concept card. No quota
    /// is consumed and the current reference image is unchanged, so a retry is clean.
    private static let generationFailedMessage =
        "That one didn't go through — the image didn't come back. Mind trying again? Rewording the change can help."

    /// Shown when a stream ends cleanly but delivered nothing decodable - without this the
    /// spinner just vanished, leaving no way to know whether anything generated or was charged.
    private static let emptyTurnMessage =
        "Nothing came back for that one — the connection ended early. Mind trying again?"

    private func run(_ request: ChatRequest, thinking: String) {
        var request = request
        request.language = selectedLanguage.rawValue          // every request carries the session language
        request.qr = qr                                       // echo QR state on every action (incl. reference)
        isStreaming = true
        turnHadError = false
        awaitingPhotoChoice = false; pendingReview = nil     // each turn starts un-gated
        let typing = ChatBubble(.typing(thinking))
        transcript.append(typing)               // pinned at the bottom until the turn ends
        Task {
            var sawEvent = false
            do {
                for try await event in client.stream(request) {
                    sawEvent = true
                    restoreOnFailedTurn = nil       // the engine answered; the new state owns from here
                    apply(event, typingID: typing.id)
                }
            } catch {
                turnHadError = true
                insertBeforeTyping(ChatBubble(.error(error.localizedDescription)), typingID: typing.id)
                reopenAnnotationIfPending()
            }
            if !sawEvent && !turnHadError {         // clean stream, zero events: surface it
                turnHadError = true
                insertBeforeTyping(ChatBubble(.error(Self.emptyTurnMessage)), typingID: typing.id)
                reopenAnnotationIfPending()
            }
            if !sawEvent { restoreOnFailedTurn?() } // the turn died whole: put the pre-send state back
            restoreOnFailedTurn = nil
            if let card = inFlightCardID {          // success latches the card; failure re-enables it
                if !turnHadError { resolvedCardIDs.insert(card) }
                inFlightCardID = nil
            }
            clearPhotosOnSuccess = false
            removeTyping(typing.id)
            isStreaming = false
        }
    }

    private func apply(_ event: SSEEvent, typingID: UUID) {
        switch event {
        case .parsedFields(let b):
            brief = b
            insertBeforeTyping(ChatBubble(.parsedFields(b)), typingID: typingID)
            maybeNudgePhotos(b, typingID: typingID)
        case .briefState(let b):
            brief = b               // the approved design riding the brief; stored silently, no bubble
        case .questions(let qs, let stage): insertBeforeTyping(ChatBubble(.questions(qs, stage)), typingID: typingID)
        case .designBrief(let d):  insertBeforeTyping(ChatBubble(.designBrief(d)), typingID: typingID)
        case .review(let r):
            if awaitingPhotoChoice { pendingReview = r }         // hold until the user answers the photo suggestion
            else { insertBeforeTyping(ChatBubble(.review(r)), typingID: typingID) }
        case .concepts(let cs):
            if let img = cs.first(where: { $0.image_base64 != nil })?.image_base64 {
                insertBeforeTyping(ChatBubble(.concepts(cs, heading: nil)), typingID: typingID)
                if inReferenceMode { currentReferenceB64 = img }   // the next composer edit builds on this result
                pendingAnnotationDraft = nil                       // a marked-up edit (if any) succeeded
                if clearPhotosOnSuccess {                          // the approve turn's photos are now in the flyer
                    generationPhotos = []; attachedPhotos = []; photoPickerItems = []
                    clearPhotosOnSuccess = false
                }
                onCreditDeduction?()                               // 1 unit per successful create (3 concepts = 1)
            } else {
                turnHadError = true                                // keep the review card retryable
                insertBeforeTyping(ChatBubble(.error(Self.generationFailedMessage)), typingID: typingID)
                reopenAnnotationIfPending()                        // bring the circles back to reword & retry
            }
        case .refined(let c), .resized(let c):
            if c.image_base64 != nil {
                insertBeforeTyping(ChatBubble(.concepts([c], heading: nil)), typingID: typingID)
                if inReferenceMode { currentReferenceB64 = c.image_base64 }  // resize/refine stays in the edit chain
                pendingAnnotationDraft = nil                       // a marked-up edit (if any) succeeded
                onCreditDeduction?()                               // 1 unit per successful refine/resize
            } else {
                turnHadError = true
                insertBeforeTyping(ChatBubble(.error(Self.generationFailedMessage)), typingID: typingID)
                reopenAnnotationIfPending()                        // bring the circles back to reword & retry
            }
        case .qr(let dto):         qr = dto                    // store latest QR state; no UI, echoed next turn
        case .qrOffer(let dto):    insertBeforeTyping(ChatBubble(.qrOffer(dto, resolved: false)), typingID: typingID)
        case .note(let t):         insertBeforeTyping(ChatBubble(.assistant(t)), typingID: typingID)
        case .error(let msg):
            turnHadError = true                                // an error event fails the turn's card, too
            insertBeforeTyping(ChatBubble(.error(msg)), typingID: typingID)
            reopenAnnotationIfPending()
        case .unknown: break
        }
    }

    private func insertBeforeTyping(_ bubble: ChatBubble, typingID: UUID) {
        if let i = transcript.firstIndex(where: { $0.id == typingID }) { transcript.insert(bubble, at: i) }
        else { transcript.append(bubble) }
    }
    private func removeTyping(_ id: UUID) { transcript.removeAll { $0.id == id } }
}
