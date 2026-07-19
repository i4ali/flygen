"""QR-intent extractor for the brain-free edit paths (refine / reference).

Runs ONLY when the instruction mentions "qr" (case-insensitive) - every other edit stays pure
trust-the-model. One cheap classification call (GATE_MODEL); returns an updated qr state plus
an augmented image-model instruction. Fails OPEN: on any error the edit proceeds unchanged.
"""
import logging
import re
from typing import Optional, Tuple
from pydantic import BaseModel
from engine.config import GATE_MODEL

log = logging.getLogger(__name__)

QR_SYSTEM = (
    "You read one flyer-edit instruction and report what it says about a QR code.\n"
    "Return: action = add | change | remove | none (none = the instruction doesn't concern a "
    "QR code); kind = website|phone|whatsapp|instagram and value = the raw target when stated "
    "(null when not); corner = bottom_right|bottom_left|top_right|top_left when stated.\n"
    "'change' covers moving it or pointing it somewhere new. Do not invent a value."
)


class QRIntent(BaseModel):
    action: Optional[str] = None
    kind: Optional[str] = None
    value: Optional[str] = None
    corner: Optional[str] = None


def mentions_qr(instruction: str) -> bool:
    # "qr" as a word, the dotted form "q.r"/"q.r."/"q. r.", or "qr code"/"qr-code"/"qrcode".
    return bool(re.search(r"\bqr\b|q\.\s*r\.?|qr[- ]?code", instruction or "", re.I))


def qr_update(instruction: str, current: Optional[dict], client) -> Tuple[Optional[dict], str, Optional[str]]:
    """-> (new_state_or_None, instruction_for_image_model, ask_or_None).

    new_state None = leave state as-is. ask = a question to send back instead of generating
    (add-with-no-target). Fail open on any error: (None, instruction, None)."""
    try:
        resp = client.messages.parse(model=GATE_MODEL, system=QR_SYSTEM,
                                     messages=[{"role": "user", "content": instruction}],
                                     output_format=QRIntent, max_tokens=256)
        intent = resp.parsed_output
    except Exception as e:
        log.warning("qr intent failed, treating as plain edit: %s", e)
        return None, instruction, None

    cur = dict(current or {})
    if intent.action == "remove":
        new = {**cur, "enabled": False}
        return new, instruction + "\n\nRemove any QR code from the flyer entirely.", None
    if intent.action in ("add", "change"):
        kind = intent.kind or cur.get("kind")
        value = intent.value or cur.get("value")
        corner = intent.corner or cur.get("corner", "bottom_right")
        if not value:
            return None, instruction, ("Happy to add a QR code - what should it open? "
                                       "A website link, a phone/WhatsApp number, or an Instagram handle?")
        new = {"enabled": True, "kind": kind or "website", "value": value, "corner": corner}
        aug = (instruction + "\n\nRemove any existing QR code from the flyer. Keep the "
               + corner.replace("_", " ") + " corner area clean; do NOT draw any QR code - "
               "a real one is added programmatically after render.")
        return new, aug, None
    return None, instruction, None
