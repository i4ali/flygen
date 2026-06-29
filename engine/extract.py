from engine.schema import ExtractedBrief, reconcile_field_sources, sanitize_brief
from engine.config import MODEL, THINKING, EFFORT, MAX_TOKENS
from engine.llm import get_client, EXTRACT_SYSTEM


def extract_brief(user_text: str, client=None) -> ExtractedBrief:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        system=EXTRACT_SYSTEM,
        messages=[{"role": "user", "content": user_text}],
        thinking=THINKING,
        output_config=EFFORT,
        output_format=ExtractedBrief,
    )
    # The model's stated/inferred guess is unreliable; deterministically upgrade any field
    # whose value is verbatim in the user's text (precise, never downgrades). Then drop any
    # meta/non-answer the model may have captured so it never reaches review or the flyer.
    return sanitize_brief(reconcile_field_sources(resp.parsed_output, user_text))
