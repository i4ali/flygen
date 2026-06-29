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
        case typing(String)
        case parsedFields(ExtractedBriefDTO)
        case questions([QuestionDTO], String)
        case designBrief(DesignBriefDTO)
        case review(ReviewProposalDTO)
        case concepts([ConceptDTO])
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

    private let client = FlyerChatClient()
    private var brief: ExtractedBriefDTO?
    private var answers: [String: String] = [:]
    private var photoNudged = false
    private var generationPhotos: [Data] = []   // photos committed to this flyer; sent at generation
    private let photoFriendlyCategories: Set<String> =
        ["music_concert", "party_celebration", "beauty_salon", "real_estate", "restaurant_food"]

    func start() {
        if transcript.isEmpty {
            transcript.append(ChatBubble(.assistant("Tell me about the flyer you want — one sentence is plenty.")))
        }
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
    }

    func removePhoto(at index: Int) {
        guard attachedPhotos.indices.contains(index) else { return }
        attachedPhotos.remove(at: index)
        if photoPickerItems.indices.contains(index) { photoPickerItems.remove(at: index) }
    }

    /// Once per flyer, nudge the user to add photos when the category is photo-friendly.
    private func maybeNudgePhotos(_ b: ExtractedBriefDTO, typingID: UUID) {
        guard !photoNudged, attachedPhotos.isEmpty, generationPhotos.isEmpty,
              let cat = b.category, photoFriendlyCategories.contains(cat) else { return }
        photoNudged = true
        let msg = cat == "music_concert"
            ? "Want the performers in the flyer? Tap the photo button to add their photos."
            : "Want to feature your own photos? Tap the photo button to add them."
        insertBeforeTyping(ChatBubble(.assistant(msg)), typingID: typingID)
    }

    // MARK: Intents

    /// Send is enabled when there's text to describe OR a photo to attach.
    var canSend: Bool {
        !isStreaming && (!composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         || !attachedPhotos.isEmpty)
    }

    func send() {
        guard !isStreaming else { return }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let photos = attachedPhotos
        guard !text.isEmpty || !photos.isEmpty else { return }

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
            brief = nil; answers = [:]
            photoNudged = !generationPhotos.isEmpty     // already have photos -> skip the nudge
            transcript.append(ChatBubble(.user(text)))
            run(ChatRequest(message: text, action: "describe"), thinking: "Reading your idea…")
        } else {
            photoNudged = true                          // photos sent on their own
        }
    }

    func submitAnswers(_ provided: [String: String], order: [String], stage: String) {
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
        let isDesign = stage == "design"
        run(ChatRequest(action: "answers", stage: isDesign ? "design" : nil, brief: brief, answers: cleaned),
            thinking: isDesign ? "Finalizing…" : "Designing…")
    }

    func approve(fieldOverrides: [String: String], decisionOverrides: [String: String]) {
        guard !isStreaming else { return }
        // Everything committed via send, plus anything still staged in the tray.
        let photos = (generationPhotos + attachedPhotos).map { $0.base64EncodedString() }
        let label = photos.isEmpty ? "Looks good — generate concepts."
            : "Looks good — generate concepts (with \(photos.count) photo\(photos.count == 1 ? "" : "s"))."
        transcript.append(ChatBubble(.user(label)))
        run(ChatRequest(action: "approve", brief: brief, answers: answers,
                        field_overrides: fieldOverrides.isEmpty ? nil : fieldOverrides,
                        decision_overrides: decisionOverrides.isEmpty ? nil : decisionOverrides,
                        user_photos_b64: photos.isEmpty ? nil : photos),
            thinking: "Generating 3 concepts — about a minute…")
        generationPhotos = []; attachedPhotos = []; photoPickerItems = []   // sent with this generation
    }

    func refine(concept: ConceptDTO, instruction: String) {
        guard let b64 = concept.image_base64, !isStreaming else { return }
        transcript.append(ChatBubble(.user("Refine: \(instruction)")))
        run(ChatRequest(action: "refine", brief: brief, instruction: instruction, prior_image_b64: b64), thinking: "Refining…")
    }

    func resize(concept: ConceptDTO, aspect: AspectRatio) {
        guard let b64 = concept.image_base64, !isStreaming else { return }
        transcript.append(ChatBubble(.user("Resize to \(aspect.displayName).")))
        run(ChatRequest(action: "resize", brief: brief, prior_image_b64: b64, aspect_ratio: aspect.rawValue), thinking: "Reformatting…")
    }

    // MARK: Streaming

    private func run(_ request: ChatRequest, thinking: String) {
        isStreaming = true
        let typing = ChatBubble(.typing(thinking))
        transcript.append(typing)               // pinned at the bottom until the turn ends
        Task {
            do {
                for try await event in client.stream(request) { apply(event, typingID: typing.id) }
            } catch {
                insertBeforeTyping(ChatBubble(.error(error.localizedDescription)), typingID: typing.id)
            }
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
        case .questions(let qs, let stage): insertBeforeTyping(ChatBubble(.questions(qs, stage)), typingID: typingID)
        case .designBrief(let d):  insertBeforeTyping(ChatBubble(.designBrief(d)), typingID: typingID)
        case .review(let r):       insertBeforeTyping(ChatBubble(.review(r)), typingID: typingID)
        case .concepts(let cs):    insertBeforeTyping(ChatBubble(.concepts(cs)), typingID: typingID)
        case .refined(let c), .resized(let c): insertBeforeTyping(ChatBubble(.concepts([c])), typingID: typingID)
        case .note(let t):         insertBeforeTyping(ChatBubble(.assistant(t)), typingID: typingID)
        case .error(let msg):      insertBeforeTyping(ChatBubble(.error(msg)), typingID: typingID)
        case .unknown: break
        }
    }

    private func insertBeforeTyping(_ bubble: ChatBubble, typingID: UUID) {
        if let i = transcript.firstIndex(where: { $0.id == typingID }) { transcript.insert(bubble, at: i) }
        else { transcript.append(bubble) }
    }
    private func removeTyping(_ id: UUID) { transcript.removeAll { $0.id == id } }
}
