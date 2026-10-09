#!/bin/zsh
# One command to run Gabay: start the local model server (Laya on 127.0.0.1:8766) and the Mac app.
# Everything runs on this Mac. Usage: ./run.sh            (MODEL=models/laya-guide-v4e5 ./run.sh to pick one)
set -e
cd "$(dirname "$0")"

# Fine-tuned checkpoint: $MODEL, else models/laya-guide (the chosen one), else the newest models/laya-guide-*.
MODEL=${MODEL:-$( [ -d models/laya-guide ] && echo models/laya-guide || ls -dt models/laya-guide-* 2>/dev/null | head -1 )}
[ -n "$MODEL" ] || { echo "No fine-tuned model in models/. See ml/FINETUNE.md (or download a release zip into models/)."; exit 1; }

SERVE=${LAYA_SERVE:-$(command -v laya-serve || echo ../local-jev/.venv/bin/laya-serve)}
[ -x "$SERVE" ] || { echo 'laya-serve not found. Install it with: pip install "laya[serve]"'; exit 1; }

if curl -sf http://127.0.0.1:8766/health >/dev/null; then
  echo "Local model server already running on 127.0.0.1:8766"
else
  echo "Starting the local model ($MODEL) on 127.0.0.1:8766…"
  # Bound to localhost only; the risk check uses the same checkpoint.
  LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=${LAYA_DEVICE:-mps} LAYA_PRELOAD=1 LAYA_MODELS=english \
  LAYA_EXTRA_MODELS="{\"guide\": \"$PWD/$MODEL\"}" \
    nohup "$SERVE" > /tmp/gabay-laya.log 2>&1 &
  for i in {1..90}; do curl -sf http://127.0.0.1:8766/health >/dev/null && break; sleep 1; done
  curl -sf http://127.0.0.1:8766/health >/dev/null || { echo "Model server didn't start; see /tmp/gabay-laya.log"; exit 1; }
fi

[ -d app/build/ScreenGuide.app ] || app/scripts/build_app.sh
pkill -f "ScreenGuide.app/Contents/MacOS/ScreenGuide" 2>/dev/null || true
open app/build/ScreenGuide.app
echo "Gabay is running. Click the round button in the bottom-right corner, or press Option + Space."
