from models import FlyerCategory

# Model + reasoning settings live in one place — see engine/config.py. Re-exported here so
# existing `from engine.llm import MODEL` call sites keep working.
from engine.config import MODEL, MODEL_SLUG, THINKING, EFFORT, MAX_TOKENS  # noqa: F401


def get_client():
    """The engine's text model via OpenRouter (uses OPENROUTER_API_KEY from .env / env)."""
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except Exception:
        pass
    from engine.openrouter_client import OpenRouterClient
    return OpenRouterClient()

def _category_catalog() -> str:
    return "\n".join(f"- {c.value}: {c.display_name}" for c in FlyerCategory)


# One large, stable system block -> cached (ephemeral). Persona + the full category
# catalog are baked in here so the cached prefix is byte-identical and reused across
# the extraction and design-brief turns (only the per-turn user message and effort vary).
EXTRACT_SYSTEM = [{
    "type": "text",
    "text": (
        "You are a senior graphic designer's intake assistant. Extract structured "
        "fields from the user's plain-language flyer request, and when planning apply "
        "senior-designer judgment. Infer the single best FlyerCategory from this "
        "catalog (use the exact value on the left):\n"
        f"{_category_catalog()}\n\n"
        "Leave fields you cannot infer null — do not invent them."
        "\n\nAlso capture `destination` if the user names a channel or medium (e.g. Instagram, "
        "story, print/printed, poster) — otherwise leave it null. In `field_sources`, map every "
        "field you populate to either \"stated\" (the user explicitly provided it) or \"inferred\" "
        "(you deduced it, e.g. the category)."
    ),
    "cache_control": {"type": "ephemeral"},
}]
