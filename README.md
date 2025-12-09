# Flyer Generator - AI-Powered Flyer Creation

A Python prototype for testing prompt engineering strategies for AI flyer generation.

## The Core Idea

The "moat" isn't access to AI image generation (everyone has that). The value is in **structured intake** that translates messy human intent into precise prompts, reducing iterations and improving results.

## How It Works

1. **Guided Intake** → User answers structured questions (category, text, style, colors)
2. **Prompt Engineering** → Answers are transformed into optimized AI prompts
3. **Generation** → Prompts are sent to GPT-4o or DALL-E 3
4. **Refinement** → User feedback is parsed into prompt modifications

## Files

| File | Purpose |
|------|---------|
| `models.py` | Data structures (FlyerProject, Category, Style, etc.) |
| `prompt_builder.py` | **The secret sauce** - transforms requirements → prompts |
| `image_generator.py` | OpenAI API integration |
| `main.py` | Interactive CLI for full flow |
| `demo.py` | Test prompt quality without API key |

## Quick Start

### Test Prompt Quality (No API Key Needed)

```bash
python demo.py
```

This shows what prompts are generated for various flyer types. Copy any prompt and paste it into ChatGPT or DALL-E to test manually.

### Full Flow with Image Generation

```bash
# Set your API key
export OPENAI_API_KEY="sk-..."

# Install dependencies
pip install openai

# Run interactive mode
python main.py

# Or test without API key (mock mode)
python main.py --mock
```

## Prompt Engineering Strategy

### 1. Category-Specific Context
Each flyer type gets tailored context:
- Sale flyers → "urgency-driving design elements"
- Events → "clear date/time placement"
- Restaurants → "appetizing appeal"

### 2. Style Expansion
Simple selections expand into detailed instructions:
- "Modern Minimal" → "clean lines, generous white space, contemporary sans-serif typography..."

### 3. Smart Negative Prompts
Prevents common AI failures:
- "blurry text, misspelled words, cluttered composition, clipart..."

### 4. Refinement Parsing
User feedback is translated into prompt modifications:
- "make the text bigger" → "larger, more prominent text that commands attention"
- "too busy" → "simplified composition with more white space"

## Example Output

```
MAIN PROMPT:
Create a professional high-quality sale and promotion flyer with 
urgency-driving design elements. Format: portrait 4:5 aspect ratio.
Visual style: bold vibrant design with strong saturated colors, 
high contrast, impactful typography...

TEXT CONTENT: Prominent headline text: "MEGA SALE" - this should be 
the most visually dominant text element. Discount: "50% OFF" - make 
this eye-catching and prominent...

NEGATIVE PROMPT:
blurry text, misspelled words, cluttered composition, clipart, 
subtle hidden pricing, calm muted urgency...
```

## Next Steps

1. **Test prompt quality** - Run demo.py, copy prompts, test in ChatGPT
2. **Iterate on prompts** - Improve category-specific hints and style descriptors
3. **Add more categories** - Expand the library
4. **Translate to SwiftUI** - Once prompts are proven effective

## Cost Estimates (OpenAI)

| Model | Quality | Cost per Image |
|-------|---------|----------------|
| gpt-image-1 | High | ~$0.08 |
| dall-e-3 | HD | ~$0.08 |
| dall-e-3 | Standard | ~$0.04 |

## Architecture for iOS App

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI App                       │
├─────────────────────────────────────────────────────┤
│  Screen Flow:                                        │
│  Category → Text → Style → Colors → Format → Generate│
├─────────────────────────────────────────────────────┤
│  FlyerProject (Swift struct matching Python models)  │
├─────────────────────────────────────────────────────┤
│  PromptBuilder (port prompt_builder.py logic)        │
├─────────────────────────────────────────────────────┤
│  OpenAI API (direct HTTPS calls or SDK)              │
└─────────────────────────────────────────────────────┘
```

## Debugging Links

| Service | Dashboard |
|---------|-----------|
| Cloudflare Workers | https://dash.cloudflare.com/ |
| CloudKit Console | https://icloud.developer.apple.com/dashboard/ |
