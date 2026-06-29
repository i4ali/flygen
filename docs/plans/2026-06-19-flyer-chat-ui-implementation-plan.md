# Flyer Chat UI Wiring — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an isolated, experimental "Chat (Beta)" screen to the FlyGen iOS app that drives the engine's local FastAPI `POST /chat` SSE workflow end-to-end (describe → questions → review/approve → 3 real concepts → refine/resize), tested on the Simulator against `http://localhost:8000`.

**Architecture:** A new `Chat/` group in the app holds a native `URLSession` SSE client, typed `Codable` DTOs that mirror the engine wire format, an `@MainActor` view model that maps streamed events to a chat transcript, and SwiftUI cards styled with the existing `FG*` design tokens. The engine is unchanged and run locally with uvicorn. The 9-step wizard, OpenRouter/Worker service, credits, and CloudKit are untouched.

**Tech Stack:** SwiftUI (iOS 17), `URLSession.bytes` SSE, `Codable`; Python FastAPI engine via `uvicorn`; classic `.xcodeproj` (new files registered with the `xcodeproj` Ruby gem).

**Deviations from skill defaults (per user):** No branching (work on `main`). No Swift unit tests — Swift verification is "build succeeds + manual run in Simulator". Commits are **optional checkpoints**, only when the user asks.

**Reference:** Design doc `docs/plans/2026-06-19-flyer-chat-ui-wiring-design.md`.

---

## Wire contract (verified against the running engine)

`POST /chat`, request body (all optional; send only what the turn needs):
`message, action(describe|answers|approve|refine|resize), brief(ExtractedBrief echoed back), answers{field:value}, instruction, prior_image_b64, aspect_ratio, field_overrides{key:value}, decision_overrides{key:option}`

Response `text/event-stream`, frames `event: <kind>\ndata: <json>\n\n`:

| kind | payload (verified shape) |
|---|---|
| `parsed_fields` | `ExtractedBrief` — snake_case fields + `field_sources{field:"stated"\|"inferred"}` |
| `questions` | `{questions:[{field,text}]}` (≤3, no options) |
| `design_brief` | `{notes, checklist[], recommendations[]}` |
| `review` | `{fields:[{key,value,source}], decisions:[{key,label,value,options[],reason}], plan}` |
| `concepts` | `[{version_id, image_base64, error}]` (3) |
| `refined` / `resized` | `{version_id, image_base64, error}` |
| `error` | a JSON string |

State round-trip: keep the latest `parsed_fields` and resend it verbatim as `brief` each turn. `approve` adds `field_overrides`+`decision_overrides`+`answers`. `refine`/`resize` send the chosen concept's `image_base64` as `prior_image_b64`.

---

## Task 1: Engine reachability (run script + ATS)

**Files:**
- Create: `scripts/run-engine.sh`
- Modify: `FlyGen/FlyGen/Info.plist` (add ATS local-networking exception)

**Step 1: Create the run script**

```bash
mkdir -p scripts
cat > scripts/run-engine.sh <<'SH'
#!/usr/bin/env bash
# Run the FlyGen chat engine locally for the iOS Simulator to reach at http://localhost:8000
# Requires OPENROUTER_API_KEY in .env (loaded by engine/llm.py + image_generator).
set -euo pipefail
cd "$(dirname "$0")/.."
exec .venv/bin/uvicorn engine.app:app --port 8000 --reload
SH
chmod +x scripts/run-engine.sh
```

**Step 2: Verify the engine boots and serves `/chat`**

Run (in one terminal): `bash scripts/run-engine.sh`
Expected: `Uvicorn running on http://127.0.0.1:8000`.
Then (another terminal) confirm the route exists:
Run: `curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8000/chat -H 'Content-Type: application/json' -d '{}'`
Expected: `200` (an empty body streams a `describe` of empty text — fine for a reachability check). Stop the server with Ctrl-C after.

**Step 3: Add the ATS exception so the Simulator can use cleartext localhost**

Run:
```bash
PLIST=FlyGen/FlyGen/Info.plist
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :NSAppTransportSecurity:NSAllowsLocalNetworking true" "$PLIST"
/usr/libexec/PlistBuddy -c "Print :NSAppTransportSecurity" "$PLIST"
```
Expected: prints a dict containing `NSAllowsLocalNetworking = true`.

---

## Task 2: Chat DTOs + SSE client + Xcode registration helper

