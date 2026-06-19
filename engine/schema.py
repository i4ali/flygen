from typing import Optional, List
from pydantic import BaseModel
from models import (
    FlyerProject, FlyerCategory, TextContent, OutputSettings, AspectRatio,
)


class ExtractedBrief(BaseModel):
    """What the model extracts from the user's free text. All optional except category."""
    category: str = "announcement"
    headline: Optional[str] = None
    subheadline: Optional[str] = None
    body_text: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    venue_name: Optional[str] = None
    address: Optional[str] = None
    price: Optional[str] = None
    discount_text: Optional[str] = None
    cta_text: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    purpose: Optional[str] = None  # free-text intent, used by rubric reasoning


def _category(value: str) -> FlyerCategory:
    try:
        return FlyerCategory(value)
    except ValueError:
        return FlyerCategory.ANNOUNCEMENT


def to_flyer_project(brief: ExtractedBrief) -> FlyerProject:
    tc = TextContent(
        headline=brief.headline or "",
        subheadline=brief.subheadline,
        body_text=brief.body_text,
        date=brief.date,
        time=brief.time,
        venue_name=brief.venue_name,
        address=brief.address,
        price=brief.price,
        discount_text=brief.discount_text,
        cta_text=brief.cta_text,
        phone=brief.phone,
        email=brief.email,
        website=brief.website,
    )
    return FlyerProject(
        category=_category(brief.category),
        text_content=tc,
        output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5, model="nano-banana-pro"),
        special_instructions=brief.purpose or None,
    )
