import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct FlyerChatView: View {
    /// When present, the chat opens seeded with this Explore flyer to refine (see `start(seed:)`).
    let seed: SampleFlyer?
    /// When present, the composer opens pre-filled with this text (editable, not auto-sent).
    let prefillText: String?
    init(seed: SampleFlyer? = nil, prefillText: String? = nil) {
        self.seed = seed
        self.prefillText = prefillText
    }

    @StateObject private var vm = FlyerChatViewModel()
    @EnvironmentObject private var entitlementService: EntitlementService
    @EnvironmentObject private var cloudKitService: CloudKitService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var didApplyPrefill = false
    @State private var didSeedLanguage = false        // seed the session language from the profile once
    @State private var showingSavePrompt = false
    @State private var showingPaywall = false
    @State private var showingCloseConfirm = false    // Close sits where Back lives; confirm before losing work
    @State private var showMyFlyersPicker = false     // "reuse a flyer" -> pick from My Flyers
    @State private var showExplorePicker = false      // "reuse a flyer" -> pick from Explore

    /// Stable identity for the invisible end-of-thread marker the chat auto-scrolls to.
    private static let chatBottomID = "chat-bottom"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: FGSpacing.md) {
                            ForEach(vm.transcript) { bubble in
                                bubbleView(bubble).id(bubble.id)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            // Invisible end-of-thread marker we auto-scroll to. A 1pt view is
                            // laid out instantly, unlike a tall just-appended bubble whose height
                            // is still being measured, so scrolling here lands on the true bottom.
                            Color.clear.frame(height: 1).id(Self.chatBottomID)
                        }
                        .padding(FGSpacing.screenHorizontal)
                    }
                    .onChange(of: vm.transcript.count) { _, _ in
                        // Defer one runloop tick so the LazyVStack has laid out the freshly
                        // appended bubbles (and re-rendered the tall review card into its approved
                        // state) before we compute the scroll offset. Scrolling in the same tick
                        // uses stale/estimated heights and overshoots past the content into blank
                        // space — the "Approve & generate jumps to a blank, then I scroll up to
                        // find the progress" bug.
                        DispatchQueue.main.async {
                            withAnimation { proxy.scrollTo(Self.chatBottomID, anchor: .bottom) }
                        }
                    }
                }
                composer
            }
            .background(FGColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // The transcript is this chat's only state, so one mis-tap here (top-left,
                    // exactly where Back lives) used to destroy paid concepts silently.
                    Button("Close") {
                        if vm.hasUnsavedWork { showingCloseConfirm = true } else { dismiss() }
                    }.foregroundColor(FGColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSavePrompt = true } label: { Image(systemName: "bookmark") }
                        .foregroundColor(FGColors.textSecondary)
                        .disabled(vm.firstUserPrompt == nil)
                }
            }
            .onAppear {
                vm.start(seed: seed)
                if !didSeedLanguage {           // seed once; the review-card row owns it afterward
                    vm.selectedLanguage = userProfiles.first?.defaultFlyerLanguageEnum ?? .english
                    didSeedLanguage = true
                }
                if !didApplyPrefill, let prefillText, vm.composerText.isEmpty {
                    vm.composerText = prefillText
                    didApplyPrefill = true
                }
                // Consume one quota unit after each successful generation (mirrors ResultView).
                vm.onCreditDeduction = { consumeOneGeneration() }
            }
            .confirmationDialog("Close this chat?", isPresented: $showingCloseConfirm, titleVisibility: .visible) {
                Button("Close anyway", role: .destructive) { dismiss() }
                Button("Keep working", role: .cancel) {}
            } message: {
                Text("This chat isn't saved — flyers you haven't added to My Flyers will be lost.")
            }
            .sheet(isPresented: $showingSavePrompt) {
                PromptEditorSheet(initialText: vm.firstUserPrompt ?? "")
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionPaywallView()
            }
            .sheet(isPresented: $showMyFlyersPicker) {
                MyFlyersReferencePicker { vm.useReference(imageData: $0) }
            }
            .sheet(isPresented: $showExplorePicker) {
                ExploreReferencePicker { vm.useReference(imageData: $0) }
            }
            .fullScreenCover(item: $vm.annotationEditor) { req in
                FlyerAnnotationView(
                    request: req,
                    onApply: { marked, instruction, annotated, draft in
                        vm.applyAnnotatedEdit(marked: marked, instruction: instruction, annotated: annotated, draft: draft)
                    },
                    onCancel: { vm.annotationEditor = nil }
                )
            }
        }
    }

    /// The most recent "Here's what I got" card — only it stays expanded; older ones collapse.
    private var latestParsedFieldsID: UUID? {
        vm.transcript.last { if case .parsedFields = $0.kind { return true } else { return false } }?.id
    }

    /// True when the user has neither subscription quota nor legacy credits left, so a generation
    /// must open the paywall instead. No profile yet -> not blocked (mirrors the wizard's `if let` gate).
    /// Unresolved entitlements -> not blocked either: on a cold launch StoreKit hasn't answered yet,
    /// and "unknown" must never read as "not subscribed" - a paying user was being shown the paywall.
    private var isGenerationBlocked: Bool {
        guard entitlementService.entitlementsResolved else { return false }
        guard let profile = userProfiles.first else { return false }
        return entitlementService.access(for: profile) == .blocked
    }

    /// Run an engine-reaching action only if the user can generate; otherwise open the paywall.
    /// Every chat turn costs money (LLM brain calls or image generation), so ALL of them gate:
    /// text sends, question answers, refine/resize/mark-up. The review card's approve button
    /// gates the same way via `isBlocked`/`onBlocked`.
    private func gated(_ action: () -> Void) {
        if isGenerationBlocked { showingPaywall = true } else { action() }
    }

    /// Consume one quota unit after a successful generation (mirrors ResultView.onCreditDeduction).
    private func consumeOneGeneration() {
        guard let profile = userProfiles.first else { return }
        Task { await entitlementService.consume(for: profile, context: modelContext, cloudKit: cloudKitService) }
    }

    @ViewBuilder
    private func bubbleView(_ bubble: ChatBubble) -> some View {
        switch bubble.kind {
        case .user(let t):        UserBubble(text: t)
        case .userPhotos(let p):  UserPhotosBubble(photos: p)
        case .assistant(let t):   AssistantBubble(text: t)
        case .photoSuggestion(let t, let resolved): PhotoSuggestionBubble(text: t, selection: $vm.photoPickerItems, disabled: vm.isStreaming, resolved: resolved, onDecline: { vm.declinePhotoSuggestion() })
        case .qrOffer(let dto, let resolved): QROfferBubble(offer: dto, disabled: vm.isStreaming, resolved: resolved,
                                                  onAccept: { vm.acceptQROffer(dto, bubbleID: bubble.id) },
                                                  onDecline: { vm.declineQROffer(dto, bubbleID: bubble.id) })
        case .referenceNudge:     ReferenceUploadBubble(selection: $vm.referencePickerItems, disabled: vm.isStreaming,
                                      onMyFlyers: { showMyFlyersPicker = true }, onExplore: { showExplorePicker = true },
                                      onDismiss: { vm.dismissReferenceNudge() })
        case .typing(let t):      TypingBubble(text: t)
        case .parsedFields(let b): ParsedFieldsCard(brief: b, expanded: bubble.id == latestParsedFieldsID)
        case .questions(let qs, let stage):  QuestionsCard(questions: qs,
                                      pending: vm.inFlightCardID == bubble.id,
                                      resolved: vm.resolvedCardIDs.contains(bubble.id),
                                      isBlocked: isGenerationBlocked,
                                      onBlocked: { showingPaywall = true },
                                      onSubmit: { answers, order in
                                          vm.submitAnswers(answers, order: order, stage: stage, cardID: bubble.id) })
        case .designBrief(let d): DesignNotesCard(brief: d)
        case .review(let r):      ReviewCard(review: r, language: $vm.selectedLanguage,
                                      pending: vm.inFlightCardID == bubble.id,
                                      resolved: vm.resolvedCardIDs.contains(bubble.id),
                                      isBlocked: isGenerationBlocked,
                                      onBlocked: { showingPaywall = true },
                                      onApprove: { vm.approve(fieldOverrides: $0, decisionOverrides: $1,
                                                              selectedElements: $2, cardID: bubble.id) })
        case .referenceImage(let c):  ReferenceImageCard(concept: c,
                                      onMarkUp: { d in gated { vm.beginAnnotation(on: d) } })
        case .concepts(let cs, let heading):   ConceptsCard(concepts: cs, heading: heading,
                                      onRefine: { c, t in gated { vm.refine(concept: c, instruction: t) } },
                                      onResize: { c, ar in gated { vm.resize(concept: c, aspect: ar) } },
                                      onAddToMyFlyers: { addToMyFlyers($0) },
                                      onMarkUp: { c in gated { if let d = c.imageData { vm.beginAnnotation(on: d) } } })
        case .error(let m):       ErrorBubble(text: m)
        }
    }

    /// Persist a chat concept into My Flyers (a SavedFlyer) so it appears in the Gallery tab
    /// and syncs via iCloud, alongside classic flyers.
    private func addToMyFlyers(_ concept: ConceptDTO) {
        guard let imageData = concept.imageData, let project = vm.chatFlyerProject() else { return }
        let generated = GeneratedFlyer(projectId: project.id, imageData: imageData,
                                       prompt: "", negativePrompt: "", model: "")
        modelContext.insert(SavedFlyer(project: project, generatedFlyer: generated))
        try? modelContext.save()
    }

    private var composer: some View {
        VStack(spacing: FGSpacing.xs) {
            if vm.inReferenceMode {
                HStack {
                    Label("Editing your flyer", systemImage: "pencil")
                        .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                    Spacer()
                    Button("New flyer") { vm.startNewFlyer() }
                        .font(FGTypography.caption).foregroundColor(FGColors.accentSecondary)
                }
                .padding(.horizontal, FGSpacing.xxs)
            }
            if !vm.attachedPhotos.isEmpty { photoStrip }
            HStack(alignment: .bottom, spacing: FGSpacing.sm) {
                // Grows up to ~8 lines, then scrolls with an always-visible scroll thumb so the
                // whole paste stays reachable and editable. Backed by a UITextView because a plain
                // SwiftUI TextField/TextEditor exposes no persistent scroll indicator (see below).
                GrowingScrollTextEditor(
                    text: $vm.composerText,
                    placeholder: vm.inReferenceMode ? "Tell me what to change…" : "Describe a flyer (starts a new one)…",
                    isEnabled: !vm.isStreaming
                )
                .background(FGColors.surfaceDefault)
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                Button {
                    // Any text send reaches the engine (a paid image edit in reference mode, LLM
                    // brain calls otherwise), so it gates on access like refine/resize. A
                    // photos-only send is a free local commit and stays ungated.
                    if vm.sendReachesEngine { gated { vm.send() } } else { vm.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                        .foregroundColor(vm.canSend ? FGColors.accentPrimary : FGColors.textTertiary)
                }
                .disabled(!vm.canSend)
            }
        }
        .padding(FGSpacing.sm)
        .background(
            FGColors.backgroundSecondary
                .overlay(alignment: .top) { Rectangle().fill(FGColors.borderHairline).frame(height: 1) }
        )
        // Loads whatever the composer strip or the in-chat photo-suggestion picker selects.
        .onChange(of: vm.photoPickerItems) { _, _ in Task { await vm.loadAttachedPhotos() } }
        // Loads a flyer picked from the "reuse a flyer" nudge and enters reference-edit mode.
        .onChange(of: vm.referencePickerItems) { _, _ in Task { await vm.loadReference() } }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FGSpacing.xs) {
                ForEach(Array(vm.attachedPhotos.enumerated()), id: \.offset) { idx, data in
                    if let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                            .overlay(alignment: .topTrailing) {
                                Button { vm.removePhoto(at: idx) } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(2)
                            }
                    }
                }
            }
            .padding(.horizontal, FGSpacing.xxs)
        }
        .frame(height: 56)
    }
}

