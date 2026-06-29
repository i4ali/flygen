# FlyGen — Wire the iOS UI to the Flyer Chat Workflow (Prototype)

- **Date:** 2026-06-19
- **Status:** Approved (brainstorm) — ready for implementation plan
- **Scope:** Experimental, isolated chat prototype in the iOS app, driving the real Python engine end-to-end on the Simulator. The existing 9-step wizard is left untouched.

## Context

- **Engine (`engine/`)** is the chat-first backend: a FastAPI `POST /chat` endpoint that **streams Server-Sent Events** through a human-gated flow (extract → questions → design brief → review → concepts → refine/resize). It is **stateless** (the caller re-sends accumulated state each turn), uses **GLM-5.2** for text and **nano-banana-pro** for images via OpenRouter, and runs **locally** (not deployed).
- **iOS app (v3.4)** is the opposite paradigm today: a **9-step wizard** that talks to a **Cloudflare Worker** (`flygen-api…workers.dev`), not the Python engine. **No chat UI exists** — only the `mockups/chat-v2/` HTML vision. Swift flyer models (`FlyerProject`, `TextContent`, …) mirror the engine's.
- **Goal:** stand up a throwaway-quality chat screen that exercises the *real* engine so the owner can feel the conversational UX ("see how it looks") before committing to the wizard→chat pivot.

## Decisions (approved)

| Axis | Decision |
|---|---|
| Fidelity | **Experimental prototype** — new, separate entry; clean-but-basic UI; wizard untouched |
| Pipeline depth | **Full** — describe → questions → review/approve → **3 real concepts** → refine/resize |
| Transport | **Simulator → `http://localhost:8000`** (engine run locally; no deploy/device/LAN) |
| Entry point | **"Chat (Beta)" card on the Home tab** → presents chat full-screen |
| Credits/persistence | **None for the chat path** — no StoreKit/credit spend, no SwiftData/CloudKit |
| Client architecture | **Native `URLSession` SSE + typed `Codable` DTOs** (zero dependencies) |
| Tests | **No Swift unit tests** (manual in-app testing). Engine suite stays green; optional single `/chat` assertion. |

### Approaches considered (client architecture)

1. **Native `URLSession.bytes(for:)` + typed DTOs — CHOSEN.** iOS 17 streams the body; SSE `event:`/`data:` parsing is trivial; `parsed_fields` round-trips as a typed `ExtractedBrief`, so no opaque-JSON handling. Zero deps — right for a prototype.
2. **SSE library** (e.g. LDSwiftEventSource) — more robust, but an unwanted dependency in a polished app for throwaway work.
3. **Non-streaming buffered turns** — simpler client but requires engine changes and loses the progressive "thinking → questions → review → concepts" feel that is the point.

## Architecture / Topology

```
┌─────────────────────────┐         POST /chat (SSE)          ┌──────────────────────────┐
│  iOS app (Simulator)    │  ───────────────────────────────▶ │  uvicorn engine.app:app  │
│                         │   ChatRequest (JSON)               │      :8000 (local)       │
│  Chat/ (new, isolated)  │  ◀─────────────────────────────── │                          │
│   View → ViewModel →    │   event: parsed_fields|questions|  │  Engine (stateless)      │
│   FlyerChatClient       │   design_brief|review|concepts|    │   GLM-5.2 (text)         │
│                         │   refined|resized|error            │   nano-banana-pro (img)  │
└─────────────────────────┘                                    └──────────────────────────┘
         wizard / Worker / credits / CloudKit  ── untouched ──
```

- **Run the engine:** `uvicorn engine.app:app --port 8000` from repo root (needs `OPENROUTER_API_KEY` in `.env`). Add `scripts/run-engine.sh` wrapper + README note. (uvicorn 0.49 / fastapi 0.137 already in `.venv`.)
- **ATS:** add `NSAppTransportSecurity → NSAllowsLocalNetworking = true` to `FlyGen/FlyGen/Info.plist` so the Simulator may use cleartext `http://localhost`.
- **Isolation:** all new code under `FlyGen/FlyGen/Chat/`. No edits to the wizard, `OpenRouterService`, credits, or CloudKit.

## Wire contract (client implements)

**Request — `POST /chat`, body `ChatRequest`** (send only the fields relevant to the turn):

```
message?, action?(describe|answers|approve|refine|resize),
brief?(ExtractedBrief echoed back), answers?({field:value}),
instruction?, prior_image_b64?, aspect_ratio?,
field_overrides?({key:value}), decision_overrides?({key:option})
```

**Response — `text/event-stream`**, frames `event: <kind>\ndata: <json>\n\n`:

