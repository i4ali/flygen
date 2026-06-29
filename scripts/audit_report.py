#!/usr/bin/env python3
"""Distill audit_turn1.json + audit_deep.json into a readable digest plus deterministic
red-flag checks (reusing the engine's own contact detectors)."""
import json
from engine.schema import is_valid_website, looks_like_phone, looks_like_email, is_non_value

CONTACT = ("phone", "email", "website")


def misrouted(slots: dict) -> list:
    """Contact values sitting in the wrong slot — the class of bug we fixed."""
    out = []
    for k in CONTACT:
        v = slots.get(k)
        if not v:
            continue
        if k == "website" and (looks_like_phone(v) or looks_like_email(v)):
            out.append(f"website holds a {'phone' if looks_like_phone(v) else 'email'}: {v!r}")
        if k == "phone" and looks_like_email(v):
            out.append(f"phone holds an email: {v!r}")
        if k == "email" and looks_like_phone(v):
            out.append(f"email holds a phone: {v!r}")
    return out


def nonvalue_slots(slots: dict) -> list:
    return [f"{k}={v!r}" for k, v in slots.items() if k != "category" and is_non_value(v)]


def turn1():
    data = json.load(open("audit_turn1.json"))
    print(f"\n{'='*90}\nTURN-1 PASS — {len(data)} prompts\n{'='*90}")
    flags = []
    for r in data:
        if r.get("error"):
            flags.append((r["prompt"], f"ERROR: {r['error']}"))
            continue
        slots = r.get("slots") or {}
        qs = r.get("questions") or []
        content_qs = [q for q in qs if q.get("field") != "format"]
        print(f"\n• [{r.get('category')}] {r['prompt'][:78]}")
        print(f"    slots: {json.dumps(slots, ensure_ascii=False)}")
        for q in content_qs:
            print(f"    Q[{q.get('field')}]: {q.get('text')}")
        # red flags
        for m in misrouted(slots):
            flags.append((r["prompt"], "MISROUTED " + m))
        for nv in nonvalue_slots(slots):
            flags.append((r["prompt"], "NON-VALUE in slot " + nv))
        if r.get("section", "").startswith("FULLY") and len(content_qs) > 1:
            flags.append((r["prompt"], f"OVER-ASK: {len(content_qs)} content Qs on a fully-specified brief"))
        if not slots.get("category"):
            flags.append((r["prompt"], "no category"))
    return flags


def deep():
    data = json.load(open("audit_deep.json"))
    print(f"\n{'='*90}\nDEEP PASS — {len(data)} prompts (full flow to review)\n{'='*90}")
    flags = []
    for t in data:
        if t.get("error"):
            flags.append((t["prompt"], f"ERROR: {t['error']}"))
            continue
        turns = t.get("turns") or []
        review = None
        for tn in turns:
            if tn.get("review"):
                review = tn["review"]
        reached = review is not None
        fb = t.get("final_brief") or {}
        slots = {k: fb.get(k) for k in
                 ("category", "headline", "subheadline", "body_text", "date", "time",
                  "venue_name", "address", "price", "discount_text", "cta_text",
                  "phone", "email", "website") if fb.get(k)}
        print(f"\n• {t['prompt'][:78]}")
        print(f"    turns={len(turns)}  reached_review={reached}  incomplete={t.get('incomplete', False)}")
        # questions asked across turns
        for tn in turns:
            for q in (tn.get("questions") or []):
                print(f"    turn{tn['n']} Q[{q.get('field')}/{q.get('stage')}]: {q.get('text')}")
        print(f"    final slots: {json.dumps(slots, ensure_ascii=False)}")
        if review:
            warns = [(fp.get("key"), fp.get("value"), fp.get("warning"))
                     for fp in (review.get("fields") or []) if fp.get("warning")]
            decs = {d.get("key"): d.get("value") for d in (review.get("decisions") or [])
                    if isinstance(d, dict)}
            print(f"    review warnings: {warns or 'none'}")
            print(f"    decisions: {json.dumps(decs, ensure_ascii=False)}")
            # flag bogus warnings: a warning on a value that's actually a valid phone/email/url
            for key, val, warn in warns:
                if key == "website" and (looks_like_phone(val) or looks_like_email(val) or is_valid_website(val)):
                    flags.append((t["prompt"], f"BOGUS WARNING on {key}={val!r}"))
        # red flags
        if not reached:
            flags.append((t["prompt"], "did NOT reach review"))
        for m in misrouted(slots):
            flags.append((t["prompt"], "MISROUTED " + m))
        for nv in nonvalue_slots(slots):
            flags.append((t["prompt"], "NON-VALUE in slot " + nv))
    return flags


if __name__ == "__main__":
    f1 = turn1()
    f2 = deep()
    print(f"\n{'='*90}\nRED FLAGS ({len(f1) + len(f2)})\n{'='*90}")
    for p, m in f1 + f2:
        print(f"  ⚑ {m}\n      ↳ {p[:80]}")
    if not (f1 or f2):
        print("  none")