// MARK: - Small bubbles
// UserBubble, AssistantBubble, and TypingBubble live in Chat/ChatBubbleViews.swift so the
// onboarding demo can reuse the exact same styling.

private struct UserPhotosBubble: View {
    let photos: [Data]
    var body: some View {
        HStack { Spacer(minLength: FGSpacing.xl)
            HStack(spacing: FGSpacing.xs) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                    if let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                    }
                }
            }
        }
    }
}
/// The brain's proactive "add a photo of X" nudge, rendered as a distinct accent-tinted bubble
/// with an inline picker - so it reads as its own message and is one tap to act on. This is the
/// only photo entry point now that the composer's picker button is hidden.
private struct PhotoSuggestionBubble: View {
    let text: String
    @Binding var selection: [PhotosPickerItem]
    var disabled: Bool
    var resolved: Bool                 // once the user has added a photo or declined, hide "No thanks"
    var onDecline: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                Image(systemName: "camera.fill").font(.system(size: 16))
                    .foregroundColor(FGColors.accentSecondary).padding(.top, 2)
                Text(text).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: FGSpacing.sm) {
                PhotosPicker(selection: $selection, maxSelectionCount: nil, matching: .images) {
                    Label("Add a photo", systemImage: "plus").font(FGTypography.button)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                        .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                }
                .disabled(disabled)
                if !resolved {
                    Button(action: onDecline) {
                        Text("No thanks").fgDismissButtonStyle()
                    }
                    .disabled(disabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.md)
        .background(FGColors.accentSecondary.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.accentSecondary.opacity(0.35), lineWidth: 1))
    }
}
/// The engine's proactive "add a scannable QR?" offer, rendered like the photo nudge: an
/// accent-tinted card with the offer line and one-tap Yes / No thanks. "Yes" sets the QR state
/// locally (it composites at the next generation, which is where the paid step already is); "No
/// thanks" records a decline so it's never re-offered. Choices hide once resolved.
private struct QROfferBubble: View {
    let offer: QROfferDTO
    var disabled: Bool
    var resolved: Bool
    var onAccept: () -> Void
    var onDecline: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                Image(systemName: "qrcode").font(.system(size: 16))
                    .foregroundColor(FGColors.accentSecondary).padding(.top, 2)
                Text(offer.text).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !resolved {
                HStack(spacing: FGSpacing.sm) {
                    Button(action: onAccept) {
                        Label("Yes, add it", systemImage: "checkmark").font(FGTypography.button)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                            .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                    .disabled(disabled)
                    Button(action: onDecline) {
                        Text("No thanks").fgDismissButtonStyle()
                    }
                    .disabled(disabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.md)
        .background(FGColors.accentSecondary.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.accentSecondary.opacity(0.35), lineWidth: 1))
    }
}
/// The "reuse a flyer you already have" nudge: pick a flyer from Photos, My Flyers, or Explore.
/// Any choice enters reference-edit mode (the flyer becomes the current image to edit under).
private struct ReferenceUploadBubble: View {
    @Binding var selection: [PhotosPickerItem]
    var disabled: Bool
    var onMyFlyers: () -> Void
    var onExplore: () -> Void
    var onDismiss: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                Image(systemName: "doc.on.doc.fill").font(.system(size: 16))
                    .foregroundColor(FGColors.accentSecondary).padding(.top, 2)
                Text("Already have a flyer you like? Pick one to edit — I'll keep the design and change whatever you want.")
                    .font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: FGSpacing.sm) {
                PhotosPicker(selection: $selection, maxSelectionCount: 1, matching: .images) {
                    sourceLabel("Photos", "photo")
                }.disabled(disabled)
                Button(action: onMyFlyers) { sourceLabel("My Flyers", "folder") }.disabled(disabled)
                Button(action: onExplore) { sourceLabel("Explore", "sparkles") }.disabled(disabled)
            }
            Button(action: onDismiss) {
                Text("No thanks").fgDismissButtonStyle()
            }
            .disabled(disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.md)
        .background(FGColors.accentSecondary.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.accentSecondary.opacity(0.35), lineWidth: 1))
    }
    @ViewBuilder private func sourceLabel(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 15))
            Text(title).font(FGTypography.captionBold).lineLimit(1).minimumScaleFactor(0.75)
        }
        .foregroundColor(FGColors.textOnAccent)
        .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
        .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
    }
}

