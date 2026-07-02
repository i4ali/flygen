#!/usr/bin/env bash
# Run the FlyGen chat engine locally for the iOS Simulator to reach at http://localhost:8000
# Requires OPENROUTER_API_KEY in .env (loaded by engine/llm.py + image_generator).
set -euo pipefail
cd "$(dirname "$0")/.."

# Free :8000 before binding. A leftover engine from a previous run keeps serving OLD code,
# and plain uvicorn just errors "Address already in use" and exits - so the Simulator silently
# keeps hitting the stale server and code fixes look like they "didn't take". Reclaim the port
# so every run guarantees the app talks to the current code.
PORT=8000
STALE="$(lsof -ti tcp:"$PORT" || true)"
if [ -n "$STALE" ]; then
  echo "Reclaiming port $PORT from stale process(es): $STALE"
  # shellcheck disable=SC2086
  kill $STALE 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    lsof -ti tcp:"$PORT" >/dev/null 2>&1 || break
    sleep 0.3
  done
  STALE="$(lsof -ti tcp:"$PORT" || true)"
  # shellcheck disable=SC2086
  [ -n "$STALE" ] && kill -9 $STALE 2>/dev/null || true
fi

exec .venv/bin/uvicorn engine.app:app --port "$PORT" --reload
