import json
from dataclasses import is_dataclass, asdict
from typing import Optional, List
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from engine.llm import get_client
from engine.orchestrator import Engine
from engine.schema import ExtractedBrief

app = FastAPI()


class ChatIn(BaseModel):
    message: Optional[str] = None
    action: Optional[str] = None       # describe | answers | approve | refine | resize
    stage: Optional[str] = None        # "design" => answers to the design brief's must-fix questions
    brief: Optional[dict] = None       # accumulated ExtractedBrief (state in/out)
    answers: Optional[dict] = None
    instruction: Optional[str] = None
    prior_image_path: Optional[str] = None
    prior_image_b64: Optional[str] = None    # concepts return base64; send it back to refine/resize
    aspect_ratio: Optional[str] = None
    field_overrides: Optional[dict] = None       # user's confirmed/edited content fields
    decision_overrides: Optional[dict] = None    # user's confirmed/overridden design decisions
    user_photos_b64: Optional[List[str]] = None  # uploaded source photos (sent on the approve turn)


def get_generator():
    """Lazily build the real image generator (only for actions that generate).
    use_openrouter=True so it reads OPENROUTER_API_KEY and maps logical model ids
    (e.g. nano-banana-pro -> google/gemini-3-pro-image-preview) to OpenRouter."""
    from image_generator import FlyerImageGenerator
    return FlyerImageGenerator(use_openrouter=True)


def run_turn(body: ChatIn):
    action = (body.action or "describe").lower()
    needs_gen = action in ("approve", "refine", "resize")
    eng = Engine(client=get_client(), generator=get_generator() if needs_gen else None)
    if body.brief:
        eng.brief = ExtractedBrief(**body.brief)
    if body.answers:
        eng.answers = dict(body.answers)

    if action == "answers":
        if (body.stage or "").lower() == "design":
            return eng.handle_design_answers(body.answers or {})
        return eng.handle_answers(body.answers or {})
    if action == "approve":
        return eng.handle_approval(field_overrides=body.field_overrides,
                                   decision_overrides=body.decision_overrides,
                                   answers=body.answers or {},
                                   user_photos_b64=body.user_photos_b64)
    if action == "refine":
        return eng.handle_refine(body.prior_image_path, body.instruction or "",
                                 prior_image_b64=body.prior_image_b64)
    if action == "resize":
        return eng.handle_resize(body.prior_image_path, body.aspect_ratio or "",
                                 prior_image_b64=body.prior_image_b64)
    return eng.handle_user_message(body.message or "")


def _to_jsonable(obj):
    if obj is None or isinstance(obj, (str, int, float, bool)):
        return obj
    if isinstance(obj, BaseModel):
        return obj.model_dump()
    if is_dataclass(obj):
        return asdict(obj)
    if isinstance(obj, dict):
        return {k: _to_jsonable(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_to_jsonable(v) for v in obj]
    return getattr(obj, "__dict__", str(obj))


def _sse(events):
    for e in events:
        yield f"event: {e.kind}\ndata: {json.dumps(_to_jsonable(e.payload), default=str)}\n\n"


@app.post("/chat")
def chat(body: ChatIn):
    return StreamingResponse(_sse(run_turn(body)), media_type="text/event-stream")