extension View {
    /// Crisp outlined style for the tertiary "No thanks" / dismiss action in chat nudge cards.
    /// Reads as an intentional secondary button beside the solid accent choices, instead of the
    /// dull gray-on-gray fill it replaced. Shared by both nudge cards so they stay consistent.
    func fgDismissButtonStyle() -> some View {
        self
            .font(FGTypography.button)
            .foregroundColor(FGColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                    .stroke(FGColors.borderDefault, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
    }
}

/// Pick one of the user's saved flyers as the reference to edit. Minimal grid of thumbnails;
/// on tap, resolve the image `Data` and hand it to reference-edit mode.
private struct MyFlyersReferencePicker: View {
    @Query(sort: \SavedFlyer.createdAt, order: .reverse) private var savedFlyers: [SavedFlyer]
    let onPick: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 108), spacing: FGSpacing.sm)]
    var body: some View {
        NavigationStack {
            ScrollView {
                if savedFlyers.isEmpty {
                    Text("You haven't saved any flyers yet. Create one first, then you can reuse its design here.")
                        .font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                        .multilineTextAlignment(.center).padding(FGSpacing.xl)
                } else {
                    LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                        ForEach(savedFlyers) { flyer in
                            if let data = flyer.imageData, let ui = UIImage(data: data) {
                                Button { onPick(data); dismiss() } label: {
                                    Image(uiImage: ui).resizable().scaledToFill()
                                        .frame(height: 150).frame(maxWidth: .infinity).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                                }
                            }
                        }
                    }
                    .padding(FGSpacing.md)
                }
            }
            .background(FGColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("My Flyers").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

/// Pick an Explore sample as the reference to edit. Renders each bundled asset to JPEG on tap.
private struct ExploreReferencePicker: View {
    let onPick: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 108), spacing: FGSpacing.sm)]
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: FGSpacing.sm) {
                    ForEach(SampleLibrary.samples) { sample in
                        if let ui = UIImage(named: sample.imageName) {
                            Button {
                                if let data = ui.jpegData(compressionQuality: 0.9) { onPick(data); dismiss() }
                            } label: {
                                Image(uiImage: ui).resizable().scaledToFill()
                                    .frame(height: 150).frame(maxWidth: .infinity).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                            }
                        }
                    }
                }
                .padding(FGSpacing.md)
            }
            .background(FGColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Explore").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}
private struct ErrorBubble: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(FGColors.error)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
        }
        .padding(FGSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColors.error.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
    }
}

