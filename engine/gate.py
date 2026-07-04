"""Cheap front-door gate: is the user's message a flyer request, or something else?

A tiny classification call on a cheap model (see engine/config.GATE_MODEL) that runs BEFORE
the expensive design brain. Non-flyer messages - greetings, "what can you do?", small talk,
off-topic asks - are deflected without ever paying for a design turn.

The gate is biased HARD toward "flyer": only an explicit `false` from the model deflects.
A null, a missing field, a garbled reply, or a transport error all fail OPEN (treated as a
flyer). The failure math is deliberately asymmetric - a false "not a flyer" turns a real
customer away, while a false "is a flyer" costs at most one wasted design call - so when in
doubt we always route to the designer.
"""
import logging
from typing import Optional
from pydantic import BaseModel
from engine.config import GATE_MODEL

log = logging.getLogger(__name__)

GATE_SYSTEM = (
    "You are the router for a flyer-design chat. Decide whether the user's latest message is an "
    "attempt to CREATE, DESCRIBE, or EDIT a flyer - this includes flyer content or details "
    "(a headline, event, sale, date, venue, etc.) and short answers to a design question - or "
    "whether it is something ELSE: a general question about the app or what you can do, a "
    "greeting, thanks, small talk, or an off-topic request.\n"
    "Bias STRONGLY toward flyer. Set is_flyer=false ONLY when the message is clearly NOT an "
    "attempt to make a flyer. Anything that could plausibly begin or continue a flyer is "
    "is_flyer=true. When in doubt, is_flyer=true."
)


class GateVerdict(BaseModel):
    # Optional + default None so a missing or unparseable value becomes None (not a validation
    # error). Only an explicit False deflects; see is_flyer_request's `is not False`.
    is_flyer: Optional[bool] = None


def is_flyer_request(text: str, client, model: str = GATE_MODEL) -> bool:
    """True -> route to the design brain; False -> deflect. Fails OPEN (True) on any error.

    `client` is the same OpenRouter shim the design brain uses; only the model differs, so no
    second client is constructed. No thinking/effort is passed, so the classification stays fast.
    """
    try:
        resp = client.messages.parse(
            model=model,
            system=GATE_SYSTEM,
            messages=[{"role": "user", "content": text}],
            output_format=GateVerdict,
            max_tokens=256,
        )
        # Only an explicit false deflects; None / True / anything odd -> treat as a flyer.
        return resp.parsed_output.is_flyer is not False
    except Exception as e:                       # transport hiccup, bad JSON, provider 5xx, ...
        log.warning("gate classification failed, failing open to flyer: %s", e)
        return True
