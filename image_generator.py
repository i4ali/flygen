"""
Image Generation Module

Interfaces with image generation APIs via OpenAI or OpenRouter.
"""
import os
import base64
import json
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass, field

# OpenAI client (works with OpenRouter too)
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("Note: openai package not installed. Run: pip install openai")


@dataclass
class GenerationResult:
    """Result from an image generation attempt"""
    success: bool
    image_path: Optional[str] = None
    image_url: Optional[str] = None
    image_base64: Optional[str] = None
    revised_prompt: Optional[str] = None
    error_message: Optional[str] = None
    model_used: str = ""
    generation_time_seconds: float = 0.0
    metadata: Dict[str, Any] = field(default_factory=dict)


# Aspect ratio to size mapping
ASPECT_RATIO_TO_SIZE: Dict[str, str] = {
    "1:1": "1024x1024",
    "4:5": "1024x1024",      # Closest square, crop later if needed
    "9:16": "1024x1792",     # Vertical
    "16:9": "1792x1024",     # Horizontal
    "letter": "1024x1792",   # Vertical for print
    "a4": "1024x1792",       # Vertical for print
}

# OpenRouter model name mappings
OPENROUTER_MODELS = {
    "dall-e-3": "openai/dall-e-3",
    "nano-banana": "google/gemini-2.5-flash-image-preview",
    "nano-banana-pro": "google/gemini-3-pro-image-preview",
    "gpt-image-1": "openai/gpt-image-1",  # Not supported on OpenRouter
}

# Models that use chat completions API (not images API)
CHAT_COMPLETION_IMAGE_MODELS = ["nano-banana", "nano-banana-pro"]

# Nano Banana supports these aspect ratios directly
NANO_BANANA_ASPECT_RATIOS = {
    "1:1": "1:1",
    "4:5": "3:4",      # Closest match
    "9:16": "9:16",
    "16:9": "16:9",
    "letter": "3:4",
    "a4": "3:4",
}


