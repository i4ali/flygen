from dataclasses import dataclass
from typing import List, Optional, Dict
from models import (
    FlyerProject, AspectRatio, ColorSchemePreset, QRCodeSettings, VisualStyle, Mood,
)
from engine.rubrics import Rubric


# Single source of platform-labeled size options — shared by the early picker AND the review
# decision so "what does 4:5 mean" is answered the same way in both places.
_FORMAT_OPTIONS = [
    ("4:5", "Instagram / feed (4:5)"),
    ("9:16", "TikTok · Reels · Stories (9:16)"),
    ("1:1", "Square (1:1)"),
    ("16:9", "Banner · YouTube (16:9)"),
    ("letter", "Print flyer · US Letter"),
    ("a4", "Print flyer · A4"),
]


def format_options() -> List[dict]:
    """Ordered size options as {value, label}; the default (4:5) is first."""
    return [{"value": v, "label": label} for v, label in _FORMAT_OPTIONS]


@dataclass
class Direction:
    """A named palette direction the user can tap to choose the aesthetic."""
    name: str
    swatches: List[str]


# Free-text palette name -> concrete hex preset. The aesthetic *choice* is the user's
# tap; mapping a chosen direction to hexes defers to these deterministic presets.
_PALETTE_PRESETS = {
    "warm": ["#E76F51", "#F4A261", "#FFE8D6"],
    "hopeful": ["#E76F51", "#F4A261", "#FFF3E0"],
    "cool": ["#264653", "#2A9D8F", "#E9F5F3"],
    "trust": ["#1B4965", "#5FA8D3", "#EAF4FB"],
    "earthy": ["#6B4226", "#A98467", "#EDE0D4"],
    "bold": ["#1D1D1D", "#FF3B30", "#FFD60A"],
    "festive": ["#D00000", "#FFBA08", "#3F88C5"],
    "energy": ["#D00000", "#FFBA08", "#3F88C5"],
    "premium": ["#0A0A0A", "#C9A227", "#1A1A1A"],
    "gold": ["#0A0A0A", "#C9A227", "#1A1A1A"],
    "elegant": ["#0B0B0B", "#C9A227", "#F5F0E1"],
    "classic": ["#0B0B0B", "#C9A227", "#F5F0E1"],
    "fresh": ["#2A9D8F", "#E9C46A", "#F4FBF8"],
    "modern": ["#22223B", "#4A4E69", "#F2E9E4"],
    "sleek": ["#22223B", "#4A4E69", "#F2E9E4"],
    "vibrant": ["#FF006E", "#FB5607", "#FFBE0B"],
    # Seasonal directions (see rubrics.SEASONAL_PALETTE_DIRECTIONS). Keyed on a word unique to
    # each direction name so _swatches_for resolves them precisely (no overlap with the above).
    "winter": ["#1B3A5B", "#5A8FB5", "#E8F1F8"],     # deep navy · ice blue · frost
    "evergreen": ["#1E3D2F", "#3E7C5A", "#EAF3EC"],  # forest · pine · snow
    "autumn": ["#8C3B0E", "#D9822B", "#F4E2C8"],     # burnt sienna · amber · wheat
    "spring": ["#6FA86B", "#E7A6C4", "#FBF4E6"],     # leaf green · blossom · cream
    "summer": ["#FF6B5C", "#2EC4B6", "#FFE066"],     # coral · aqua · sunshine
}
_DEFAULT_SWATCHES = ["#264653", "#2A9D8F", "#E9C46A"]


def map_format(destination: str) -> AspectRatio:
    """Deterministic destination -> aspect ratio. 'both' prefers portrait."""
    d = (destination or "").strip().lower()
    if d in ("print", "printed", "flyer", "poster", "paper", "handout"):
        return AspectRatio.LETTER
    if d in ("story", "stories", "reel", "reels"):
        return AspectRatio.STORY_9_16
    if d in ("square",):
        return AspectRatio.SQUARE_1_1
    if d in ("banner", "landscape"):
        return AspectRatio.LANDSCAPE_16_9
    # instagram / social / feed / post / both / unknown -> portrait
    return AspectRatio.PORTRAIT_4_5


