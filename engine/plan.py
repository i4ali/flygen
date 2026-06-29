import json
from models import VisualStyle, Mood
from engine.schema import DesignBrief
from engine.config import MODEL, THINKING, EFFORT, MAX_TOKENS
from engine.llm import get_client, EXTRACT_SYSTEM


def _user_prompt(brief, rubric, answers) -> str:
    return (
        "Apply senior-designer judgment to this specific flyer brief.\n\n"
        f"BRIEF (JSON): {brief.model_dump_json()}\n\n"
        f"CATEGORY CHECKLIST: {rubric.checklist}\n"
        f"VISUAL HIERARCHY: {rubric.hierarchy}\n"
        f"DEFAULT RECOMMENDATIONS: {rubric.recommendations}\n"
        f"PALETTE OPTIONS (pick exactly one, by its text): {rubric.palette_directions}\n"
        f"VISUAL STYLE OPTIONS (pick exactly one): {[s.display_name for s in VisualStyle]}\n"
        f"MOOD OPTIONS (pick exactly one): {[m.display_name for m in Mood]}\n"
        f"USER ANSWERS: {json.dumps(answers)}\n\n"
        "Return a DesignBrief: (1) notes — a short design rationale for this brief; "
        "(2) checklist — the category checklist made concrete for THIS brief (not generic); "
        "(3) recommendations — at least one proactive, specific suggestion a senior designer "
        "would offer (e.g. a layout, hierarchy, or copy improvement); "
        "Take the customer's provided contact details (website, phone, email, address) at FACE "
        "VALUE — never flag a well-formed value as a conflict or something to 'resolve before "
        "production' just because the brand or domain seems unexpected; it's the customer's call. "
        "(4) questions — ONLY genuinely generation-blocking gaps you must ask the client before "
        "designing: a missing or unusable value (e.g. a vague date like 'next weekend' that needs a "
        "concrete one, or no way for people to act/contact). At most 2. Each item MUST have BOTH a "
        "snake_case `field` key AND a `text` — the actual friendly question to show the customer "
        "(e.g. {\"field\": \"date\", \"text\": \"What's the exact date and time of the opening?\"}). "
        "Never return a field without its text. If the brief is workable as-is, return an empty list — "
        "and never put style suggestions here (those belong in recommendations). "
        "(5) recommended_palette, recommended_style, recommended_mood — choose the SINGLE best fit "
        "for THIS brief from the PALETTE / VISUAL STYLE / MOOD OPTIONS above (copy the option text "
        "exactly). These pre-select the customer's review controls, so pick deliberately for the "
        "subject and season — e.g. a deep, cool palette for a winter sale rather than a generic "
        "high-energy default — not a rote first option."
    )


def build_design_brief(brief, rubric, answers=None, client=None) -> DesignBrief:
    """The 'plans like a pro' turn: turn the rubric + specific brief into an applied
    checklist + proactive recommendations. Runs Claude Sonnet 4.6 at high effort with
    adaptive thinking. (effort+parse combination is exercised by the eval harness / manual runs.)"""
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        system=EXTRACT_SYSTEM,
        messages=[{"role": "user", "content": _user_prompt(brief, rubric, answers or {})}],
        thinking=THINKING,
        output_config=EFFORT,
        output_format=DesignBrief,
    )
    return resp.parsed_output
