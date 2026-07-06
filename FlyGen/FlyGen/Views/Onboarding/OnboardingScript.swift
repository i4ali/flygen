import Foundation

// The onboarding storyboard, expressed as data. `ChatOnboardingViewModel` walks these beats:
// the auto beats play on a timer, and `.chipQuestion` / `.textQuestion` stop the runner to wait
// for the user. Editing the flow means editing this list - not the view or the runner.

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
    /// Interactive free-text: pauses the runner until the user sends or skips. Renders only the
    /// input field; the question itself is a preceding `.assistant` beat so it stays visible above
    /// the answer. Nothing typed here is stored - it's a rapport beat.
    case textQuestion(placeholder: String)
    /// Interactive: pauses the runner until the user submits.
    case chipQuestion(OnboardingQuestion)
    /// Final call-to-action button that completes onboarding.
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

enum OnboardingScript {
    /// Asset names for the three demo flyers revealed in beat ④. The owner drops the real,
    /// engine-generated BBQ flyers into these imagesets; `DemoFlyerCard` shows a styled
    /// placeholder until they land.
    static let demoFlyerImages = ["onboarding_demo_1", "onboarding_demo_2", "onboarding_demo_3"]

    /// The expert design decisions the "show its work" beat ticks through. Each maps to a real
    /// engine step (tone read, palette choice, hierarchy, exact-detail preservation, QR).
    static let worklogItems = [
        "Reading a warm, community tone",
        "Choosing a warm, high-contrast palette",
        "Balancing the headline hierarchy",
        "Keeping the address & time exact",
        "Adding a QR code for RSVPs",
    ]

    /// The skip-aware warm reply after the open question. The copy lives here so the flow stays
    /// data-driven; the view model appends the matching line. It can't be a static beat in the
    /// array because it branches on whether the user answered or skipped.
    static let textReplyAnswered = "Nice. Let's make you something that gets noticed."
    static let textReplySkipped = "All good - let's get you noticed."

    static let beats: [OnboardingBeat] = [
        .assistant("Hi - I'm your designer. Give me a sentence, I'll give you a flyer. Watch."),
        .userTypes("Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome."),
        .brief(["BBQ Fundraiser", "Sat 12pm", "Lincoln Park", "$10"]),   // got your facts
        .worklog(worklogItems),                                          // ...now the pro decisions
        .reveal(demoFlyerImages),
        .assistant("Three ways to go - and that was one sentence."),
        .assistant("Your turn. First - what do you do?"),               // open + personal; stores nothing
        .textQuestion(placeholder: "e.g., I run a home bakery"),
        .chipQuestion(OnboardingQuestion(kind: .language, prompt: "What language do you design in?")),
        .assistant("Perfect - your flyers, your language."),
        .cta("Make your first flyer"),
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
    /// Extra beat after the reveal so it can breathe before the thread turns interactive.
    static let revealHold: Double = 0.8
}