def _swatches_for(name: str) -> List[str]:
    low = (name or "").lower()
    for keyword, hexes in _PALETTE_PRESETS.items():
        if keyword in low:
            return list(hexes)
    return list(_DEFAULT_SWATCHES)


def propose_palette_directions(rubric: Rubric) -> List[Direction]:
    """Named swatch directions drawn from the rubric's palette directions."""
    return [Direction(name=n, swatches=_swatches_for(n)) for n in rubric.palette_directions]


def _match_direction(choice: str, directions: List[Direction]) -> Optional[Direction]:
    c = (choice or "").strip().lower()
    for d in directions:
        if d.name.strip().lower() == c:
            return d
    for d in directions:
        if c and (c in d.name.lower() or d.name.lower() in c):
            return d
    return directions[0] if directions else None


def _resolve_enum(enum_cls, raw):
    """Resolve an enum from either its wire value ('modern_minimal') or its human display
    label ('Modern Minimal'). Returns None when nothing matches."""
    if raw is None:
        return None
    s = str(raw).strip()
    if not s:
        return None
    try:
        return enum_cls(s)                       # exact wire value
    except ValueError:
        pass
    for m in enum_cls:
        if getattr(m, "display_name", m.value).lower() == s.lower():
            return m
    return None


def apply_decisions(project: FlyerProject, answers: dict, rubric: Rubric) -> FlyerProject:
    """Record the user's decisions onto the project: format, palette, style/mood, QR.
    The aesthetic choice is the user's tap; this just records it deterministically."""
    answers = answers or {}

    if answers.get("destination"):
        project.output.aspect_ratio = map_format(answers["destination"])

    palette_choice = answers.get("palette")
    if palette_choice:
        chosen = _match_direction(palette_choice, propose_palette_directions(rubric))
        if chosen:
            sw = chosen.swatches
            project.colors.preset = ColorSchemePreset.CUSTOM
            project.colors.primary_color = sw[0] if len(sw) > 0 else None
            project.colors.secondary_color = sw[1] if len(sw) > 1 else None
            project.colors.accent_color = sw[2] if len(sw) > 2 else None
            project.colors.gradient_colors = list(sw)

    style = _resolve_enum(VisualStyle, answers.get("style"))
    if style:
        project.visuals.style = style

    mood = _resolve_enum(Mood, answers.get("mood"))
    if mood:
        project.visuals.mood = mood

    qr_url = answers.get("qr_url") or answers.get("qr")
    if qr_url:
        project.qr_settings = QRCodeSettings(enabled=True, url=qr_url)

    return project


@dataclass
class DecisionProposal:
    key: str
    label: str
    value: str
    options: List[str]
    reason: str
    option_labels: Optional[Dict[str, str]] = None   # value -> human label (e.g. format sizes)


def _recommended(design, attr: str) -> Optional[str]:
    """A design-pass recommendation, only if it's a real (non-empty) string. Guards against a
    mocked/garbled design brief (e.g. a MagicMock, or a parse miss) leaking a non-string value."""
    v = getattr(design, attr, None)
    return v.strip() if isinstance(v, str) and v.strip() else None


