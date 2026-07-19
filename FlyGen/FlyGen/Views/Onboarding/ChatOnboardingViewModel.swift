import SwiftUI

/// A display-ready item in the onboarding transcript. The view renders these; the view model
/// produces and mutates them as the script plays.
struct RenderedBeat: Identifiable {
    let id = UUID()
    var kind: Kind

    enum Kind {
        case assistant(String)
        case user(String, typing: Bool)   // typing == true shows a blinking caret mid-type
        case thinking(String)      // current status line
        case brief([String])
        case worklog([String])     // the "show its work" checklist of design decisions
        case reveal([String])
        case qrOffer(QROfferDemo, accepted: Bool)   // accepted flips true to animate the auto-tap
        case markup(MarkupDemo)                     // circle-to-edit playing itself
        case resize(ResizeDemo)                     // format chips + aspect morph
        case savePrompt(saved: Bool)                // saved flips true to show the confirmation
        case textQuestion(placeholder: String)   // the "what are you promoting?" input field
        case chipQuestion(OnboardingQuestion)
        case cta(String)
    }
}

/// Drives the onboarding chat: walks `OnboardingScript.beats`, playing the auto beats on a
/// cancellable timer and stopping at each `.chipQuestion` to wait for the user. All motion is
/// pure SwiftUI; there is no Lottie here.
@MainActor
final class ChatOnboardingViewModel: ObservableObject {
    @Published private(set) var rendered: [RenderedBeat] = []
    /// True while a chip question is on screen awaiting the user (auto-play is paused).
    @Published private(set) var isInteracting = false

    /// The user's language selection, bound by the dropdown and returned on completion.
    @Published var selectedLanguage: FlyerLanguage = .english
    /// The active text-question's draft, bound by the input view. Deliberately not persisted.
    @Published var textDraft: String = ""

    /// Called when the user taps the final CTA. Receives the one collected preference (language);
    /// the open "what do you do?" answer is intentionally not collected.
    var onComplete: ((FlyerLanguage) -> Void)?

    private let beats = OnboardingScript.beats
    private var index = 0
    private var runTask: Task<Void, Never>?
    private var reduceMotion = false

    // MARK: - Lifecycle

    func start(reduceMotion: Bool) {
        guard rendered.isEmpty else { return }        // start is idempotent across re-appearances
        self.reduceMotion = reduceMotion
        selectedLanguage = Self.deviceLanguage()   // sensible default; the user can change it
        resume()
    }

    /// Collapse the current question's chips into a sent user bubble, then resume the script.
    func submitCurrentQuestion() {
        guard let i = rendered.lastIndex(where: {
            if case .chipQuestion = $0.kind { return true } else { return false }
        }), case .chipQuestion(let q) = rendered[i].kind else { return }

        Haptics.selection()
        let bubbleText = collapsedReply(for: q)
        withAnimation(FGAnimations.spring) { rendered[i].kind = .user(bubbleText, typing: false) }
        isInteracting = false
        resume()
    }

    /// Handle the open text question. On send, the typed words become a user bubble; on skip, no
    /// bubble is added and the question stays visible above. Either way a skip-aware warm reply is
    /// appended and the script resumes. Nothing typed here is stored.
    func submitTextQuestion(skipped: Bool) {
        guard let i = rendered.lastIndex(where: {
            if case .textQuestion = $0.kind { return true } else { return false }
        }) else { return }

        Haptics.selection()
        let trimmed = textDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let answered = !skipped && !trimmed.isEmpty
        withAnimation(FGAnimations.spring) {
            if answered {
                rendered[i].kind = .user(trimmed, typing: false)   // the field becomes their answer
            } else {
                rendered.remove(at: i)                             // drop the field; question remains above
            }
        }
        textDraft = ""
        isInteracting = false
        append(.assistant(answered ? OnboardingScript.textReplyAnswered : OnboardingScript.textReplySkipped))
        resume()
    }

    func finish() {
        Haptics.success()
        onComplete?(selectedLanguage)
    }

    /// "Skip ▸": jump past the auto-play demo straight to the "what are you promoting?" hand-off.
    /// Cancels the runner and resumes at the "Your turn" assistant line + text question. A no-op
    /// once the thread is already interactive or past the demo.
    func skipToEnding() {
        guard !isInteracting else { return }
        guard let q = beats.firstIndex(where: {
            if case .textQuestion = $0 { return true } else { return false }
        }), index < q else { return }
        Haptics.selection()
        runTask?.cancel()
        index = max(0, q - 1)     // include the "Your turn. What are you promoting?" line
        resume()
    }

    // MARK: - The runner

    private func resume() {
        runTask?.cancel()
        runTask = Task { [weak self] in await self?.runLoop() }
    }

