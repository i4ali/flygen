#!/usr/bin/env bash
# Run the FlyGen chat engine locally for the iOS Simulator to reach at http://localhost:8000
# Requires OPENROUTER_API_KEY in .env (loaded by engine/llm.py + image_generator).
set -euo pipefail
cd "$(dirname "$0")/.."
exec .venv/bin/uvicorn engine.app:app --port 8000 --reload