**Files:**
- Create: `scripts/add_to_xcode.rb`
- Create: `FlyGen/FlyGen/Chat/ChatModels.swift`
- Create: `FlyGen/FlyGen/Chat/FlyerChatClient.swift`

**Step 1: Create the Xcode registration helper** (classic project — files must be added to the `FlyGen` target)

```ruby
# scripts/add_to_xcode.rb — add Swift files to the FlyGen target. Idempotent.
# Usage: ruby scripts/add_to_xcode.rb FlyGen/FlyGen/Chat/Foo.swift [more...]
require 'xcodeproj'

project = Xcodeproj::Project.open('FlyGen/FlyGen.xcodeproj')
target = project.targets.find { |t| t.name == 'FlyGen' } or abort 'FlyGen target not found'
group = project.main_group['Chat'] || project.main_group.new_group('Chat', 'FlyGen/FlyGen/Chat')

ARGV.each do |rel|
  abort "missing file: #{rel}" unless File.exist?(rel)
  abs = File.expand_path(rel)
  if project.files.any? { |f| f.real_path.to_s == abs }
    puts "skip (already in project): #{rel}"; next
  end
  ref = group.new_reference(abs)
  target.add_file_references([ref])
  puts "added: #{rel}"
end
project.save
puts 'saved project.'
```

**Step 2: Create `ChatModels.swift`** (DTOs + typed SSE event decoding)

```swift
import Foundation

// MARK: - Request (mirrors engine/app.py ChatIn; nil fields are omitted on encode)

struct ChatRequest: Encodable {
    var message: String?
    var action: String?
    var brief: ExtractedBriefDTO?
    var answers: [String: String]?
    var instruction: String?
    var prior_image_b64: String?
    var aspect_ratio: String?
    var field_overrides: [String: String]?
    var decision_overrides: [String: String]?
}

// MARK: - parsed_fields payload (round-trips as `brief`)

struct ExtractedBriefDTO: Codable, Equatable {
    var category: String?
    var headline: String?
    var subheadline: String?
    var body_text: String?
    var date: String?
    var time: String?
    var venue_name: String?
    var address: String?
    var price: String?
    var discount_text: String?
    var cta_text: String?
    var phone: String?
    var email: String?
    var website: String?
    var purpose: String?
    var destination: String?
    var field_sources: [String: String]?

    /// Non-empty content fields in display order (category first), with their source.
    var displayFields: [(key: String, value: String, source: String)] {
        let pairs: [(String, String?)] = [
            ("category", category), ("headline", headline), ("subheadline", subheadline),
            ("body_text", body_text), ("date", date), ("time", time),
            ("venue_name", venue_name), ("address", address), ("price", price),
            ("discount_text", discount_text), ("cta_text", cta_text),
            ("phone", phone), ("email", email), ("website", website),
        ]
        return pairs.compactMap { key, value in
            guard let v = value, !v.isEmpty else { return nil }
            return (key, v, field_sources?[key] ?? "inferred")
        }
    }
}

// MARK: - questions payload

struct QuestionSetDTO: Decodable { let questions: [QuestionDTO] }
struct QuestionDTO: Decodable, Identifiable {
    let field: String
    let text: String
    var id: String { field }
}

// MARK: - design_brief payload

struct DesignBriefDTO: Decodable {
    let notes: String
    let checklist: [String]
    let recommendations: [String]
}

// MARK: - review payload

struct ReviewProposalDTO: Decodable {
    let fields: [FieldProposalDTO]
    let decisions: [DecisionProposalDTO]
    let plan: DesignBriefDTO?
}
struct FieldProposalDTO: Decodable, Identifiable {
    let key: String; let value: String; let source: String
    var id: String { key }
}
struct DecisionProposalDTO: Decodable, Identifiable {
    let key: String; let label: String; let value: String
    let options: [String]; let reason: String
    var id: String { key }
}

// MARK: - concepts | refined | resized payload

struct ConceptDTO: Decodable, Identifiable {
    let version_id: String
    let image_base64: String?
    let error: String?
    var id: String { version_id }
    var imageData: Data? { image_base64.flatMap { Data(base64Encoded: $0) } }
}

// MARK: - SSE events

enum SSEEvent {
    case parsedFields(ExtractedBriefDTO)
    case questions([QuestionDTO])
    case designBrief(DesignBriefDTO)
    case review(ReviewProposalDTO)
    case concepts([ConceptDTO])
    case refined(ConceptDTO)
    case resized(ConceptDTO)
    case error(String)
    case unknown(String)

    static func decode(event: String, data: Data) -> SSEEvent {
        let dec = JSONDecoder()
        do {
            switch event {
            case "parsed_fields": return .parsedFields(try dec.decode(ExtractedBriefDTO.self, from: data))
            case "questions":     return .questions(try dec.decode(QuestionSetDTO.self, from: data).questions)
            case "design_brief":  return .designBrief(try dec.decode(DesignBriefDTO.self, from: data))
            case "review":        return .review(try dec.decode(ReviewProposalDTO.self, from: data))
            case "concepts":      return .concepts(try dec.decode([ConceptDTO].self, from: data))
            case "refined":       return .refined(try dec.decode(ConceptDTO.self, from: data))
            case "resized":       return .resized(try dec.decode(ConceptDTO.self, from: data))
            case "error":
                let msg = (try? dec.decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? "error"
                return .error(msg)
            default: return .unknown(event)
            }
        } catch {
            return .error("decode failed for \(event): \(error.localizedDescription)")
        }
    }
}
```

