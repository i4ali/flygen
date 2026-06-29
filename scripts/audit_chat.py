#!/usr/bin/env python3
"""Drive the running engine (/chat on :8000) over the test prompts and capture each turn's
structured output for auditing. No image generation — stops at the review gate.

Usage:
    python scripts/audit_chat.py smoke      # one prompt, full flow (verify the harness)
    python scripts/audit_chat.py turn1      # ALL prompts, describe turn only -> audit_turn1.json
    python scripts/audit_chat.py deep       # representative subset, full flow -> audit_deep.json
"""
import json
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE = "http://localhost:8000/chat"
PROMPTS_FILE = "test-prompts.txt"
TURN_CAP = 6  # safety: the flow asks-once, so review arrives well within this

# Representative subset for the deep (full-flow) pass — one per category/section.
DEEP_SUBSET = [
    "Grand opening of Nova Nail Bar next weekend, first 10 people get 50% off",
    "Flyer for a neighborhood yard sale",
    "Summer clearance at Bloom Boutique — 40% off all dresses this weekend only, Sat & Sun 10-6",
    "Pizza & Pints fundraiser, Saturday June 28 6-9pm at Riverside Hall, $25 a head, RSVP to events@riverside.org or call 555-0142",
    "Now hiring baristas at Daybreak Coffee — part-time, flexible hours, apply in store at 88 Front St",
    "An evening with singer-songwriter Nora Vale, Saturday March 14 at 8pm, The Listening Room, $25",
    "Open house this Sunday 1-4pm at 14 Maple Court, modern 3-bed with a renovated kitchen, hosted by Sarah Lin Realty",
    "Live music night with some great local bands, coming soon at the pub, free entry",
]


# --- SSE transport ---------------------------------------------------------
def post_turn(body: dict) -> list:
    """POST one turn to /chat and parse the SSE stream into [(kind, payload), ...]."""
    data = json.dumps(body).encode()
    req = urllib.request.Request(BASE, data=data, headers={"Content-Type": "application/json"})
    events, kind = [], None
    with urllib.request.urlopen(req, timeout=600) as resp:
        for raw in resp:
            line = raw.decode("utf-8").rstrip("\n")
            if line.startswith("event:"):
                kind = line[6:].strip()
            elif line.startswith("data:"):
                events.append((kind, json.loads(line[5:].strip())))
    return events


def _last(events, kind):
    """Latest payload of a kind, or None."""
    hits = [p for k, p in events if k == kind]
    return hits[-1] if hits else None


def _questions(events):
    """All question dicts emitted this turn, with their stage."""
    out = []
    for k, p in events:
        if k == "questions":
            for q in (p.get("questions") or []):
                out.append({**q, "_stage": p.get("stage", "gaps")})
    return out


# --- auto-answerer: plausible, deterministic answers so the flow reaches review ---
_ANSWER_TABLE = {
    "format": "4:5",
    "date": "Saturday, July 12, 2026",
    "time": "6:00–9:00pm",
    "venue_name": "Riverside Community Center",
    "address": "142 Riverside Ave",
    "price": "$10",
    "discount_text": "40% off everything",
    "cta_text": "RSVP at riverside.org/events",
    "destination": "Instagram",
    "body_text": "All proceeds benefit the Riverside Youth Center.",
    "subheadline": "An evening of food, fun, and community",
    "headline": "Join Us",
    "cause": "Riverside Youth Center",
    "beneficiary": "Riverside Youth Center",
    "organization": "Riverside Youth Center",
    "org_name": "Riverside Youth Center",
    "host": "Riverside Youth Center",
    "hosted_by": "Riverside Youth Center",
}
# Contact-family keys: answer with a PHONE on purpose, to live-test the contact-routing fix
# (a phone given to a website/contact question must land in `phone`, never flagged as a bad URL).
_CONTACT_KEYS = {"website", "phone", "email", "link", "url", "redeem_link",
                 "contact", "contact_info", "contact_details", "contact_phone"}


def answer_for(field: str) -> str:
    """Realistic value for known content fields; a phone for any contact channel (to test
    routing); a decline ('No', skipped as a non-value) for unknown extra clarifications — so the
    brief stays clean and we still reach review via the honest-gap path."""
    f = (field or "").strip().lower()
    if f in _CONTACT_KEYS:
        return "555-0142"
    if f in _ANSWER_TABLE:
        return _ANSWER_TABLE[f]
    return "No"


# --- driving ---------------------------------------------------------------
def describe(prompt: str) -> list:
    return post_turn({"action": "describe", "message": prompt})