def propose_decisions(brief, rubric, design=None) -> List["DecisionProposal"]:
    # format: the size the user picked early, else inferred from destination, else the default
    if getattr(brief, "aspect_ratio", None):
        fmt = brief.aspect_ratio
        fmt_reason = "the size you picked"
    elif getattr(brief, "destination", None):
        fmt = map_format(brief.destination).value
        fmt_reason = f"inferred from your brief ({brief.destination})"
    else:
        fmt = AspectRatio.PORTRAIT_4_5.value
        fmt_reason = "default — reads well in feeds and prints cleanly"

    fmt_opts = format_options()
    directions = [d.name for d in propose_palette_directions(rubric)]

    # palette / style / mood: prefer the design pass's brief-specific pick (chosen from the
    # offered options) over the blind category default / hard-coded defaults — but always
    # surfaced for approval, and always falling back when the pass gave nothing usable. This
    # is the fix for the audited contradiction (notes recommending a winter palette while the
    # control defaulted to "High-energy red/yellow").
    palette = directions[0] if directions else "Warm & inviting"
    palette_reason = "from the category's recommended directions"
    rec_pal = _recommended(design, "recommended_palette")
    if rec_pal:
        low = rec_pal.lower()
        match = next((n for n in directions
                      if n.lower() == low or low in n.lower() or n.lower() in low), None)
        if match:
            palette, palette_reason = match, "matched to your brief by the design plan"

    style_value, style_reason = VisualStyle.MODERN_MINIMAL.display_name, "a clean, safe default"
    rec_style = _resolve_enum(VisualStyle, _recommended(design, "recommended_style"))
    if rec_style:
        style_value, style_reason = rec_style.display_name, "matched to your brief by the design plan"

    mood_value, mood_reason = Mood.FRIENDLY.display_name, "approachable default"
    rec_mood = _resolve_enum(Mood, _recommended(design, "recommended_mood"))
    if rec_mood:
        mood_value, mood_reason = rec_mood.display_name, "matched to your brief by the design plan"

    return [
        DecisionProposal("format", "Size / format", fmt, [o["value"] for o in fmt_opts], fmt_reason,
                         option_labels={o["value"]: o["label"] for o in fmt_opts}),
        DecisionProposal("palette", "Color palette", palette, directions, palette_reason),
        DecisionProposal("visual_style", "Visual style", style_value,
                         [s.display_name for s in VisualStyle], style_reason),
        DecisionProposal("mood", "Mood", mood_value,
                         [m.display_name for m in Mood], mood_reason),
        DecisionProposal("quality", "Quality", "hd", ["low", "medium", "high", "hd"], "print-ready"),
        # NB: the image model (nano-banana-pro) is intentionally NOT proposed — it's an
        # internal implementation detail set by to_flyer_project, not a user decision.
    ]


def emphasis_note(rubric, design=None) -> str:
    """Compose a generation-emphasis instruction from the rubric's visual hierarchy and the
    design pass's brief-specific recommendations, so the plan's intent actually reaches the
    image prompt. (These were surfaced to the user at review but never fed to generation —
    why the audited flyer rendered 'While Supplies Last' tiny despite the notes elevating it.)"""
    parts = []
    hierarchy = list(getattr(rubric, "hierarchy", None) or [])
    if hierarchy:
        parts.append("Visual emphasis, most to least prominent: "
                     + ", ".join(h.replace("_", " ") for h in hierarchy))
    recs = getattr(design, "recommendations", None)
    recs = recs if isinstance(recs, list) else []
    parts.extend(r for r in recs if isinstance(r, str) and r.strip())
    # rstrip a trailing period per part so the join doesn't produce ".." sentences.
    return ". ".join(p.strip().rstrip(".") for p in parts if p.strip())


def apply_proposed(project, decisions: dict, rubric) -> "FlyerProject":
    """Apply the user's confirmed/overridden decision values (keyed as in propose_decisions)."""
    decisions = decisions or {}
    if decisions.get("format"):
        try:
            project.output.aspect_ratio = AspectRatio(decisions["format"])
        except ValueError:
            pass
    if decisions.get("palette"):
        apply_decisions(project, {"palette": decisions["palette"]}, rubric)
    if decisions.get("visual_style"):
        m = _resolve_enum(VisualStyle, decisions["visual_style"])
        if m:
            project.visuals.style = m
    if decisions.get("mood"):
        m = _resolve_enum(Mood, decisions["mood"])
        if m:
            project.visuals.mood = m
    if decisions.get("quality"):
        project.output.quality = decisions["quality"]
    if decisions.get("model"):
        project.output.model = decisions["model"]
    if decisions.get("qr_url"):
        from models import QRCodeSettings
        project.qr_settings = QRCodeSettings(enabled=True, url=decisions["qr_url"])
    return project