**Step 3: Create `FlyerChatClient.swift`** (native SSE over `URLSession.bytes`)

```swift
import Foundation

enum ChatClientError: LocalizedError {
    case badStatus(Int)
    var errorDescription: String? {
        switch self {
        case .badStatus(let c): return "Engine returned HTTP \(c). Is it running on :8000?"
        }
    }
}

struct FlyerChatClient {
    /// The Simulator reaches the host Mac's localhost directly.
    /// Start the engine with `scripts/run-engine.sh`.
    static let baseURL = URL(string: "http://localhost:8000")!

    private let session: URLSession
    init() {
        let cfg = URLSessionConfiguration.default
        // The first GLM extract and image generation can idle for minutes with no
        // intermediate bytes, so allow long gaps before timing out.
        cfg.timeoutIntervalForRequest = 300
        cfg.timeoutIntervalForResource = 600
        session = URLSession(configuration: cfg)
    }

    func stream(_ body: ChatRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = URLRequest(url: Self.baseURL.appendingPathComponent("chat"))
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    req.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        continuation.finish(throwing: ChatClientError.badStatus(http.statusCode)); return
                    }

                    var eventName = "message"
                    var dataLines: [String] = []
                    func flush() {
                        guard !dataLines.isEmpty else { return }
                        if let data = dataLines.joined(separator: "\n").data(using: .utf8) {
                            continuation.yield(SSEEvent.decode(event: eventName, data: data))
                        }
                        eventName = "message"; dataLines = []
                    }

                    for try await line in bytes.lines {
                        if line.isEmpty { flush() }
                        else if line.hasPrefix("event:") { eventName = line.dropFirst(6).trimmingCharacters(in: .whitespaces) }
                        else if line.hasPrefix("data:") { dataLines.append(String(line.dropFirst(5).drop(while: { $0 == " " }))) }
                    }
                    flush()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
```

**Step 4: Register the two files and build**

Run: `ruby scripts/add_to_xcode.rb FlyGen/FlyGen/Chat/ChatModels.swift FlyGen/FlyGen/Chat/FlyerChatClient.swift`
Expected: `added: …ChatModels.swift` / `added: …FlyerChatClient.swift` / `saved project.`

Run:
```bash
xcodebuild -project FlyGen/FlyGen.xcodeproj -scheme FlyGen \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -8
```
Expected: `** BUILD SUCCEEDED **`. Fix any compile errors before continuing.

---

## Task 3: Chat view model + transcript model

**Files:**
- Create: `FlyGen/FlyGen/Chat/FlyerChatViewModel.swift`

**Step 1: Create `FlyerChatViewModel.swift`**

