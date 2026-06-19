from engine.schema import ExtractedBrief, to_flyer_project
from models import FlyerProject, FlyerCategory, AspectRatio


def test_extracted_brief_converts_to_flyer_project():
    brief = ExtractedBrief(
        category="nonprofit_charity",
        headline="Bake Sale",
        date="Sat Jun 14 · 10–2",
        venue_name="Grace Hall",
        cta_text="Donate online",
    )
    project = to_flyer_project(brief)
    assert isinstance(project, FlyerProject)
    assert project.category == FlyerCategory.NONPROFIT_CHARITY
    assert project.text_content.headline == "Bake Sale"
    assert project.text_content.venue_name == "Grace Hall"
    # sane default format when the engine hasn't decided yet
    assert project.output.aspect_ratio == AspectRatio.PORTRAIT_4_5


def test_unknown_category_falls_back_to_announcement():
    project = to_flyer_project(ExtractedBrief(category="not_a_real_category", headline="Hi"))
    assert project.category == FlyerCategory.ANNOUNCEMENT
