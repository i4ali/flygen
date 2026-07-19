import Foundation
import CoreGraphics

// The onboarding storyboard, expressed as data. `ChatOnboardingViewModel` walks these beats:
// the auto beats play on a timer, and `.textQuestion` / `.chipQuestion` stop the runner to wait
// for the user. Editing the flow means editing this list - not the view or the runner.
//
// The story: one BBQ flyer is generated from a sentence, then evolves through the app's real
// features - a QR is added, a circle-to-edit tweaks it, it's resized for other platforms, and the
// brief is saved - before the user types their own event and hits the paywall. Crucially the demo
// flyers ship QR-free; the QR only appears when the assistant deliberately offers it (beat ②), so
// the feature is shown honestly instead of looking like an automatic part of generation.

enum OnboardingBeat {
    /// Assistant plain-text line (revealed after a short gap).
    case assistant(String)
    /// User violet bubble, typed out character-by-character.
    case userTypes(String)
    /// The "thinking" indicator, cycling through these status lines, then removed.
    case thinking([String])
    /// A comprehension chip-row proving the brief was understood.
    case brief([String])
    /// "Show its work": a checklist of expert design decisions that ticks through, so the
    /// engine's quality is felt rather than claimed.
    case worklog([String])
    /// The money shot: these flyer image asset names bloom in, staggered.
    case reveal([String])
    /// Auto-play ②: the proactive QR offer card. It accepts itself, then the runner reveals the
    /// hero with the QR composited on (mirrors the real `QROfferBubble` + next-render compositing).
    case qrOffer(QROfferDemo)
    /// Auto-play ③: circle-to-edit. Magenta circles + notes draw themselves over the hero, then the
    /// runner ticks the edit worklog and reveals the edited hero.
    case markup(MarkupDemo)
    /// Auto-play ④: resize. Format chips slide in and the hero morphs into a new aspect ratio.
    case resize(ResizeDemo)
    /// Auto-play ⑤: save the prompt. The bookmark taps and a "Saved to your Prompts" confirmation
    /// slides in.
    case savePrompt
    /// Interactive free-text: pauses the runner until the user sends or skips. Renders only the
    /// input field; the question itself is a preceding `.assistant` beat so it stays visible above
    /// the answer. Nothing typed here is stored - it's the "make it yours" investment beat.
    case textQuestion(placeholder: String)
    /// Interactive: pauses the runner until the user submits.
    case chipQuestion(OnboardingQuestion)
    /// Final call-to-action button that completes onboarding (and triggers the paywall).
    case cta(String)
}

enum OnboardingQuestionKind {
    case language
}

struct OnboardingQuestion: Identifiable, Equatable {
    let id = UUID()
    let kind: OnboardingQuestionKind
    let prompt: String
}

// MARK: - Auto-play beat payloads

/// The QR-offer beat: mirrors the real `QROfferBubble`, auto-accepts, then the runner reveals
/// `revealImage` (the hero with the QR composited on).
struct QROfferDemo: Equatable {
    let prompt: String          // "Add a QR code that opens your RSVP link?"
    let acceptLabel: String     // "Yes, add it"
    let declineLabel: String    // "No thanks"
    let revealImage: String     // "onboarding_hero_qr"
}

/// One markup circle + its note, positioned in normalized (0...1) space over the flyer.
struct MarkupMark: Equatable {
    let center: CGPoint         // normalized over the flyer image
    let note: String            // "make it Sunday"
}

/// The circle-to-edit beat: draws `marks` over `baseImage`, then the runner ticks `worklog` and
/// reveals `resultImage`.
struct MarkupDemo: Equatable {
    let baseImage: String       // "onboarding_hero_qr"
    let marks: [MarkupMark]
    let worklog: [String]
    let resultImage: String     // "onboarding_hero_edited"
}

/// The resize beat: shows `formats` as chips, highlights `selected`, and morphs the hero into
/// `resultImage` (a new aspect ratio).
struct ResizeDemo: Equatable {
    let formats: [String]       // ["Poster", "Story", "Square"]
    let selected: String        // "Story"
    let resultImage: String     // "onboarding_hero_story"
}

enum OnboardingScript {
    /// The three QR-free concepts fanned in beat ①. `DemoFlyerCard` shows a styled placeholder
    /// until the owner drops the real, engine-generated BBQ flyers into these imagesets.
    static let demoConcepts = ["onboarding_concept_1", "onboarding_concept_2", "onboarding_concept_3"]
    /// The concept the story follows (the middle card). QR-free until beat ②.
    static let heroBase = "onboarding_concept_2"

    /// The generation "show its work" checklist - DESIGN DECISIONS ONLY. The old "Adding a QR code"
    /// line is gone on purpose: a QR is a deliberate feature shown in beat ②, not an automatic step.
    static let worklogItems = [
        "Reading a warm, community tone",
        "Choosing a warm, high-contrast palette",
        "Balancing the headline hierarchy",
        "Keeping the address & time exact",
    ]

