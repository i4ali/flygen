"""The single design-director call: conversation -> TurnResult."""
import json
from typing import Optional
from engine.turn import TurnResult, validate_decisions
from engine.llm import INTERPRET_SYSTEM, get_client
from engine.config import MODEL, MAX_TOKENS, THINKING, EFFORT
from engine.rubrics import briefing_for

def _user_prompt(prior_brief, user_text, answers, qr=None) -> str:
    parts = []
    if prior_brief:
        parts.append("Conversation so far, as the brief you produced last turn (update it):\n"
                     + json.dumps(prior_brief, ensure_ascii=False))
    if user_text:
        parts.append("User said:\n" + user_text)
    if answers:
        parts.append("User answered your questions:\n" + json.dumps(answers, ensure_ascii=False))
    # QR is standalone state (never in the brief). Always show it - null vs {enabled:false} is how
    # the brain distinguishes "never offered" from "user declined", so the offer stays one-time.
    parts.append("Current QR state (null = never discussed): " + json.dumps(qr))
    # The category may already be known; include its briefing so the model applies it.
    cat = (prior_brief or {}).get("category") or "announcement"
    parts.append("Design briefing for the likely category:\n" + briefing_for(cat))
    parts.append("Return ONE TurnResult JSON. If must-have facts are missing and not inferable, "
                 "status=need_input with questions; otherwise status=ready with decisions, "
                 "creative_elements, and the plan.")
    return "\n\n".join(parts)

def interpret(prior_brief: Optional[dict], user_text: Optional[str],
              answers: Optional[dict], qr: Optional[dict] = None, client=None) -> TurnResult:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        system=INTERPRET_SYSTEM,
        messages=[{"role": "user", "content": _user_prompt(prior_brief, user_text, answers, qr)}],
        thinking=THINKING,
        output_config=EFFORT,
        output_format=TurnResult,
    )
    return validate_decisions(resp.parsed_output)
