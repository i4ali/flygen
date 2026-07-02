from engine.llm import INTERPRET_SYSTEM


def test_interpret_system_is_one_stable_cached_block():
    assert isinstance(INTERPRET_SYSTEM, list) and len(INTERPRET_SYSTEM) == 1
    block = INTERPRET_SYSTEM[0]
    assert block["type"] == "text"
    assert block["cache_control"] == {"type": "ephemeral"}


def test_interpret_system_bakes_in_the_enum_catalogs():
    text = INTERPRET_SYSTEM[0]["text"]
    assert "nonprofit_charity" in text      # category catalog
    assert "modern_minimal" in text         # visual style catalog
    assert "4:5" in text                    # aspect ratio catalog