| `kind` | Payload | UI |
|---|---|---|
| `parsed_fields` | `ExtractedBrief` (snake_case; incl. `field_sources`) | "Here's what I got" card with **stated/inferred** badges |
| `questions` | `{questions:[{field,text}]}` (≤3, **no options**) | Question card, one free-text input per question → `answers{field:value}` |
| `design_brief` | `{notes, checklist[], recommendations[]}` | Collapsible "Design notes" |
| `review` | `{fields:[{key,value,source}], decisions:[{key,label,value,options[],reason}], plan}` | **Approval card**: editable fields + each decision as a chooser over `options[]` |
| `concepts` | `[{version_id, image_base64, error?}]` (3) | 3 image cards; pick one |
| `refined` / `resized` | `{version_id, image_base64, error?}` | Replace/append the image |
| `error` | string | Error bubble + Retry |

**State round-trip:** keep the most recent `ExtractedBrief` from `parsed_fields`; resend it verbatim as `brief` on every later turn. `approve` sends `brief` + `field_overrides` + `decision_overrides` + `answers`. `refine`/`resize` send the chosen concept's base64 as `prior_image_b64` (+ `instruction` / `aspect_ratio`).

## Turn flow

```
describe(message)
  → parsed_fields  [→ questions  ▮GATE: wait for answers]
answers({field:value})                      (resend brief)
  → parsed_fields  [→ questions ▮ if still gaps]
  → design_brief → review                   ▮GATE: wait for approval
approve(field_overrides, decision_overrides) (resend brief + answers)
  → concepts (×3)
refine(instruction) / resize(aspect_ratio)   (send chosen concept b64)
  → refined / resized
```

Refine is image-to-image off the chosen PNG, so the visual decisions ride along in the image (the stateless rebuild from `brief` alone doesn't need to re-carry palette/format).

## iOS components (all new, under `Chat/`)

| File | Responsibility |
|---|---|
| `ChatDTOs.swift` | `Codable` wire types: `ChatRequest`, `ExtractedBriefDTO` (snake_case `CodingKeys`, all-optional, lossless round-trip), `QuestionSet`/`Question`, `DesignBriefDTO`, `ReviewProposalDTO`/`FieldProposal`/`DecisionProposal`, `ConceptDTO`; `SSEEvent` kind enum |
| `FlyerChatClient.swift` | `func stream(_ req: ChatRequest) -> AsyncThrowingStream<SSEEvent>` over `URLSession.bytes`; base-URL constant (`http://localhost:8000`); long resource timeout (~300s) for image gen; SSE line parser |
| `FlyerChatViewModel.swift` | `@MainActor ObservableObject`: `transcript: [ChatBubble]`, current `brief`/`answers`, `send/answer/approve/refine/resize`; maps each `SSEEvent` → bubble; tracks the active gate |
| `FlyerChatView.swift` (+ subviews) | Scrollable transcript + composer; cells `ParsedFieldsCard`, `QuestionsCard`, `ReviewCard`, `ConceptsCard`, `TypingIndicator` |
| Home entry | "Chat (Beta)" card on `HomeTab` presenting `FlyerChatView` full-screen |
| `Info.plist` | ATS `NSAllowsLocalNetworking` |
| `scripts/run-engine.sh` | `uvicorn engine.app:app --port 8000` convenience wrapper |

Reuse where natural: existing `AspectRatio` cases for the resize chooser; existing save-to-Photos util for exporting a concept. Chat DTOs stay **separate** from `FlyerProject` (the engine owns project compilation).

## Error handling & latency UX

- Per-stage typing indicator: "Reading your idea…", "Designing…", "Generating 3 concepts — ~1–2 min".
- `error` events and transport failures → inline error bubble with **Retry**; on connection-refused, hint "is the engine running on :8000?".
- Decode failures are logged and surfaced as an error bubble (don't crash the transcript).

## Testing

- **Manual, in-app:** run the engine locally, drive a full describe→approve→concepts→refine/resize conversation on the Simulator.
- **Engine:** existing suite stays green (46 tests). Optional: one `test_app.py` assertion that a `describe` turn streams the expected `event:` kinds. No engine behavior changes.
- No Swift unit tests (per decision).

## Non-goals (YAGNI)

No chat persistence, no credits/subscription, no CloudKit sync, no brand-kit auto-fill, no device/LAN/deploy, no replacing the wizard, no mockup-perfect styling, no Swift test suite.

## Open follow-ups (post-prototype, not now)

- Server-supplied question chips (e.g. `destination`: Instagram/Print) — engine currently sends text only.
- Decision overrides carried through refine via persisted project state.
- Deploy engine for on-device testing.