    /// Beat ② - the proactive QR offer. Accepts itself, then reveals `onboarding_hero_qr`.
    static let qrOffer = QROfferDemo(
        prompt: "Add a scannable QR code that opens your RSVP link?",
        acceptLabel: "Yes, add it",
        declineLabel: "No thanks",
        revealImage: "onboarding_hero_qr")

    /// Beat ③ - circle-to-edit. Two marks on the hero; the edit worklog mirrors the real editor's
    /// preserve-then-change behavior.
    static let markupDemo = MarkupDemo(
        baseImage: "onboarding_hero_qr",
        marks: [
            // Positions are tuned to the hero asset (date line ~64% down, details below); easy to
            // nudge once seen on-device, since scaledToFill can shift things a hair.
            MarkupMark(center: CGPoint(x: 0.36, y: 0.64), note: "make it Sunday"),
            MarkupMark(center: CGPoint(x: 0.62, y: 0.79), note: "add Live music"),
        ],
        worklog: ["Keeping your layout & colors", "Switching Saturday to Sunday", "Adding 'Live music'"],
        resultImage: "onboarding_hero_edited")

    /// Beat ④ - resize. One design, sized for everywhere; morphs the edited hero into a Story crop.
    static let resizeDemo = ResizeDemo(
        formats: ["Poster", "Story", "Square"],
        selected: "Story",
        resultImage: "onboarding_hero_story")

    /// The skip-aware warm reply after the "what are you promoting?" question. The copy lives here
    /// so the flow stays data-driven; the view model appends the matching line. It can't be a static
    /// beat because it branches on whether the user answered or skipped.
    static let textReplyAnswered = "Perfect - let's make yours."
    static let textReplySkipped = "All good - let's get you noticed."

    static let beats: [OnboardingBeat] = [
        // ① Hook - one sentence becomes three flyers
        .assistant("Hi, I'm your designer. One sentence, and I'll design you a flyer. Watch."),
        .userTypes("Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome."),
        .brief(["BBQ Fundraiser", "Sat 12pm", "Lincoln Park", "$10"]),   // got your facts
        .worklog(worklogItems),                                          // ...now the pro decisions (no QR)
        .reveal(demoConcepts),
        .assistant("Three ways to go, from one sentence."),
        .assistant("Let's build on this one."),
        .reveal([heroBase]),                                             // narrow to the hero (still QR-free)
        // ② Add a QR - the feature, done honestly
        .assistant("Want people to RSVP? I can add a scannable QR."),
        .qrOffer(qrOffer),                                               // auto-accepts, then reveals the QR'd hero
        .assistant("Done - it bakes right onto your flyer."),
        // ③ Circle-to-edit
        .assistant("Need a change? Don't retype it - just circle it."),
        .markup(markupDemo),                                             // draws circles + notes, then reveals the edited hero
        .assistant("Updated in seconds - nothing redone from scratch."),
        // ④ Resize for anywhere
        .assistant("Same flyer, everywhere you post."),
        .resize(resizeDemo),
        .assistant("One design, sized for Instagram, Stories, and print."),
        // ⑤ Save the prompt
        .assistant("Love this brief? Save it and reuse it anytime."),
        .savePrompt,
        .assistant("It's in your Prompts tab now - tweak the details, fresh flyer in one tap."),
        // ⑥ Your turn -> paywall
        .assistant("Your turn. What are you promoting?"),
        .textQuestion(placeholder: "e.g., Saturday yoga class in the park"),
        .chipQuestion(OnboardingQuestion(kind: .language, prompt: "What language should your flyers be in?")),
        .assistant("Great. Your flyers, your language."),
        .cta("Make my flyer"),
    ]
}

/// All auto-play timing lives here so pacing is tunable in one place.
enum OnboardingTiming {
    /// Pause before each auto beat appears.
    static let beatGap: Double = 0.7
    /// Seconds per character in the self-typing user sentence.
    static let typeCharInterval: Double = 0.035
    /// How long each "thinking" status line stays up.
    static let thinkingPerLine: Double = 1.1
    /// Delay between each flyer card in the reveal.
    static let revealStagger: Double = 0.15
    /// Extra beat after the reveal so it can breathe before the thread continues.
    static let revealHold: Double = 0.8
    /// How long the QR offer card sits before it auto-accepts.
    static let qrOfferDwell: Double = 1.4
    /// Hold after the "Yes" tap before the QR'd hero reveals.
    static let qrAcceptHold: Double = 0.5
    /// Delay before the bookmark auto-taps in the save-prompt beat.
    static let saveTapDelay: Double = 1.0
    /// How long the "Saved to your Prompts" confirmation holds.
    static let saveConfirmHold: Double = 1.4
}
