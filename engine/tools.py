from dataclasses import dataclass
from typing import List, Optional
from models import FlyerProject
from prompt_builder import FlyerPromptBuilder


@dataclass
class Concept:
    version_id: str
    image_base64: Optional[str]
    error: Optional[str] = None


def _to_concept(result, version_id: str) -> Concept:
    """Map a GenerationResult to a Concept (base64 only, no disk)."""
    return Concept(
        version_id=version_id,
        image_base64=getattr(result, "image_base64", None) if result.success else None,
        error=None if result.success else result.error_message,
    )


def generate_concepts(project: FlyerProject, generator, n: int = 3,
                      user_photo_paths: Optional[List[str]] = None) -> List[Concept]:
    """Compile the project to a prompt and generate N concepts as base64 (no disk).
    Uploaded user photos (e.g. the performers) ride along as references, after the logo."""
    package = FlyerPromptBuilder(project).build()
    input_images = []
    if project.logo_path:
        input_images.append(project.logo_path)
    if user_photo_paths:
        input_images.extend(user_photo_paths)
    results = generator.generate(
        prompt=package["main_prompt"],
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"],
        n=n,
        save_images=False,
        input_images=input_images or None,
    )
    return [_to_concept(r, f"v{i+1}") for i, r in enumerate(results)]


def refine_concept(project: FlyerProject, prior_image_path: str, instruction: str,
                   generator, mode: str = "edit") -> Concept:
    """Refine a prior concept. In edit mode, the prior image is fed back in for
    image-to-image editing (mirrors main.py's EDIT MODE)."""
    package = FlyerPromptBuilder(project).build()
    input_images = [project.logo_path] if project.logo_path else []

    prompt = package["main_prompt"]
    if mode == "edit":
        input_images = input_images + [prior_image_path]
        prompt = (
            f"{prompt}\n\n"
            f"EDIT MODE: Modify the provided image with these specific changes: {instruction}. "
            f"Preserve all other elements exactly as they appear in the original image."
        )
    else:
        prompt = f"{prompt}\n\nApply these changes: {instruction}."

    results = generator.generate(
        prompt=prompt,
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"],
        n=1,
        save_images=False,
        input_images=input_images or None,
    )
    return _to_concept(results[0], "refined")


def _reference_aspect_ratio(path: str) -> str:
    """Nearest natively-supported ratio to the uploaded flyer's true shape, so the edit
    isn't squished. Falls back to portrait 4:5 if the image can't be read."""
    from image_generator import nearest_aspect_ratio
    try:
        from PIL import Image
        with Image.open(path) as im:
            return nearest_aspect_ratio(im.width, im.height)
    except Exception:
        return "4:5"


def edit_reference(reference_path: str, generator, instruction: str,
                   aspect_ratio: Optional[str] = None) -> Concept:
    """Edit an uploaded flyer from the user's own words: hand the flyer plus the instruction to
    the image model and let it make the change. One image; the prompt stays light and trusts the
    model to read the flyer and edit just what was asked."""
    aspect_ratio = aspect_ratio or _reference_aspect_ratio(reference_path)
    instruction = (instruction or "").strip() or "Return this flyer unchanged."
    prompt = f"Edit this flyer to make this change, keeping the rest of the flyer the same:\n\n{instruction}"
    results = generator.generate(
        prompt=prompt, model="nano-banana-pro", aspect_ratio=aspect_ratio,
        n=1, save_images=False, input_images=[reference_path],
    )
    return _to_concept(results[0], "reference_edit")


def resize_concept(prior_image_path: str, aspect_ratio: str, generator,
                   model: str = "nano-banana-pro") -> Concept:
    """Reformat an existing concept to a new aspect ratio, preserving text/style
    (mirrors main.py's reformat_image)."""
    prompt = (
        f"Reformat this flyer image to {aspect_ratio} aspect ratio. "
        f"Preserve ALL text exactly as shown - do not change any words or spelling. "
        f"Maintain the same visual style, colors, and layout as much as possible. "
        f"Adapt the composition to fit the new dimensions naturally."
    )
    results = generator.generate(
        prompt=prompt,
        model=model,
        aspect_ratio=aspect_ratio,
        n=1,
        save_images=False,
        input_images=[prior_image_path],
    )
    return _to_concept(results[0], "resized")