```swift
import SwiftUI

// MARK: - Transcript model

struct ChatBubble: Identifiable {
    let id: UUID
    let kind: Kind
    init(_ kind: Kind, id: UUID = UUID()) { self.kind = kind; self.id = id }
    enum Kind {
        case user(String)
        case assistant(String)
        case typing(String)
        case parsedFields(ExtractedBriefDTO)
        case questions([QuestionDTO])
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

    private let client = FlyerChatClient()
    private var brief: ExtractedBriefDTO?
    private var answers: [String: String] = [:]

    func start() {
        if transcript.isEmpty {
            transcript.append(ChatBubble(.assistant("Tell me about the flyer you want — one sentence is plenty.")))
        }
    }

    // MARK: Intents

    func sendDescribe() {
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        composerText = ""
        // a fresh describe starts a new flyer
        brief = nil; answers = [:]
        transcript.append(ChatBubble(.user(text)))
        run(ChatRequest(message: text, action: "describe"), thinking: "Reading your idea…")
    }

    func submitAnswers(_ provided: [String: String]) {
        let cleaned = provided.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !cleaned.isEmpty, !isStreaming else { return }
        answers.merge(cleaned) { _, new in new }
        transcript.append(ChatBubble(.user(cleaned.map { "\($0.key.replacingOccurrences(of: "_", with: " ")): \($0.value)" }.joined(separator: ", "))))
        run(ChatRequest(action: "answers", brief: brief, answers: cleaned), thinking: "Designing…")
    }

    func approve(fieldOverrides: [String: String], decisionOverrides: [String: String]) {
        guard !isStreaming else { return }
        transcript.append(ChatBubble(.user("Looks good — generate concepts.")))
        run(ChatRequest(action: "approve", brief: brief, answers: answers,
                        field_overrides: fieldOverrides.isEmpty ? nil : fieldOverrides,
                        decision_overrides: decisionOverrides.isEmpty ? nil : decisionOverrides),
            thinking: "Generating 3 concepts — about a minute…")
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
        case .parsedFields(let b): brief = b; insertBeforeTyping(ChatBubble(.parsedFields(b)), typingID: typingID)
        case .questions(let qs):   insertBeforeTyping(ChatBubble(.questions(qs)), typingID: typingID)
        case .designBrief(let d):  insertBeforeTyping(ChatBubble(.designBrief(d)), typingID: typingID)
        case .review(let r):       insertBeforeTyping(ChatBubble(.review(r)), typingID: typingID)
        case .concepts(let cs):    insertBeforeTyping(ChatBubble(.concepts(cs)), typingID: typingID)
        case .refined(let c), .resized(let c): insertBeforeTyping(ChatBubble(.concepts([c])), typingID: typingID)
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
```

**Step 2: Register and build**

Run: `ruby scripts/add_to_xcode.rb FlyGen/FlyGen/Chat/FlyerChatViewModel.swift`
Run the build command from Task 2 Step 4. Expected: `** BUILD SUCCEEDED **`.

---

## Task 4: Chat view + cards

**Files:**
- Create: `FlyGen/FlyGen/Chat/FlyerChatView.swift`

**Step 1: Create `FlyerChatView.swift`** (transcript, composer, and all bubble/card subviews)

