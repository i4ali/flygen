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

    /// The user's selections, bound by the chip-question view and returned on completion.
    @Published var selectedCategories: Set<FlyerCategory> = []
    @Published var selectedLanguages: Set<FlyerLanguage> = []

    /// Called when the user taps the final CTA. Receives the two collected preferences.
    var onComplete: (([FlyerCategory], [FlyerLanguage]) -> Void)?

    private let beats = OnboardingScript.beats
    private var index = 0
    private var runTask: Task<Void, Never>?
    private var reduceMotion = false

    // MARK: - Lifecycle

    func start(reduceMotion: Bool) {
        guard rendered.isEmpty else { return }        // start is idempotent across re-appearances
        self.reduceMotion = reduceMotion
        selectedLanguages = [Self.deviceLanguage()]   // sensible default; the user can change it
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

    func finish() {
        Haptics.success()
        onComplete?(orderedCategories(), orderedLanguages())
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
        case .category:
            let names = orderedCategories().map { $0.onboardingLabel }
            return names.isEmpty ? "A bit of everything" : names.joined(separator: ", ")
        case .language:
            let names = orderedLanguages().map { $0.shortName }
            return names.isEmpty ? FlyerLanguage.english.shortName : names.joined(separator: ", ")
        }
    }

    /// Stable ordering (enum declaration order) regardless of tap sequence.
    private func orderedCategories() -> [FlyerCategory] {
        FlyerCategory.allCases.filter { selectedCategories.contains($0) }
    }

    private func orderedLanguages() -> [FlyerLanguage] {
        FlyerLanguage.allCases.filter { selectedLanguages.contains($0) }
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