// MARK: - Shared pieces

private struct AssistantCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FGSpacing.md)
            .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.borderSubtle, lineWidth: 1))
    }
}
private struct SourceBadge: View {
    let source: String
    var body: some View {
        let stated = source == "stated"
        Text(source.uppercased()).font(FGTypography.captionSmall)
            .foregroundColor(stated ? FGColors.success : FGColors.warning)
            .padding(.horizontal, FGSpacing.xs).padding(.vertical, 2)
            .background((stated ? FGColors.success : FGColors.warning).opacity(0.15)).clipShape(Capsule())
    }
}

// MARK: - Cards

private struct ParsedFieldsCard: View {
    let brief: ExtractedBriefDTO
    var expanded: Bool = true
    @State private var userToggled: Bool? = nil   // follows `expanded` until the user overrides
    var body: some View {
        AssistantCard {
            DisclosureGroup(isExpanded: Binding(get: { userToggled ?? expanded },
                                                set: { userToggled = $0 })) {
                // Identity must be positional: every additional_info row shares the key "extra",
                // and duplicate ForEach IDs make SwiftUI render the first row's content for all
                // of them (the "Ladies only x3" bug - the payload itself was distinct).
                ForEach(Array(brief.displayFields.enumerated()), id: \.offset) { _, f in
                    HStack(alignment: .top, spacing: FGSpacing.xs) {
                        Text(f.key.replacingOccurrences(of: "_", with: " "))
                            .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                            .frame(width: 92, alignment: .leading)
                        Text(prettyValue(f.key, f.value)).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SourceBadge(source: f.source)
                    }
                }
                .padding(.top, FGSpacing.xs)
            } label: {
                Text("Here's what I got").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            }.tint(FGColors.accentSecondary)
        }
    }
    /// Category arrives as a raw enum value ("church_religious"); show its canonical display name
    /// ("Church & Faith") - the same one the review card uses - so the two cards never disagree.
    private func prettyValue(_ key: String, _ value: String) -> String {
        guard key == "category" else { return value }
        if let category = FlyerCategory(rawValue: value) { return category.displayName }
        return value.split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

private struct QuestionsCard: View {
    let questions: [QuestionDTO]
    // The latch lives in the view model now (resolved on SUCCESS only), so a network blip,
    // paywall hit, or empty tap no longer bricks the card - the old `submitted = true` before
    // dispatch was permanent, with no path back after a failure.
    var pending: Bool = false                  // this card's turn is in flight
    var resolved: Bool = false                 // this card's turn succeeded; stays disabled
    var isBlocked: Bool = false                // no quota/credits -> submit opens the paywall instead
    var onBlocked: () -> Void = {}
    let onSubmit: ([String: String], [String]) -> Void
    @State private var answers: [String: String] = [:]
    private var locked: Bool { pending || resolved }
    /// At least one non-empty answer - the button stays disabled otherwise, because an empty
    /// submit sends nothing (and used to latch the card dead).
    private var hasAnswer: Bool {
        answers.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    private var heading: String {
        switch questions.count {
        case 1:  return "One quick thing"
        case 2:  return "A couple of quick questions"
        default: return "A few quick questions"
        }
    }
    var body: some View {
        AssistantCard {
            Text(heading).font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(questions) { q in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(q.text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                    if let opts = q.options, !opts.isEmpty {
                        choicePicker(q.field, opts)          // labeled picker (e.g. size)
                    } else {
                        TextField("Your answer", text: Binding(get: { answers[q.field] ?? "" }, set: { answers[q.field] = $0 }))
                            .textFieldStyle(.plain).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                            .disabled(locked)
                    }
                }
            }
            Button {
                if isBlocked { onBlocked(); return }   // paywall first; the card stays live to retry after subscribing
                onSubmit(answers, questions.map { $0.field })
            } label: {
                Text("Send answers").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(locked || !hasAnswer)
        }
        .onAppear {
            // Pre-select each picker's default (first option) so the size is sent even untouched.
            for q in questions where !(q.options ?? []).isEmpty {
                if answers[q.field] == nil { answers[q.field] = q.options?.first?.value }
            }
        }
    }

    @ViewBuilder
    private func choicePicker(_ field: String, _ opts: [FormatOptionDTO]) -> some View {
        let current = answers[field] ?? opts.first?.value ?? ""
        Menu {
            ForEach(opts, id: \.value) { opt in Button(opt.label) { answers[field] = opt.value } }
        } label: {
            HStack {
                Text(opts.first(where: { $0.value == current })?.label ?? current)
                    .font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
            }
            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
        }
        .disabled(locked)
    }
}

private struct DesignNotesCard: View {
    let brief: DesignBriefDTO
    var body: some View {
        AssistantCard {
            if !brief.notes.isEmpty {
                Text(brief.notes).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
            }
            DisclosureGroup {
                if !brief.checklist.isEmpty {
                    Text("Checklist").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary).padding(.top, FGSpacing.xs)
                    ForEach(brief.checklist, id: \.self) { bullet($0, "checkmark.circle") }
                }
                if !brief.recommendations.isEmpty {
                    Text("Recommendations").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary).padding(.top, FGSpacing.xs)
                    ForEach(brief.recommendations, id: \.self) { bullet($0, "lightbulb") }
                }
            } label: {
                Text("Design notes").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            }.tint(FGColors.accentSecondary)
        }
    }
    @ViewBuilder private func bullet(_ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(FGColors.accentSecondary).padding(.top, 2)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ReviewCard: View {
    let review: ReviewProposalDTO
    @Binding var language: FlyerLanguage    // the flyer's render language; declared here, sticky across edits
    // The latch lives in the view model (resolved on SUCCESS only): a failed approve turn
    // re-enables the card instead of leaving it permanently dead mid-edit.
    var pending: Bool = false               // this card's approve turn is in flight
    var resolved: Bool = false              // this card's turn succeeded; stays disabled
    var isBlocked: Bool = false             // no quota/credits -> approve opens the paywall instead
    var onBlocked: () -> Void = {}
    let onApprove: (_ fieldOverrides: [String: String], _ decisionOverrides: [String: String], _ selectedElements: [String]?) -> Void
    @State private var fieldValues: [String: String] = [:]
    @State private var decisionValues: [String: String] = [:]
    @State private var elementSelected: [String: Bool] = [:]
    private var locked: Bool { pending || resolved }
    var body: some View {
        AssistantCard {
            Text("Review before I generate").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(review.fields) { f in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack { Text(f.key.replacingOccurrences(of: "_", with: " "))
                        .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                        Spacer(); SourceBadge(source: f.source) }
                    // Grows with the value and scrolls (with the always-visible thumb) once it's
                    // long - the body field especially runs well past a single line.
                    GrowingScrollTextEditor(
                        text: Binding(get: { fieldValues[f.key] ?? f.value }, set: { fieldValues[f.key] = $0 }),
                        placeholder: "",
                        isEnabled: !locked,
                        fontSize: 13,           // FGTypography.bodySmall
                        insetH: FGSpacing.sm,
                        insetV: FGSpacing.xs,
                        maxLines: 6
                    )
                    .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    .overlay(RoundedRectangle(cornerRadius: FGSpacing.inputRadius)   // amber outline when flagged
                        .stroke(FGColors.warning, lineWidth: f.warning == nil ? 0 : 1))
                    if let w = f.warning { warningLine(w) }   // the value needs attention (e.g. a malformed URL)
                }
            }
            Divider().background(FGColors.borderSubtle)
            ForEach(review.decisions) { d in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(d.label).font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                    Menu {
                        ForEach(d.options, id: \.self) { opt in
                            Button(d.option_labels?[opt] ?? opt) { decisionValues[d.key] = opt }
                        }
                    } label: {
                        HStack {
                            let cur = decisionValues[d.key] ?? d.value
                            Text(d.option_labels?[cur] ?? cur).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
                        }
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    }.disabled(locked)
                    if d.supported == false {       // engine flagged this value as off-vocabulary
                        warningLine("Not a standard option - pick a suggested value above.")
                    }
                    if !d.reason.isEmpty {
                        Text(d.reason).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                    }
                }
            }
            // Render language: pre-selected from the profile default, changeable per flyer. The card's
            // copy above stays English by design; this row only declares what language to render in.
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text("Language").font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                Menu {
                    ForEach(FlyerLanguage.allCases, id: \.self) { lang in
                        Button { language = lang } label: {
                            HStack { Text(lang.displayName); if language == lang { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    HStack {
                        Text(language.displayName).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
                    }
                    .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                    .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                }.disabled(locked)
            }
            creativeIdeas
            designNotes
            Button {
                if isBlocked { onBlocked(); return }   // no quota/credits -> paywall; keep the card active to retry
                let fo = fieldValues.filter { key, val in review.fields.first(where: { $0.key == key })?.value != val }
                var dov: [String: String] = [:]
                for d in review.decisions { dov[d.key] = decisionValues[d.key] ?? d.value }
                onApprove(fo, dov, selectedElements())
            } label: {
                Text("Approve & generate 3 concepts").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(locked)
        }
    }

    // Proactive creative ideas: safe ones default on, sensitive ones default off; the user toggles.
    @ViewBuilder private var creativeIdeas: some View {
        if let elements = review.creative_elements, !elements.isEmpty {
            Divider().background(FGColors.borderSubtle)
            Text("Creative ideas").font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
            ForEach(elements) { e in
                HStack(alignment: .top, spacing: FGSpacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: FGSpacing.xxs) {
                            Text(e.what).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            if e.sensitivity == "sensitive" {
                                Text("SENSITIVE").font(FGTypography.captionSmall).foregroundColor(FGColors.warning)
                                    .padding(.horizontal, FGSpacing.xxs).padding(.vertical, 1)
                                    .background(FGColors.warning.opacity(0.15)).clipShape(Capsule())
                            }
                        }
                        if let why = e.why, !why.isEmpty {
                            Text(why).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { isElementOn(e) }, set: { elementSelected[e.what] = $0 }))
                        .labelsHidden().tint(FGColors.accentPrimary).disabled(locked)
                }
            }
        }
    }

    // The design brief now rides inside review.plan; surface it (older builds got a separate event).
    @ViewBuilder private var designNotes: some View {
        if let plan = review.plan, !(plan.notes.isEmpty && plan.checklist.isEmpty && plan.recommendations.isEmpty) {
            Divider().background(FGColors.borderSubtle)
            if !plan.notes.isEmpty {
                Text(plan.notes).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
            }
            if !plan.checklist.isEmpty || !plan.recommendations.isEmpty {
                DisclosureGroup {
                    ForEach(plan.checklist, id: \.self) { planBullet($0, "checkmark.circle") }
                    ForEach(plan.recommendations, id: \.self) { planBullet($0, "lightbulb") }
                } label: {
                    Text("Design notes").font(FGTypography.captionBold).foregroundColor(FGColors.textTertiary)
                }.tint(FGColors.accentSecondary)
            }
        }
    }

    private func isElementOn(_ e: CreativeProposalDTO) -> Bool {
        elementSelected[e.what] ?? (e.selected ?? (e.sensitivity == "safe"))
    }
    /// nil when no creative ideas were offered (engine keeps its safe defaults); otherwise the chosen set.
    private func selectedElements() -> [String]? {
        guard let elements = review.creative_elements, !elements.isEmpty else { return nil }
        return elements.filter { isElementOn($0) }.map { $0.what }
    }
    @ViewBuilder private func warningLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xxs) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(FGColors.warning)
            Text(text).font(FGTypography.captionSmall).foregroundColor(FGColors.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    @ViewBuilder private func planBullet(_ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: FGSpacing.xs) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(FGColors.accentSecondary).padding(.top, 2)
            Text(text).font(FGTypography.captionSmall).foregroundColor(FGColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The user's uploaded flyer, shown as the edit starting point: just the image, no Save / My Flyers /
/// Resize (those belong on generated results) and no refine box (editing is via the composer).
private struct ReferenceImageCard: View {
    let concept: ConceptDTO
    var onMarkUp: (Data) -> Void = { _ in }
    var body: some View {
        AssistantCard {
            Text("Your flyer").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            if let data = concept.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFit()
                    .frame(maxWidth: .infinity).auroraFlyerCard()
                MarkUpButton { onMarkUp(data) }
            }
        }
    }
}

/// "Mark up to edit" - opens the full-screen annotation editor on a flyer image. Shared by the
/// uploaded-reference card and generated concept cards so they read the same.
private struct MarkUpButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("Mark up to edit", systemImage: "pencil.and.outline")
                .font(FGTypography.buttonSmall).foregroundColor(FGColors.accentSecondary)
        }
    }
}

private struct ConceptsCard: View {
    let concepts: [ConceptDTO]
    var heading: String? = nil                    // overrides the title (e.g. a seeded "Starting point")
    let onRefine: (ConceptDTO, String) -> Void
    let onResize: (ConceptDTO, AspectRatio) -> Void
    let onAddToMyFlyers: (ConceptDTO) -> Void
    var onMarkUp: (ConceptDTO) -> Void = { _ in }
    @State private var refineText: [String: String] = [:]
    @State private var savedVersionIDs: Set<String> = []
    var body: some View {
        AssistantCard {
            Text(heading ?? (concepts.count > 1 ? "Three concepts" : "Updated concept")).font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(concepts) { c in
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    if let data = c.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .frame(maxWidth: .infinity).auroraFlyerCard()
                        MarkUpButton { onMarkUp(c) }
                    } else if let err = c.error {
                        Text(err).font(FGTypography.captionSmall).foregroundColor(FGColors.error)
                    }
                    HStack(spacing: FGSpacing.xs) {
                        TextField("Refine (e.g. warmer, bigger headline)", text: Binding(
                            get: { refineText[c.version_id] ?? "" }, set: { refineText[c.version_id] = $0 }))
                            .textFieldStyle(.plain).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                            .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        Button {
                            let t = (refineText[c.version_id] ?? "").trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { onRefine(c, t) }
                        } label: { Image(systemName: "wand.and.stars").foregroundColor(FGColors.accentPrimary) }
                    }
                    HStack(spacing: FGSpacing.md) {
                        Button { save(c) } label: { Label("Photos", systemImage: "square.and.arrow.down").font(FGTypography.buttonSmall) }
                            .foregroundColor(FGColors.accentSecondary)
                        let added = savedVersionIDs.contains(c.version_id)
                        Button {
                            onAddToMyFlyers(c)
                            savedVersionIDs.insert(c.version_id)
                        } label: {
                            Label(added ? "Added" : "My Flyers",
                                  systemImage: added ? "checkmark.circle.fill" : "square.grid.2x2")
                                .font(FGTypography.buttonSmall)
                        }
                        .foregroundColor(added ? FGColors.success : FGColors.accentSecondary)
                        .disabled(added)
                        Menu {
                            ForEach(AspectRatio.allCases) { ar in Button(ar.displayName) { onResize(c, ar) } }
                        } label: { Label("Resize", systemImage: "aspectratio").font(FGTypography.buttonSmall).foregroundColor(FGColors.accentSecondary) }
                    }
                }
                .padding(.bottom, FGSpacing.xs)
            }
        }
    }
    private func save(_ c: ConceptDTO) {
        guard let data = c.imageData else { return }
        Task { try? await PhotoLibraryService.saveImageData(data) }
    }
}

