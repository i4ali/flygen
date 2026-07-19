# Real QR codes on flyers - design

**Date:** 2026-07-19
**Status:** Approved by owner

## Goal

Let users put a real, scannable QR code on any flyer in the chat flow. Owner verified
assumption: the QR itself is a Python-engine job (`qrcode` + PIL composite) - image models only
draw decorative, non-scanning QR patterns (the demo flyers prove it). The LLM brain's role is
limited to capturing intent and target; the image-model prompt's role is limited to keeping the
target corner clear.

## Product decisions (owner)

- **Content kinds:** website URL, phone (call `tel:` or WhatsApp `wa.me` - brain asks which,
  once), Instagram handle. No email. Python builds the final URI deterministically; the brain
  emits only `kind + value`.
- **Trigger:** explicit ask anytime, PLUS a one-time proactive offer when the brief contains a
  website/phone/social handle - always as a question, never silently added (no-silent-defaults).
- **Placement:** bottom-right default; any of the 4 corners reachable by saying it in chat.
  Style: black QR on white padding, 15% of flyer width (wizard-era constants kept).
- **Scope:** all chat flows - creation, follow-up edits (QR survives edits), annotate, resize,
  and uploaded/reused flyers.
- **Fake QRs banned globally:** every generation prompt now forbids model-drawn QR codes, even
  when no real QR is configured.

## Architecture (Approach A - engine-side, approved)

QR state is its own small wire object, NOT part of the brief (reference flyers have no brief;
iOS's `ExtractedBriefDTO` is typed so unknown brief keys would be dropped on round-trip):

```
qr: { enabled: bool, kind: "website"|"phone"|"whatsapp"|"instagram", value: str, corner: str }
```

- **iOS** stores it per chat thread beside the brief and echoes it on every action; engine
  returns updates via an SSE event. Small DTO + plumbing only - no UI.
- **Writers (engine-side only):**
  1. The **brain** (describe path): new TurnResult field + rubric (offer once when contact
     facts exist; set only after explicit user yes; corner changes; removal).
  2. A **scoped extractor** on the brain-free refine/reference paths: fires ONLY when the
     instruction mentions "QR" (case-insensitive); one cheap Gemini-Flash call (same model as
     the non-flyer gate) returning add/move/remove + kind/value/corner. Preserves the
     trust-the-model stance for every instruction that doesn't mention QR.
- **Compositing:** final step of `approve` / `refine` / `resize` / `reference` when
  `qr.enabled`. `qr_service.py` gains bytes-in/bytes-out composite, 4-corner support, and the
  URI builder. Same corner + same size math means an edit's mangled baked-in QR is exactly
  covered by the fresh composite.
- **Prompts:** when QR enabled - "keep the {corner} area clear; do not draw any QR code";
  globally - never render QR codes.

## Edge cases

- Malformed website: keep + flag (face-value rule); encode what the user approved.
- Extractor failure/ambiguity: fail open - treat as a normal edit, never block generation.
- Composite failure: return the un-QR'd flyer with a note event rather than failing the turn.
- Padding scales with QR size (min 8px) so 4K outputs don't get a hairline border.

## Testing & rollout

No test ceremony: quick local scripts for URI builder + composite, one curl through local
`/chat`, iOS build-verify, owner simulator eyeball. Requires Cloud Run redeploy for Release
builds (per project CLAUDE.md).