class FlyerImageGenerator:
    """Generates flyer images using AI models via OpenAI or OpenRouter"""
    
    def __init__(
        self, 
        api_key: Optional[str] = None, 
        output_dir: str = "./generated",
        use_openrouter: bool = False,
        base_url: Optional[str] = None
    ):
        """
        Initialize the generator.
        
        Args:
            api_key: API key (or set OPENAI_API_KEY / OPENROUTER_API_KEY env var)
            output_dir: Directory to save generated images
            use_openrouter: If True, use OpenRouter API instead of OpenAI directly
            base_url: Custom base URL (overrides use_openrouter setting)
        """
        if not OPENAI_AVAILABLE:
            raise ImportError(
                "openai package not installed. Run: pip install openai"
            )
        
        self.use_openrouter = use_openrouter
        
        # Determine API key
        if api_key:
            self.api_key = api_key
        elif use_openrouter:
            self.api_key = os.environ.get("OPENROUTER_API_KEY")
        else:
            self.api_key = os.environ.get("OPENAI_API_KEY")
        
        if not self.api_key:
            env_var = "OPENROUTER_API_KEY" if use_openrouter else "OPENAI_API_KEY"
            raise ValueError(
                f"API key required. Set {env_var} environment variable or pass api_key parameter."
            )
        
        # Determine base URL
        if base_url:
            self.base_url = base_url
        elif use_openrouter:
            self.base_url = "https://openrouter.ai/api/v1"
        else:
            self.base_url = None  # Use OpenAI default
        
        # Initialize client
        if self.base_url:
            self.client = OpenAI(
                api_key=self.api_key,
                base_url=self.base_url,
                default_headers={
                    "HTTP-Referer": "https://flyer-generator.app",
                    "X-Title": "Flyer Generator"
                }
            )
        else:
            self.client = OpenAI(api_key=self.api_key)
        
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def _get_model_name(self, model: str) -> str:
        """Get the correct model name based on provider"""
        if self.use_openrouter and model in OPENROUTER_MODELS:
            return OPENROUTER_MODELS[model]
        return model
    
    def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        model: str = "nano-banana",
        aspect_ratio: str = "4:5",
        quality: str = "hd",
        n: int = 1,
        save_images: bool = True,
        input_images: Optional[List[str]] = None
    ) -> List[GenerationResult]:
        """
        Generate flyer image(s).

        Args:
            prompt: Main generation prompt
            negative_prompt: What to avoid (appended to prompt)
            model: "nano-banana", "nano-banana-pro", "dall-e-3", or "gpt-image-1"
            aspect_ratio: "1:1", "4:5", "9:16", "16:9", "letter", "a4"
            quality: "low", "medium", "high", "hd" (model-dependent)
            n: Number of images to generate (1-4)
            save_images: Whether to save to disk
            input_images: List of image paths to include (e.g., logo) - only for Nano Banana

        Returns:
            List of GenerationResult objects
        """
        import time
        start_time = time.time()

        # Get appropriate size for aspect ratio (for DALL-E/GPT models)
        size = ASPECT_RATIO_TO_SIZE.get(aspect_ratio, "1024x1024")

        # Get correct model name for provider
        actual_model = self._get_model_name(model)

        # Combine prompt with negative prompt
        full_prompt = prompt
        if negative_prompt:
            full_prompt += f"\n\nAVOID: {negative_prompt}"

        results = []

        # Warn if input images provided but model doesn't support it
        if input_images and model not in CHAT_COMPLETION_IMAGE_MODELS:
            print(f"⚠️  Warning: {model} does not support input images. Logo will be ignored.")
            print("   Use nano-banana or nano-banana-pro to include your logo.")
            input_images = None

        try:
            # Determine which generation method to use based on model
            if model in CHAT_COMPLETION_IMAGE_MODELS:
                # Use chat completions API (Nano Banana models)
                for i in range(n):
                    result = self._generate_nano_banana(
                        full_prompt, aspect_ratio, save_images, i, actual_model, input_images
                    )
                    results.append(result)
            elif model == "gpt-image-1":
                # Use GPT Image API (direct OpenAI only)
                results = self._generate_gpt_image(
                    full_prompt, size, quality, n, save_images
                )
            else:
                # Use DALL-E 3 API (default fallback)
                for i in range(n):
                    result = self._generate_dalle3(
                        full_prompt, size, quality, save_images, i, actual_model
                    )
                    results.append(result)
        
        except Exception as e:
            results.append(GenerationResult(
                success=False,
                error_message=str(e),
                model_used=actual_model
            ))
        
        # Add timing
        elapsed = time.time() - start_time
        for result in results:
            result.generation_time_seconds = elapsed / len(results)
            result.metadata["prompt_length"] = len(prompt)
            result.metadata["aspect_ratio"] = aspect_ratio
            result.metadata["provider"] = "openrouter" if self.use_openrouter else "openai"
        
        return results
    
    def _generate_dalle3(
        self,
        prompt: str,
        size: str,
        quality: str,
        save: bool,
        index: int,
        model: str = "dall-e-3"
    ) -> GenerationResult:
        """Generate with DALL-E 3"""
        try:
            # Map quality
            dalle_quality = "hd" if quality in ["hd", "high"] else "standard"
            
            response = self.client.images.generate(
                model=model,
                prompt=prompt,
                size=size,
                quality=dalle_quality,
                style="vivid",
                n=1
            )
            
            image_url = response.data[0].url
            revised_prompt = response.data[0].revised_prompt
            
            # Download and save
            image_path = None
            if save and image_url:
                image_path = self._save_image_from_url(image_url, "dalle3", index)
            
            return GenerationResult(
                success=True,
                image_path=str(image_path) if image_path else None,
                image_url=image_url,
                revised_prompt=revised_prompt,
                model_used="dall-e-3",
                metadata={"size": size, "quality": dalle_quality}
            )
        
        except Exception as e:
            return GenerationResult(
                success=False,
                error_message=str(e),
                model_used="dall-e-3"
            )

    def _load_image_as_base64(self, image_path: str) -> Optional[str]:
        """Load an image file and return as base64 string"""
        try:
            with open(image_path, 'rb') as f:
                return base64.b64encode(f.read()).decode('utf-8')
        except Exception as e:
            print(f"Warning: Could not load image {image_path}: {e}")
            return None

    def _generate_nano_banana(
        self,
        prompt: str,
        aspect_ratio: str,
        save: bool,
        index: int,
        model: str,
        input_images: Optional[List[str]] = None
    ) -> GenerationResult:
        """Generate with Nano Banana via chat completions API"""
        try:
            # Map aspect ratio
            ar = NANO_BANANA_ASPECT_RATIOS.get(aspect_ratio, "1:1")

            # Build message content - can include both text and images
            content = []

            # Add input images first (e.g., logo)
            if input_images:
                for img_path in input_images:
                    img_b64 = self._load_image_as_base64(img_path)
                    if img_b64:
                        # Detect image type from extension
                        ext = Path(img_path).suffix.lower()
                        mime_type = {
                            '.png': 'image/png',
                            '.jpg': 'image/jpeg',
                            '.jpeg': 'image/jpeg',
                            '.gif': 'image/gif',
                            '.webp': 'image/webp'
                        }.get(ext, 'image/png')
                        content.append({
                            "type": "image_url",
                            "image_url": {"url": f"data:{mime_type};base64,{img_b64}"}
                        })

            # Add text prompt
            content.append({"type": "text", "text": prompt})

            response = self.client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": content}],
                extra_body={
                    "modalities": ["image", "text"],
                    "image_config": {"aspect_ratio": ar}
                }
            )

            # Extract image from response
            message = response.choices[0].message

            # Check for images in the response
            # OpenRouter returns images as a list with image_url containing data URL
            images = getattr(message, 'images', None)
            if images and len(images) > 0:
                image_data_url = images[0].get("image_url", {}).get("url", "")
                if image_data_url and "," in image_data_url:
                    # Parse base64 from data URL: "data:image/png;base64,..."
                    b64_data = image_data_url.split(",")[1]

                    image_path = None
                    if save:
                        image_path = self._save_image_from_base64(b64_data, "nanobanana", index)

                    return GenerationResult(
                        success=True,
                        image_path=str(image_path) if image_path else None,
                        image_base64=b64_data,
                        model_used=model,
                        metadata={"aspect_ratio": ar, "has_logo": bool(input_images)}
                    )

            return GenerationResult(
                success=False,
                error_message="No image in response",
                model_used=model
            )

        except Exception as e:
            return GenerationResult(
                success=False,
                error_message=str(e),
                model_used=model
            )

    def _generate_gpt_image(
        self,
        prompt: str,
        size: str,
        quality: str,
        n: int,
        save: bool
    ) -> List[GenerationResult]:
        """Generate with GPT-Image-1"""
        results = []
        
        try:
            # Map quality
            gpt_quality = quality if quality in ["low", "medium", "high"] else "high"
            
            response = self.client.images.generate(
                model="gpt-image-1",
                prompt=prompt,
                size=size,
                quality=gpt_quality,
                n=n
            )
            
            for i, image_data in enumerate(response.data):
                image_b64 = image_data.b64_json
                
                # Save to file
                image_path = None
                if save and image_b64:
                    image_path = self._save_image_from_base64(image_b64, "gptimg", i)
                
                results.append(GenerationResult(
                    success=True,
                    image_path=str(image_path) if image_path else None,
                    image_base64=image_b64,
                    model_used="gpt-image-1",
                    metadata={"size": size, "quality": gpt_quality}
                ))
        
        except Exception as e:
            results.append(GenerationResult(
                success=False,
                error_message=str(e),
                model_used="gpt-image-1"
            ))
        
        return results
    
    def _save_image_from_url(
        self, 
        url: str, 
        prefix: str, 
        index: int
    ) -> Optional[Path]:
        """Download and save image from URL"""
        try:
            import urllib.request
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{prefix}_{timestamp}_{index}.png"
            filepath = self.output_dir / filename
            urllib.request.urlretrieve(url, filepath)
            return filepath
        except Exception as e:
            print(f"Warning: Failed to save image from URL: {e}")
            return None
    
    def _save_image_from_base64(
        self,
        b64_data: str,
        prefix: str,
        index: int
    ) -> Optional[Path]:
        """Save base64 image data to file"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{prefix}_{timestamp}_{index}.png"
            filepath = self.output_dir / filename
            
            image_bytes = base64.b64decode(b64_data)
            with open(filepath, 'wb') as f:
                f.write(image_bytes)
            
            return filepath
        except Exception as e:
            print(f"Warning: Failed to save image from base64: {e}")
            return None


class MockFlyerGenerator:
    """Mock generator for testing without API key"""
    
    def __init__(self, output_dir: str = "./generated"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        model: str = "gpt-image-1",
        aspect_ratio: str = "4:5",
        quality: str = "hd",
        n: int = 1,
        save_images: bool = True
    ) -> List[GenerationResult]:
        """Generate mock results for testing"""
        results = []
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        for i in range(n):
            # Create a mock "image" file with the prompt
            if save_images:
                filepath = self.output_dir / f"mock_{timestamp}_{i}.txt"
                with open(filepath, 'w') as f:
                    f.write(f"MOCK IMAGE GENERATION\n")
                    f.write(f"=" * 50 + "\n\n")
                    f.write(f"Model: {model}\n")
                    f.write(f"Aspect Ratio: {aspect_ratio}\n")
                    f.write(f"Quality: {quality}\n\n")
                    f.write(f"PROMPT:\n{prompt}\n\n")
                    f.write(f"NEGATIVE:\n{negative_prompt}\n")
            
            results.append(GenerationResult(
                success=True,
                image_path=str(filepath) if save_images else None,
                model_used=f"mock-{model}",
                metadata={
                    "aspect_ratio": aspect_ratio,
                    "quality": quality,
                    "note": "This is a mock generation for testing"
                }
            ))
        
        return results


# =============================================================================
# CONVENIENCE FUNCTION
# =============================================================================

def create_generator(
    api_key: Optional[str] = None, 
    mock: bool = False,
    use_openrouter: bool = False
):
    """
    Create appropriate generator based on availability.
    
    Args:
        api_key: API key
        mock: Force mock generator (for testing)
        use_openrouter: Use OpenRouter instead of OpenAI directly
    
    Returns:
        FlyerImageGenerator or MockFlyerGenerator
    """
    if mock:
        return MockFlyerGenerator()
    
    try:
        return FlyerImageGenerator(api_key=api_key, use_openrouter=use_openrouter)
    except (ImportError, ValueError) as e:
        print(f"Warning: Cannot create real generator ({e}). Using mock.")
        return MockFlyerGenerator()


# =============================================================================
# TEST
# =============================================================================

if __name__ == "__main__":
    print("Testing Mock Generator...")
    
    gen = MockFlyerGenerator(output_dir="./test_generated")
    
    results = gen.generate(
        prompt="Test flyer for a bakery sale",
        negative_prompt="blurry text, clipart",
        model="gpt-image-1",
        aspect_ratio="4:5",
        n=1
    )
    
    for result in results:
        print(f"Success: {result.success}")
        print(f"Path: {result.image_path}")
        print(f"Model: {result.model_used}")