// MARK: - Growing text editor with an always-visible scroll thumb
//
// SwiftUI's TextField and TextEditor don't give us a persistent, prominent scroll
// indicator (TextField shows none; iOS only flashes one while dragging), so the composer
// uses this UITextView-backed editor. It grows with its content from one line up to
// ~8 lines, then scrolls, drawing its own always-on thumb on the right edge whenever the
// text overflows. Styling (font, colors, insets, radius) mirrors the design tokens so it
// looks identical to the old TextField pill.
struct GrowingScrollTextEditor: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isEnabled: Bool
    // Defaults match the chat composer; callers (e.g. the review card) override for a denser field.
    var fontSize: CGFloat = 15         // FGTypography.body; review fields pass 13 (bodySmall)
    var insetH: CGFloat = FGSpacing.md // horizontal text padding
    var insetV: CGFloat = FGSpacing.sm // vertical text padding
    var maxLines: CGFloat = 8          // grow up to this many lines, then scroll

    private var uiFont: UIFont { UIFont.systemFont(ofSize: fontSize, weight: .regular) }
    private var minHeight: CGFloat { ceil(uiFont.lineHeight) + insetV * 2 }
    private var maxHeight: CGFloat { ceil(uiFont.lineHeight * maxLines) + insetV * 2 }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ComposerContainerView {
        let container = ComposerContainerView()
        let tv = container.textView
        tv.delegate = context.coordinator
        tv.font = uiFont
        tv.textColor = UIColor(FGColors.textPrimary)
        tv.tintColor = UIColor(FGColors.accentPrimary) // caret + selection
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: insetV, left: insetH, bottom: insetV, right: insetH)
        tv.textContainer.lineFragmentPadding = 0
        tv.showsVerticalScrollIndicator = false // replaced by our always-on thumb
        tv.alwaysBounceVertical = false
        tv.keyboardDismissMode = .interactive

        container.placeholderLabel.font = uiFont
        container.placeholderLabel.textColor = UIColor(FGColors.textTertiary)
        container.placeholderLabel.text = placeholder
        container.textInset = UIEdgeInsets(top: insetV, left: insetH, bottom: insetV, right: insetH)
        return container
    }

    func updateUIView(_ container: ComposerContainerView, context: Context) {
        let tv = container.textView
        // Only overwrite when the binding changed externally (prefill, clear-on-send); leave the
        // text view alone during normal typing so we never clobber the caret or in-flight IME text.
        if tv.text != text {
            let sel = tv.selectedRange
            tv.text = text
            tv.selectedRange = NSRange(location: min(sel.location, (text as NSString).length), length: 0)
        }
        container.placeholderLabel.text = placeholder
        container.placeholderLabel.isHidden = !text.isEmpty
        tv.isEditable = isEnabled
        container.setNeedsLayout()
    }

    // Reports the clamped height so the composer grows to fit, up to the 8-line cap.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView container: ComposerContainerView, context: Context) -> CGSize? {
        let width = proposal.width ?? container.bounds.width
        guard width > 0 else { return nil }
        let fit = container.textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: min(maxHeight, max(minHeight, ceil(fit))))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: GrowingScrollTextEditor
        init(_ parent: GrowingScrollTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            guard let container = textView.superview as? ComposerContainerView else { return }
            container.placeholderLabel.isHidden = !textView.text.isEmpty
            container.setNeedsLayout()
        }

        // UITextViewDelegate inherits UIScrollViewDelegate: keep the thumb in sync as the user scrolls.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            (scrollView.superview as? ComposerContainerView)?.updateScrollIndicator()
        }
    }
}