    private func runLoop() async {
        while index < beats.count {
            if Task.isCancelled { return }
            switch beats[index] {
            case .assistant(let t):
                await pause(OnboardingTiming.beatGap)
                append(.assistant(t))
            case .userTypes(let t):
                await pause(OnboardingTiming.beatGap)
                await typeUser(t)
            case .thinking(let lines):
                await pause(OnboardingTiming.beatGap)
                await runThinking(lines)
            case .brief(let chips):
                await pause(OnboardingTiming.beatGap)
                append(.brief(chips))
            case .worklog(let items):
                await pause(OnboardingTiming.beatGap)
                append(.worklog(items))
                await pause(WorklogView.duration(for: items))   // let it tick through
            case .reveal(let names):
                await pause(OnboardingTiming.beatGap)
                append(.reveal(names))
                await pause(OnboardingTiming.revealHold)
            case .qrOffer(let demo):
                await pause(OnboardingTiming.beatGap)
                let id = append(.qrOffer(demo, accepted: false))
                await pause(OnboardingTiming.qrOfferDwell)             // let the card read
                if Task.isCancelled { return }
                withAnimation(FGAnimations.spring) { update(id, .qrOffer(demo, accepted: true)) }
                await pause(OnboardingTiming.qrAcceptHold)             // the "Yes" tap lands
                append(.reveal([demo.revealImage]))                   // hero re-blooms WITH the QR
                await pause(OnboardingTiming.revealHold)
            case .markup(let demo):
                await pause(OnboardingTiming.beatGap)
                append(.markup(demo))
                await pause(OnboardingMarkupView.duration(for: demo))  // draw circles + type notes + Apply
                if Task.isCancelled { return }
                append(.worklog(demo.worklog))
                await pause(WorklogView.duration(for: demo.worklog))
                append(.reveal([demo.resultImage]))                   // edited hero
                await pause(OnboardingTiming.revealHold)
            case .resize(let demo):
                await pause(OnboardingTiming.beatGap)
                append(.resize(demo))
                await pause(OnboardingResizeView.duration)            // chips + morph
                await pause(OnboardingTiming.revealHold)
            case .savePrompt:
                await pause(OnboardingTiming.beatGap)
                let id = append(.savePrompt(saved: false))
                await pause(OnboardingTiming.saveTapDelay)
                if Task.isCancelled { return }
                withAnimation(FGAnimations.spring) { update(id, .savePrompt(saved: true)) }
                await pause(OnboardingTiming.saveConfirmHold)
            case .textQuestion(let placeholder):
                await pause(OnboardingTiming.beatGap)
                if Task.isCancelled { return }
                append(.textQuestion(placeholder: placeholder))
                isInteracting = true
                index += 1
                return                                  // stop until submitTextQuestion(skipped:)
            case .chipQuestion(let q):
                await pause(OnboardingTiming.beatGap)
                if Task.isCancelled { return }
                append(.chipQuestion(q))
                isInteracting = true
                index += 1
                return                                  // stop until submitCurrentQuestion()
            case .cta(let title):
                await pause(OnboardingTiming.beatGap)
                append(.cta(title))
            }
            index += 1
        }
    }

    // MARK: - Beat rendering

    private func typeUser(_ full: String) async {
        guard !reduceMotion, let first = full.first else { append(.user(full, typing: false)); return }
        let id = append(.user(String(first), typing: true))
        var current = String(first)
        for ch in full.dropFirst() {
            try? await Task.sleep(nanoseconds: seconds(OnboardingTiming.typeCharInterval))
            if Task.isCancelled { return }
            current.append(ch)
            update(id, .user(current, typing: true))    // grows in place; no per-char animation
        }
        update(id, .user(current, typing: false))       // drop the caret once sent
    }

    private func runThinking(_ lines: [String]) async {
        let id = append(.thinking(lines.first ?? ""))
        for line in lines.dropFirst() {
            try? await Task.sleep(nanoseconds: seconds(OnboardingTiming.thinkingPerLine))
            if Task.isCancelled { return }
            update(id, .thinking(line))
        }
        try? await Task.sleep(nanoseconds: seconds(OnboardingTiming.thinkingPerLine))
        if Task.isCancelled { return }
        remove(id)                                      // indicator disappears before content lands
    }

    private func pause(_ s: Double) async {
        try? await Task.sleep(nanoseconds: seconds(reduceMotion ? min(s, 0.35) : s))
    }

    // MARK: - Transcript helpers

    @discardableResult
    private func append(_ kind: RenderedBeat.Kind, animated: Bool = true) -> UUID {
        let beat = RenderedBeat(kind: kind)
        if animated && !reduceMotion {
            withAnimation(FGAnimations.spring) { rendered.append(beat) }
        } else {
            rendered.append(beat)
        }
        return beat.id
    }

    private func update(_ id: UUID, _ kind: RenderedBeat.Kind) {
        guard let i = rendered.firstIndex(where: { $0.id == id }) else { return }
        rendered[i].kind = kind
    }

    private func remove(_ id: UUID) {
        withAnimation(FGAnimations.spring) { rendered.removeAll { $0.id == id } }
    }

    // MARK: - Selections

    private func collapsedReply(for q: OnboardingQuestion) -> String {
        switch q.kind {
        case .language:
            return selectedLanguage.shortName
        }
    }

    // MARK: - Utilities

    private func seconds(_ s: Double) -> UInt64 { UInt64(max(0, s) * 1_000_000_000) }

    static func deviceLanguage() -> FlyerLanguage {
        let code: String
        if #available(iOS 16, *) {
            code = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            code = Locale.current.languageCode ?? "en"
        }
        return FlyerLanguage(rawValue: code) ?? .english
    }
}
