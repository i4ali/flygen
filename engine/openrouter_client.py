"""Adapter that lets the engine call Claude Sonnet 4.6 through OpenRouter.

OpenRouter is OpenAI-compatible (chat/completions), not the Anthropic Messages API,
so this exposes the small slice of the Anthropic client the engine relies on —
`client.messages.parse(...).parsed_output` — and translates it to an OpenRouter call:
  - system content-blocks  -> a flattened system message
  - output_format (pydantic) -> response_format json_schema + local validation
  - thinking / output_config.effort -> OpenRouter's `reasoning` param
"""
import json
import os
import types as _types
from typing import Union, get_origin, get_args
from openai import OpenAI
from pydantic import BaseModel

from engine.config import MODEL, MODEL_SLUG

_NONE = type(None)
_UNION_TYPE = getattr(_types, "UnionType", None)   # `X | None` syntax (py3.10+); may be absent


def _ts_type(ann) -> str:
    """Render a pydantic field annotation as a compact TypeScript-style type the model follows —
    e.g. Optional[List[str]] -> 'string[] | null'. Stating each field's TYPE (not just its name)
    stops the model emitting a scalar where an array/object is required (the additional_info crash)."""
    origin = get_origin(ann)
    args = get_args(ann)
    if origin is Union or (_UNION_TYPE is not None and origin is _UNION_TYPE):
        parts = [_ts_type(a) for a in args if a is not _NONE]
        ts = parts[0] if len(parts) == 1 else "(" + " | ".join(parts) + ")"
        return f"{ts} | null" if _NONE in args else ts
    if origin in (list, tuple, set):
        return f"{_ts_type(args[0]) if args else 'any'}[]"
    if origin is dict:
        k = _ts_type(args[0]) if args else "string"
        v = _ts_type(args[1]) if len(args) > 1 else "any"
        return f"{{ [key: {k}]: {v} }}"
    if ann is str:
        return "string"
    if ann is bool:
        return "boolean"
    if ann in (int, float):
        return "number"
    if isinstance(ann, type) and issubclass(ann, BaseModel):
        inner = ", ".join(f"{n}: {_ts_type(f.annotation)}" for n, f in ann.model_fields.items())
        return f"{{ {inner} }}"
    return "any"

OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

# Map the engine's logical model id -> OpenRouter slug (both from engine/config.py).
_MODEL_MAP = {MODEL: MODEL_SLUG}


class _Parsed:
    def __init__(self, parsed_output):
        self.parsed_output = parsed_output


def _flatten_system(system):
    if system is None:
        return None
    if isinstance(system, str):
        return system
    if isinstance(system, list):
        return "\n\n".join(b.get("text", "") if isinstance(b, dict) else str(b) for b in system)
    return str(system)


def _flatten_messages(messages):
    out = []
    for m in messages or []:
        content = m.get("content")
        if isinstance(content, list):
            content = "\n".join(b.get("text", "") if isinstance(b, dict) else str(b) for b in content)
        out.append({"role": m.get("role", "user"), "content": content})
    return out


def _reasoning(thinking, output_config):
    effort = (output_config or {}).get("effort")
    if effort:
        return {"effort": effort}
    if thinking and thinking.get("type") == "adaptive":
        return {"effort": "medium"}   # adaptive -> a sensible OpenRouter default
    return None


def _to_model(content, model_cls):
    content = (content or "").strip()
    if content.startswith("```"):
        content = content.strip("`")
        if content[:4].lower() == "json":
            content = content[4:]
        content = content.strip()
    try:
        return model_cls.model_validate_json(content)
    except Exception:
        i, j = content.find("{"), content.rfind("}")
        if i != -1 and j > i:
            return model_cls.model_validate_json(content[i:j + 1])
        raise


class _Messages:
    def __init__(self, oai):
        self._oai = oai

    def _create(self, *, model, messages, max_tokens, reasoning):
        return self._oai.chat.completions.create(
            model=_MODEL_MAP.get(model, model),
            messages=messages,
            max_tokens=max_tokens,
            extra_body={"reasoning": reasoning} if reasoning else None,
        )

    def parse(self, *, model, messages, output_format, system=None,
              max_tokens=2000, thinking=None, output_config=None, **_ignored):
        # OpenRouter's response_format=json_schema is unreliable across providers (it stalls /
        # drops the connection), so we instruct the model to emit JSON and validate locally. We
        # spell out each field's TYPE (not just its name) so the model stops drifting on shape —
        # e.g. returning a bare string where an array is required (the additional_info crash).
        spec = "\n".join(f'- "{name}": {_ts_type(field.annotation)}'
                         for name, field in output_format.model_fields.items())
        instruction = (
            "Return ONLY a single JSON object (no prose, no markdown code fence) with EXACTLY "
            "these keys and value types (TypeScript notation; `| null` means the value may be "
            f"null):\n{spec}\n"
            "Use null for any value you cannot infer. For an array type (ending in `[]`), ALWAYS "
            'return a JSON array — e.g. [] or ["one item"] — never a bare string.'
        )
        sys = _flatten_system(system)
        sys = f"{sys}\n\n{instruction}" if sys else instruction

        oai_messages = [{"role": "system", "content": sys}]
        oai_messages.extend(_flatten_messages(messages))

        reasoning = _reasoning(thinking, output_config)
        resp = self._create(model=model, messages=oai_messages, max_tokens=max_tokens,
                            reasoning=reasoning)
        choice = resp.choices[0]
        # finish_reason == "length" means the model hit the token ceiling and its JSON answer is
        # cut off mid-structure (unparseable). Retry ONCE with more room and lighter reasoning, so
        # the budget goes to the answer rather than the thinking (see engine/config.py MAX_TOKENS).
        if getattr(choice, "finish_reason", None) == "length":
            resp = self._create(model=model, messages=oai_messages, max_tokens=max_tokens * 2,
                                reasoning={"effort": "low"} if reasoning else None)
            choice = resp.choices[0]
        return _Parsed(_to_model(choice.message.content, output_format))


class OpenRouterClient:
    """Drop-in for the engine's use of the Anthropic client, backed by OpenRouter."""

    def __init__(self, api_key=None, base_url=OPENROUTER_BASE_URL):
        api_key = api_key or os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            raise RuntimeError("OPENROUTER_API_KEY not set")
        self._oai = OpenAI(
            api_key=api_key,
            base_url=base_url,
            default_headers={"HTTP-Referer": "https://flyer-generator.app", "X-Title": "Flyer Generator"},
            timeout=180.0,
        )
        self.messages = _Messages(self._oai)
