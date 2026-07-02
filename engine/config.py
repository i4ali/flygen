"""Engine configuration — the single place to change the text model and how hard it thinks.

The engine reaches the model through the OpenRouter shim (engine/openrouter_client.py), so
the model is named in two parts: MODEL is the logical id used across the engine, and
MODEL_SLUG is the OpenRouter route it maps to. To switch models, change both.
"""

# --- Text model (the intake + design brain) -------------------------------------------
# To use a different model, change these two lines (confirm the slug at
# https://openrouter.ai/models).
MODEL = "claude-sonnet-4-6"                   # logical id used throughout the engine
MODEL_SLUG = "anthropic/claude-sonnet-4.6"    # the OpenRouter route MODEL maps to

# --- Reasoning ------------------------------------------------------------------------
# Adaptive thinking lets the model decide how much to reason; effort sets the ceiling.
# Raise EFFORT to make every text turn deliberate harder.
THINKING = {"type": "adaptive"}
EFFORT = {"effort": "high"}                    # how hard to think: "low" | "medium" | "high" | "max"

# Output budget per turn. The OpenRouter shim carves the thinking budget out of this, so it
# must leave room for BOTH the reasoning pass and the JSON answer - too small truncates the
# JSON (the failure mode that surfaces as a Pydantic "invalid JSON" error in the app). The shim
# also retries once with a larger budget on a truncated turn, so this is the comfortable first
# try, not the hard ceiling; the largest briefs (long multi-day programs) need the headroom.
MAX_TOKENS = 16000
