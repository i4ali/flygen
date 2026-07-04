# Design - Cheap front-door gate: deflect non-flyer messages before the design brain

- **Date:** 2026-07-02
- **Status:** Approved + implemented (brainstorm 2026-07-02).
- **Builds on:** `2026-06-30-one-brain-interpreter-design.md` (§4.1 sanctions a cheap pass in front of the expensive design pass; this is that cheap pass, used as a gate).

---

## 1. Problem

Every typed message goes straight to the expensive design brain (`handle_user_message` -> `interpret()`), which is **forced** to return a flyer `TurnResult`. So a non-flyer message - a product question, a greeting, small talk, off-topic - produces two bad outcomes:

1. **Wrong output.** The brain fabricates a flyer brief. Observed: "Do you accept photos as samples?" rendered a "Here's what I got -> category: Announcement (INFERRED)" card for a message that never described a flyer.
2. **Wasted cost.** A full design-director turn (with high-effort thinking) fires to answer what is essentially an FAQ.

## 2. Decision

Put a **cheap classifier in front** of the design brain. It decides flyer-vs-not; non-flyer messages are **deflected with a fixed, firm line** and never reach the expensive brain. Settled in brainstorm:

- **Deflect, don't answer (hard boundary).** Non-flyer messages get one consistent line ("I only design flyers here..."), not a helpful answer. This keeps the product scoped to flyers, needs **no capabilities brief to maintain**, and carries **zero risk of a wrong capability/price claim**.
- **A second, cheaper model - not a heuristic.** A keyword/regex gate would re-introduce exactly the natural-language-parsing pile the one-brain design deleted. A cheap LLM gate is in the spirit of the sanctioned cheap pass (§4.1).
- **The big brain is untouched.** No `TurnResult` change, no triage prompt, no rubric change. It stays a pure flyer designer and never sees a non-flyer message.

## 3. The load-bearing rule: fail open to "flyer"

The failure math is asymmetric. A false **"not a flyer"** turns a real customer away; a false **"is a flyer"** costs at most one wasted design call. So the gate is biased hard toward flyer, in the prompt **and** in the parse:

> Only an explicit `false` deflects. A `null`, a missing field, garbled JSON, or a transport error all fail **open** (treated as a flyer).

Encoded as `GateVerdict.is_flyer: Optional[bool] = None` + `return verdict.is_flyer is not False`, wrapped in a try/except that returns `True` on any exception.

## 4. Architecture

```
user types a message
        |
   [ gate: is_flyer_request() ]   -- GATE_MODEL (google/gemini-2.5-flash) via the existing OpenRouter shim
        |
   explicit false --------> Event("note", DEFLECTION)   (deflection bubble; interpret() skipped)
        |
   true / null / error ---> _run() -> interpret() -> parsed_fields / questions / review   (unchanged)
```

- **`engine/gate.py`** (new) - `is_flyer_request(text, client) -> bool`. One `client.messages.parse` call with a tiny `{is_flyer}` schema and a strongly-biased system prompt. Reuses the same OpenRouter client (only the model differs); no thinking/effort, so it stays fast (~0.5-1s live).
- **`engine/config.py`** - `GATE_MODEL = "google/gemini-2.5-flash"`. An OpenRouter slug passed straight through the shim (its `_MODEL_MAP` falls through for unknown slugs). One-line swap to A/B another model.
- **`engine/orchestrator.py`** - `handle_user_message` gates first; explicit-not-flyer -> yield one `note` event with `DEFLECTION` and return. Gate injected via `gate_fn=None` for tests. **Only the typed "describe" turn is gated** - `answers`/`approve`/`refine`/`resize` are always mid-flyer and bypass it.
- **iOS - no changes.** The client already decodes a `note` SSE event into a plain assistant bubble (`ChatModels.swift` `case "note"` -> `FlyerChatViewModel` `.note` -> `.assistant`). Emitting the deflection as `note` reuses that path; nothing to rebuild.

## 5. Trade-offs (accepted)

- The gate adds one cheap round-trip **before real flyer requests too** (~0.5-1s, a fraction of a cent). It nets positive on cost once even a few percent of traffic is non-flyer; for a user who only ever sends flyer requests it is a small tax. Accepted for the cost + hard-boundary win.
- The gate's judgment is the load-bearing part; the fail-open rule is the guardrail. Live smoke: 8/8 representative messages classified correctly, including the screenshot case and a thin-but-real brief.

## 6. Testing

- `tests/engine/test_gate.py` - true -> route, explicit false -> deflect, **null -> flyer**, **exception -> flyer**, and the call uses `GATE_MODEL` + `GateVerdict`.
- `tests/engine/test_orchestrator.py` - a deflected message emits exactly `["note"]` and **interpret never runs**; existing brain tests inject `gate_fn=lambda: True` to bypass the gate. Full engine suite: 88 passed.
- Live smoke (`scratchpad/gate_smoke.py`, hits OpenRouter) + a real gate + real orchestrator end-to-end confirming the screenshot message deflects with the brief left empty.

## 7. Non-goals

- Answering product questions (deflect-only was chosen); no capabilities brief.
- Reducing the design brain's own cost or preserving an in-progress brief across a typed question (the composer already resets to a new flyer by design).
- Any change to `TurnResult`, the design prompt, rubrics, or the image pipeline.

## 8. Deploy note

The engine changed, so a **Release** build needs a Cloud Run redeploy before it uses the gate (`gcloud run deploy flygen-engine --source . ...`; env already carries `OPENROUTER_API_KEY`). Debug builds hit the local engine - restart `run-engine.sh` to pick up the new code.