/// Hosts the text view, its placeholder, and the always-visible scroll thumb. The thumb is a
/// sibling of the text view (not inside its scrolling content), so it stays pinned to the viewport.
final class ComposerContainerView: UIView {
    let textView = UITextView()
    let placeholderLabel = UILabel()
    private let track = UIView()
    private let thumb = UIView()
    var textInset: UIEdgeInsets = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)

        placeholderLabel.numberOfLines = 1
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)

        track.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        track.isUserInteractionEnabled = false
        track.isHidden = true
        addSubview(track)

        thumb.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        thumb.isUserInteractionEnabled = false
        thumb.isHidden = true
        addSubview(thumb)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.frame = bounds
        let pw = max(0, bounds.width - textInset.left - textInset.right)
        placeholderLabel.frame = CGRect(x: textInset.left, y: textInset.top,
                                        width: pw, height: ceil(placeholderLabel.font.lineHeight))
        updateScrollIndicator()
    }

    /// Draws (or hides) the always-visible scroll thumb based on how far the text overflows.
    func updateScrollIndicator() {
        let visible = textView.bounds.height
        let content = textView.sizeThatFits(CGSize(width: textView.bounds.width,
                                                   height: .greatestFiniteMagnitude)).height
        let overflow = content - visible
        guard visible > 0, overflow > 1 else {
            track.isHidden = true
            thumb.isHidden = true
            return
        }
        track.isHidden = false
        thumb.isHidden = false

        let barWidth: CGFloat = 5
        let rightMargin: CGFloat = 4
        let vInset: CGFloat = 6 // keep clear of the pill's rounded corners
        let x = bounds.width - barWidth - rightMargin
        let trackH = max(0, visible - vInset * 2)
        track.frame = CGRect(x: x, y: vInset, width: barWidth, height: trackH)
        track.layer.cornerRadius = barWidth / 2

        let thumbH = max(28, trackH * (visible / content))
        let progress = max(0, min(1, textView.contentOffset.y / overflow))
        thumb.frame = CGRect(x: x, y: vInset + (trackH - thumbH) * progress,
                             width: barWidth, height: thumbH)
        thumb.layer.cornerRadius = barWidth / 2
    }
}