```swift
import SwiftUI
import UIKit

struct FlyerChatView: View {
    @StateObject private var vm = FlyerChatViewModel()
    @Environment(\.dismiss) private var dismiss

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
                        }
                        .padding(FGSpacing.screenHorizontal)
                    }
                    .onChange(of: vm.transcript.count) { _, _ in
                        if let last = vm.transcript.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                composer
            }
            .background(FGColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Chat (Beta)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(FGColors.textSecondary)
                }
            }
            .onAppear { vm.start() }
        }
    }

    @ViewBuilder
    private func bubbleView(_ bubble: ChatBubble) -> some View {
        switch bubble.kind {
        case .user(let t):        UserBubble(text: t)
        case .assistant(let t):   AssistantBubble(text: t)
        case .typing(let t):      TypingBubble(text: t)
        case .parsedFields(let b): ParsedFieldsCard(brief: b)
        case .questions(let qs):  QuestionsCard(questions: qs, onSubmit: { vm.submitAnswers($0) })
        case .designBrief(let d): DesignNotesCard(brief: d)
        case .review(let r):      ReviewCard(review: r, onApprove: { vm.approve(fieldOverrides: $0, decisionOverrides: $1) })
        case .concepts(let cs):   ConceptsCard(concepts: cs,
                                      onRefine: { vm.refine(concept: $0, instruction: $1) },
                                      onResize: { vm.resize(concept: $0, aspect: $1) })
        case .error(let m):       ErrorBubble(text: m)
        }
    }

    private var composer: some View {
        HStack(spacing: FGSpacing.sm) {
            TextField("Describe a flyer (starts a new one)…", text: $vm.composerText, axis: .vertical)
                .textFieldStyle(.plain).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.sm)
                .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                .disabled(vm.isStreaming)
            Button { vm.sendDescribe() } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                    .foregroundColor(vm.composerText.isEmpty || vm.isStreaming ? FGColors.textTertiary : FGColors.accentPrimary)
            }
            .disabled(vm.composerText.isEmpty || vm.isStreaming)
        }
        .padding(FGSpacing.sm)
        .background(FGColors.backgroundSecondary)
    }
}

// MARK: - Small bubbles

private struct UserBubble: View {
    let text: String
    var body: some View {
        HStack { Spacer(minLength: FGSpacing.xl)
            Text(text).font(FGTypography.body).foregroundColor(FGColors.textOnAccent)
                .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.sm)
                .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        }
    }
}
private struct AssistantBubble: View {
    let text: String
    var body: some View {
        Text(text).font(FGTypography.body).foregroundColor(FGColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
private struct TypingBubble: View {
    let text: String
    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            ProgressView().tint(FGColors.accentSecondary).scaleEffect(0.8)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textTertiary)
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
    var body: some View {
        AssistantCard {
            Text("Here's what I got").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(brief.displayFields, id: \.key) { f in
                HStack(alignment: .top, spacing: FGSpacing.xs) {
                    Text(f.key.replacingOccurrences(of: "_", with: " "))
                        .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                        .frame(width: 92, alignment: .leading)
                    Text(f.value).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SourceBadge(source: f.source)
                }
            }
        }
    }
}

private struct QuestionsCard: View {
    let questions: [QuestionDTO]
    let onSubmit: ([String: String]) -> Void
    @State private var answers: [String: String] = [:]
    @State private var submitted = false
    var body: some View {
        AssistantCard {
            Text("A couple of quick questions").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(questions) { q in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(q.text).font(FGTypography.bodySmall).foregroundColor(FGColors.textSecondary)
                    TextField("Your answer", text: Binding(get: { answers[q.field] ?? "" }, set: { answers[q.field] = $0 }))
                        .textFieldStyle(.plain).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .disabled(submitted)
                }
            }
            Button { submitted = true; onSubmit(answers) } label: {
                Text("Send answers").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(submitted)
        }
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
    let onApprove: (_ fieldOverrides: [String: String], _ decisionOverrides: [String: String]) -> Void
    @State private var fieldValues: [String: String] = [:]
    @State private var decisionValues: [String: String] = [:]
    @State private var approved = false
    var body: some View {
        AssistantCard {
            Text("Review before I generate").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(review.fields) { f in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack { Text(f.key.replacingOccurrences(of: "_", with: " "))
                        .font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                        Spacer(); SourceBadge(source: f.source) }
                    TextField("", text: Binding(get: { fieldValues[f.key] ?? f.value }, set: { fieldValues[f.key] = $0 }))
                        .textFieldStyle(.plain).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                        .disabled(approved)
                }
            }
            Divider().background(FGColors.borderSubtle)
            ForEach(review.decisions) { d in
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    Text(d.label).font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                    Menu {
                        ForEach(d.options, id: \.self) { opt in Button(opt) { decisionValues[d.key] = opt } }
                    } label: {
                        HStack {
                            Text(decisionValues[d.key] ?? d.value).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
                        }
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                        .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                    }.disabled(approved)
                    Text(d.reason).font(FGTypography.captionSmall).foregroundColor(FGColors.textTertiary)
                }
            }
            Button {
                approved = true
                let fo = fieldValues.filter { key, val in review.fields.first(where: { $0.key == key })?.value != val }
                var dov: [String: String] = [:]
                for d in review.decisions { dov[d.key] = decisionValues[d.key] ?? d.value }
                onApprove(fo, dov)
            } label: {
                Text("Approve & generate 3 concepts").font(FGTypography.button).foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            }.disabled(approved)
        }
    }
}

private struct ConceptsCard: View {
    let concepts: [ConceptDTO]
    let onRefine: (ConceptDTO, String) -> Void
    let onResize: (ConceptDTO, AspectRatio) -> Void
    @State private var refineText: [String: String] = [:]
    var body: some View {
        AssistantCard {
            Text(concepts.count > 1 ? "Three concepts" : "Updated concept").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
            ForEach(concepts) { c in
                VStack(alignment: .leading, spacing: FGSpacing.xs) {
                    if let data = c.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
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
                        Button { save(c) } label: { Label("Save", systemImage: "square.and.arrow.down").font(FGTypography.buttonSmall) }
                            .foregroundColor(FGColors.accentSecondary)
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
```

