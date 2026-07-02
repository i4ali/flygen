"""Prompt-builder fixes: palette-reaches-image, and Arabic/RTL handling."""
from models import FlyerProject, FlyerCategory, TextContent, ColorSettings
from prompt_builder import FlyerPromptBuilder


def _project(colors=None, text=None, imagery=None):
    return FlyerProject(category=FlyerCategory.CHURCH_RELIGIOUS,
                        text_content=text or TextContent(headline="Ladies Majlis-e-Aza"),
                        colors=colors or ColorSettings(),
                        imagery_description=imagery)


# --- Fix 1: palette free-text is authoritative, warm/light defaults are dropped ---

def test_color_section_uses_description_and_drops_warm_light():
    p = _project(colors=ColorSettings(description="midnight black base, deep burgundy, antique gold"))
    section = FlyerPromptBuilder(p)._build_color_section()
    assert "midnight black base" in section
    assert "warm color palette" not in section.lower()   # the harmful default is gone
    assert "bright and airy" not in section.lower()       # ...and so is the light background

def test_color_section_without_description_keeps_legacy_defaults():
    p = _project(colors=ColorSettings())                  # preset=WARM, background=LIGHT
    section = FlyerPromptBuilder(p)._build_color_section()
    assert "warm color palette" in section.lower()


# --- Fix 3: Arabic is not letter-split, and a targeted instruction is added ---

def test_spell_out_skips_arabic():
    b = FlyerPromptBuilder(_project())
    assert b._spell_out("يا حسين") == "يا حسين"  # unchanged
    assert b._spell_out("GALA") == "G A L A"              # Latin still spelled letter-by-letter

def test_arabic_instruction_present_when_content_has_arabic():
    p = _project(imagery="Calligraphy 'يا حسين' (Ya Hussain)")
    prompt = FlyerPromptBuilder(p).build()["main_prompt"]
    assert "ARABIC/URDU SCRIPT" in prompt and "EXACTLY ONCE" in prompt

def test_no_arabic_instruction_for_plain_english():
    p = _project(text=TextContent(headline="Summer Gala"), imagery="gold confetti")
    prompt = FlyerPromptBuilder(p).build()["main_prompt"]
    assert "ARABIC/URDU SCRIPT" not in prompt