def run_full_flow(prompt: str) -> dict:
    """describe -> keep answering whatever is asked -> stop at review (or turn cap)."""
    trace = {"prompt": prompt, "turns": []}
    events = describe(prompt)
    brief = _last(events, "parsed_fields")
    answers_acc = {}
    turn = 0
    while True:
        turn += 1
        qs = _questions(events)
        trace["turns"].append({
            "n": turn,
            "questions": [{"field": q.get("field"), "text": q.get("text"),
                           "stage": q.get("_stage"),
                           "has_options": bool(q.get("options"))} for q in qs],
            "design_brief": _last(events, "design_brief"),
            "review": _last(events, "review"),
            "note": _last(events, "note"),
            "error": _last(events, "error"),
        })
        if _last(events, "review") is not None:
            trace["final_brief"] = brief
            return trace
        if not qs or turn >= TURN_CAP:
            trace["final_brief"] = brief
            trace["incomplete"] = True
            return trace
        # answer every question asked this turn
        stage = qs[0].get("_stage", "gaps")
        new_answers = {q["field"]: answer_for(q["field"]) for q in qs if q.get("field")}
        answers_acc.update(new_answers)
        body = {"action": "answers", "brief": brief, "answers": answers_acc}
        if stage == "design":
            body["stage"] = "design"
        events = post_turn(body)
        nb = _last(events, "parsed_fields")
        if nb is not None:
            brief = nb


# --- prompt parsing --------------------------------------------------------
def load_prompts():
    """Return [(section, prompt)], deduped, preserving order."""
    section = "?"
    seen, out = set(), []
    sec_re = re.compile(r"^\d+\.\s+(.*?)(?:\s+→.*)?$")
    with open(PROMPTS_FILE, encoding="utf-8") as f:
        for line in f:
            s = line.rstrip("\n")
            m = sec_re.match(s.strip())
            if m and "→" in s or (m and s.strip()[0].isdigit() and not s.strip().startswith(">")):
                section = m.group(1).strip()
                continue
            t = s.strip()
            if t.startswith(">"):
                p = t[1:].strip()
                if p and p not in seen:
                    seen.add(p)
                    out.append((section, p))
    return out


# --- field-slot view for quick scanning of extraction correctness ----------
_SLOTS = ["category", "headline", "subheadline", "date", "time", "venue_name",
          "address", "price", "discount_text", "cta_text", "phone", "email", "website"]


def brief_slots(brief: dict) -> dict:
    return {k: brief.get(k) for k in _SLOTS if brief.get(k)}


def warnings_of(review: dict) -> list:
    if not review:
        return []
    return [{"key": fp.get("key"), "value": fp.get("value"), "warning": fp.get("warning")}
            for fp in (review.get("fields") or []) if fp.get("warning")]


# --- entry points ----------------------------------------------------------
def cmd_smoke():
    prompt = DEEP_SUBSET[3]  # the fully-specified fundraiser
    print(f"SMOKE: {prompt!r}\n")
    trace = run_full_flow(prompt)
    print(json.dumps(trace, indent=2, ensure_ascii=False)[:6000])


def cmd_turn1():
    prompts = load_prompts()
    print(f"turn-1 pass over {len(prompts)} prompts (concurrency 5)…")
    results = [None] * len(prompts)

    def work(i, section, prompt):
        try:
            events = describe(prompt)
            brief = _last(events, "parsed_fields") or {}
            return i, {
                "section": section, "prompt": prompt,
                "category": brief.get("category"),
                "slots": brief_slots(brief),
                "field_sources": brief.get("field_sources"),
                "questions": [{"field": q.get("field"), "text": q.get("text"),
                               "has_options": bool(q.get("options"))}
                              for q in _questions(events)],
                "error": _last(events, "error"),
            }
        except Exception as e:
            return i, {"section": section, "prompt": prompt, "error": f"{type(e).__name__}: {e}"}

    with ThreadPoolExecutor(max_workers=5) as ex:
        futs = [ex.submit(work, i, sec, p) for i, (sec, p) in enumerate(prompts)]
        done = 0
        for fut in as_completed(futs):
            i, res = fut.result()
            results[i] = res
            done += 1
            print(f"  [{done}/{len(prompts)}] {res['prompt'][:60]}")
    with open("audit_turn1.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("wrote audit_turn1.json")


def cmd_deep():
    print(f"deep full-flow pass over {len(DEEP_SUBSET)} prompts…")
    traces = []
    for i, prompt in enumerate(DEEP_SUBSET, 1):
        print(f"  [{i}/{len(DEEP_SUBSET)}] {prompt[:60]}")
        try:
            traces.append(run_full_flow(prompt))
        except Exception as e:
            traces.append({"prompt": prompt, "error": f"{type(e).__name__}: {e}"})
    with open("audit_deep.json", "w", encoding="utf-8") as f:
        json.dump(traces, f, indent=2, ensure_ascii=False)
    print("wrote audit_deep.json")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "smoke"
    {"smoke": cmd_smoke, "turn1": cmd_turn1, "deep": cmd_deep}[cmd]()
