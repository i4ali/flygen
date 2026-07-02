from unittest.mock import MagicMock
from models import FlyerProject, FlyerCategory, TextContent
from engine.tools import generate_concepts, refine_concept, resize_concept, Concept


def test_generate_concepts_builds_prompt_and_returns_base64():
    fake_result = MagicMock(success=True, image_base64="ZmFrZQ==", image_path=None, error_message=None)
    fake_generator = MagicMock()
    fake_generator.generate.return_value = [fake_result, fake_result, fake_result]

    project = FlyerProject(category=FlyerCategory.EVENT, text_content=TextContent(headline="Bake Sale"))
    concepts = generate_concepts(project, generator=fake_generator, n=3)

    assert len(concepts) == 3
    assert all(isinstance(c, Concept) for c in concepts)
    assert concepts[0].image_base64 == "ZmFrZQ=="
    # the wrapper compiled a prompt via FlyerPromptBuilder and asked for no disk writes
    _, kwargs = fake_generator.generate.call_args
    assert kwargs["save_images"] is False
    assert kwargs["n"] == 3
    assert isinstance(kwargs["prompt"], str) and len(kwargs["prompt"]) > 0


def test_generate_concepts_includes_user_photos_as_input_images():
    # uploaded photos ride along as references for the image model, alongside any logo.
    fake_result = MagicMock(success=True, image_base64="ZmFrZQ==", image_path=None, error_message=None)
    fake_generator = MagicMock()
    fake_generator.generate.return_value = [fake_result]

    project = FlyerProject(category=FlyerCategory.MUSIC_CONCERT, text_content=TextContent(headline="Live Show"))
    generate_concepts(project, generator=fake_generator, n=1,
                      user_photo_paths=["/tmp/a.png", "/tmp/b.png"])

    _, kwargs = fake_generator.generate.call_args
    assert kwargs["input_images"] == ["/tmp/a.png", "/tmp/b.png"]


def test_refine_concept_passes_prior_image_in_edit_mode():
    fake_result = MagicMock(success=True, image_base64="cmVmaW5lZA==", image_path=None, error_message=None)
    fake_generator = MagicMock()
    fake_generator.generate.return_value = [fake_result]

    project = FlyerProject(category=FlyerCategory.EVENT, text_content=TextContent(headline="Bake Sale"))
    concept = refine_concept(
        project,
        prior_image_path="/tmp/prev.png",
        instruction="make the headline bigger",
        generator=fake_generator,
        mode="edit",
    )

    assert isinstance(concept, Concept)
    assert concept.image_base64 == "cmVmaW5lZA=="
    _, kwargs = fake_generator.generate.call_args
    assert kwargs["save_images"] is False
    # prior image must be handed back in for image-to-image editing
    assert "/tmp/prev.png" in kwargs["input_images"]
    # instruction is embedded in an EDIT MODE prompt
    assert "EDIT MODE" in kwargs["prompt"]
    assert "make the headline bigger" in kwargs["prompt"]


def test_resize_concept_uses_target_aspect():
    fake_result = MagicMock(success=True, image_base64="cmVzaXplZA==", image_path=None, error_message=None)
    fake_generator = MagicMock()
    fake_generator.generate.return_value = [fake_result]

    concept = resize_concept(prior_image_path="/tmp/prev.png", aspect_ratio="letter", generator=fake_generator)

    assert isinstance(concept, Concept)
    assert concept.image_base64 == "cmVzaXplZA=="
    _, kwargs = fake_generator.generate.call_args
    assert kwargs["save_images"] is False
    assert kwargs["aspect_ratio"] == "letter"
    assert "/tmp/prev.png" in kwargs["input_images"]
