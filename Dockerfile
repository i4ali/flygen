# Container image for the FlyGen chat engine (FastAPI + uvicorn), deployed to
# Cloudflare Containers behind the `flygen-engine` Worker. Build context is the
# repo root so the image can include both the `engine/` package and the root
# modules it imports (models, facts, prompt_builder, image_generator, ...).
FROM python:3.13-slim

WORKDIR /app

# Install Python deps first for layer caching. Pillow/qrcode/openai/etc. all ship
# manylinux wheels, so the slim base needs no apt build tooling.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# App code. Copy every root module (engine imports models/facts/prompt_builder,
# and lazily image_generator) plus the engine package. `.dockerignore` keeps the
# iOS project, .venv, .env and other noise out of the image.
COPY *.py ./
COPY engine/ ./engine/

# The container listens on $PORT (Cloudflare sets/knows this via the Container
# class `defaultPort`). Default to 8000 to match local dev.
ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn engine.app:app --host 0.0.0.0 --port ${PORT:-8000}"]
