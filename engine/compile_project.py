"""Approved TurnResult + user overrides -> FlyerProject (then the unchanged FlyerPromptBuilder runs)."""
from typing import Optional
from models import (FlyerProject, FlyerCategory, TextContent, OutputSettings, VisualSettings,
                    ColorSettings, ColorSchemePreset, AspectRatio, VisualStyle, Mood)
from engine.rubrics import PALETTE_SWATCHES

_CONTENT_FIELDS = ["headline", "subheadline", "body_text", "date", "time", "venue_name",
                   "address", "price", "discount_text", "cta_text", "phone", "email",
                   "website", "social_handle"]

def _category(value) -> FlyerCategory:
    try:
        return FlyerCategory(value)
    except (ValueError, TypeError):
        return FlyerCategory.ANNOUNCEMENT

def _decisions_map(turn, overrides: dict) -> dict:
    """key -> final value: the brain's decision, overridden by the user's review edits."""
    out = {d.key: d.value for d in turn.decisions}
    out.update({k: v for k, v in (overrides or {}).items() if v})
    return out

def _aspect(value) -> AspectRatio:
    for a in AspectRatio:
        if value in (a.value, a.display_name):
            return a
    return AspectRatio.PORTRAIT_4_5            # unsupported was flagged at review; safe fallback

def _enum_by_value_or_label(enum_cls, value, default):
    for m in enum_cls:
        if value in (m.value, m.display_name):
            return m
    return default

def _colors_for(palette_name: Optional[str]) -> ColorSettings:
    # The brain returns a finished palette direction in natural language (e.g. "midnight black
    # base, deep burgundy, antique gold, ivory body text"). Carry it through verbatim as the
    # authoritative instruction so the image model honors it - including the background. A swatch
    # match (bonus) also supplies explicit hexes, but the free-text description is what fixes the
    # old bug where an unmatched palette fell back to warm/light defaults.
    description = (palette_name or "").strip() or None
    hexes = PALETTE_SWATCHES.get((palette_name or "").lower())
    if not hexes:
        return ColorSettings(description=description)
    primary, secondary, *rest = hexes + [None, None]
    return ColorSettings(preset=ColorSchemePreset.CUSTOM, primary_color=primary,
                         secondary_color=secondary, accent_color=rest[0] if rest else None,
                         description=description)

def build_project(turn, field_overrides: dict, decision_overrides: dict,
                  selected_elements: Optional[list] = None) -> FlyerProject:
    fo = field_overrides or {}
    tc = TextContent(**{f: (fo.get(f) if f in fo else getattr(turn, f, None)) for f in _CONTENT_FIELDS})
    tc.headline = tc.headline or ""
    tc.additional_info = turn.additional_info or None

    dec = _decisions_map(turn, decision_overrides)
    output = OutputSettings(aspect_ratio=_aspect(dec.get("format")),
                            quality=dec.get("quality") or "hd", model="nano-banana-pro")
    visuals = VisualSettings(style=_enum_by_value_or_label(VisualStyle, dec.get("visual_style"),
                                                           VisualStyle.MODERN_MINIMAL),
                             mood=_enum_by_value_or_label(Mood, dec.get("mood"), Mood.FRIENDLY))
    colors = _colors_for(dec.get("palette"))

    # Approved creative elements -> free-text imagery the existing compiler already supports.
    chosen = selected_elements if selected_elements is not None else \
        [e.what for e in turn.creative_elements if e.sensitivity == "safe"]
    imagery = "; ".join(chosen) or None
    instructions = turn.purpose or None

    return FlyerProject(category=_category(turn.category), text_content=tc, output=output,
                        visuals=visuals, colors=colors,
                        imagery_description=imagery, special_instructions=instructions)