**Step 2: Register and build**

Run: `ruby scripts/add_to_xcode.rb FlyGen/FlyGen/Chat/FlyerChatView.swift`
Run the build command from Task 2 Step 4. Expected: `** BUILD SUCCEEDED **`.

---

## Task 5: Home entry point ("Chat (Beta)")

**Files:**
- Modify: `FlyGen/FlyGen/Views/Tabs/HomeTab.swift`

**Step 1: Add presentation state** — after `@State private var showingDiscardDraftAlert = false` (~line 10) add:

```swift
    @State private var showingChat = false
```

**Step 2: Add the entry button** — immediately after the "Use Template" button block (after its `.padding(.horizontal, FGSpacing.xl)`, ~line 136), inside the same `VStack`, insert:

```swift
                    // Chat (Beta) — experimental conversational flow (not credit-gated)
                    Button { showingChat = true } label: {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "bubble.left.and.text.bubble.right")
                            Text("Chat (Beta)")
                            Text("NEW").font(FGTypography.captionSmall).foregroundColor(FGColors.textOnAccent)
                                .padding(.horizontal, FGSpacing.xs).padding(.vertical, 2)
                                .background(FGColors.accentSecondary).clipShape(Capsule())
                        }
                        .font(FGTypography.button).foregroundColor(FGColors.textSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.md)
                        .background(FGColors.surfaceDefault).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .overlay(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius).stroke(FGColors.borderDefault, lineWidth: 1))
                    }
                    .padding(.horizontal, FGSpacing.xl)
```

**Step 3: Present the chat** — add alongside the other `.fullScreenCover` modifiers (e.g. after the `TemplatePickerView` cover, ~line 176):

```swift
            .fullScreenCover(isPresented: $showingChat) {
                FlyerChatView()
            }
```

**Step 4: Build**

Run the build command from Task 2 Step 4. Expected: `** BUILD SUCCEEDED **`.

---

## Task 6: Manual end-to-end test (Simulator → local engine)

**Step 1:** Confirm `.env` at repo root contains `OPENROUTER_API_KEY=...`.

**Step 2:** Terminal A: `bash scripts/run-engine.sh` → wait for `Uvicorn running on http://127.0.0.1:8000`.

**Step 3:** Open `FlyGen/FlyGen.xcodeproj` in Xcode, choose an iPhone simulator (iOS 17+), Run (⌘R). (The app requires iCloud — use a simulator already signed into an Apple ID, or the existing onboarding path.)

**Step 4:** Home tab → tap **Chat (Beta)**. Type:
`Flyer for our church bake sale this Saturday 10–2 at Grace Hall, proceeds to the youth summer camp` → send.

**Step 5: Verify the full flow**
- "Here's what I got" card appears with stated/inferred badges (after the first GLM call — may take 20–150s; the cold-start latency seen earlier).
- A questions card appears (e.g. a CTA question). Answer it → "Designing…".
- "Design notes" + "Review before I generate" appear. Change one decision (e.g. format → `letter`). Tap **Approve & generate 3 concepts**.
- After ~1–2 min, three images render. Type a refine ("warmer, bigger headline") on one → a refined image returns. Use **Resize** → pick Story (9:16) → a resized image returns. Tap **Save** → image lands in Photos.
- Watch Terminal A: each turn logs a `POST /chat`.

**Troubleshooting:**
- Connection refused / `HTTP -1004`: the engine isn't running or not on `:8000` (the error bubble hints this).
- Very slow first response: expected GLM latency, not a hang (resource timeout is 300s).
- Decode error bubble: compare the failing event's JSON in Terminal A against the DTO; adjust the DTO.

---

## Task 7 (optional): Engine `/chat` smoke assertion

**Files:**
- Modify: `tests/engine/test_app.py`

Add a test that a `describe` turn streams the expected event kinds, reusing the existing fakes (no network). Keep the engine suite green:

Run: `.venv/bin/python -m pytest tests/engine -q`
Expected: all pass.

---

## Done / out of scope

Wizard, credits, CloudKit, OpenRouter Worker service untouched. No persistence, no device/LAN/deploy, no mockup-perfect styling, no Swift unit tests. Follow-ups (post-prototype): server-supplied question chips; decision overrides carried through refine via persisted project; engine deployment for on-device testing.
