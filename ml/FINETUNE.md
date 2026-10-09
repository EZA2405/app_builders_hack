# Fine-tuning Laya (teammate handoff)

**Goal:** fine-tune the open Laya decision model so it picks the right menu command for a plain-language goal, in apps it has never seen. Everything you need is in this repo.

**What's here:**
- **Training data:** `ml/data/train.jsonl` (1,818 rows) and `ml/data/val.jsonl` (381 rows, 4 apps never trained on). These are Laya rows: a goal plus a 16-option choice, with the right command as `expected`.
- **Held-out test:** `ml/fixtures/{preview,finder,systemsettings,safari}_real.json`, 35 goals in 4 apps that are never in training.
- **Baselines** (Apple M4, 16 GB, held-out 35):
  - base Laya **8/35**
  - hosted Jev (cloud reference) **35/35**

## 1. Setup (~5 min)

```bash
git clone https://github.com/EZA2405/app_builders_hack && cd app_builders_hack   # or git pull
python3 -m venv .venv && source .venv/bin/activate        # Python 3.10+
pip install "laya[serve]"                                  # pulls torch; on NVIDIA make sure torch has CUDA
python -c "import laya, torch; print(laya.__version__, torch.cuda.is_available(), torch.backends.mps.is_available())"
```

## 2. Train

Use `--device cuda` on an NVIDIA GPU, `--device mps` on an Apple Silicon Mac. **Close other heavy apps:** training plus a browser plus downloads crashed a 16 GB Mac.

```bash
cd ml
# v1: base English checkpoint
laya-train --data data/train.jsonl --eval data/val.jsonl \
  --base convaiinnovations/laya --out ../models/laya-guide-v1 \
  --device cuda --epochs 3 --shuffle-options --label-smoothing 0.05 --seed 7 2>&1 | tee train_v1.log
```

If there's time and GPU to spare, also try these. Change one thing at a time, and keep each log:
- **v2:** start from the typed-decisions checkpoint, which is already fine-tuned for choice questions: `--base convaiinnovations/laya` → the `typed-decisions/` subfolder of the HF repo. Download it with `huggingface-cli download convaiinnovations/laya --include "typed-decisions/*"` and pass the local folder path.
- **v3:** v1 with `--epochs 6`.

The trainer prints validation accuracy before and after. Note both numbers.

## 3. Test on the held-out apps (the number that matters)

```bash
# serve your checkpoint locally
LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=cuda \
LAYA_EXTRA_MODELS='{"guide": "'"$PWD"'/../models/laya-guide-v1"}' laya-serve &

# 35 held-out goals, 16-option tournament (stdlib python, no extra deps)
for f in preview finder systemsettings safari; do
  python3 bench_localjev.py --url http://127.0.0.1:8766 --model guide --group 16 --fixture fixtures/${f}_real.json | tail -1
done
```

Run the same loop with `--model convaiinnovations/laya` to confirm you also get the 8/35 base result on your machine.

## 4. Report back
- **Post in the team chat:** val accuracy before and after, held-out score per app plus the total out of 35, median latency, device, and training time.
- **Add a row to `ml/RESULTS.md`** (measured numbers only, with the command), then commit and push to `main` (`git pull --rebase` first).
- **Send the best checkpoint folder** (`models/laya-guide-vN/`, ~850 MB) by AirDrop or Google Drive. **Do not commit weights to git.**

## Rules
- **Don't add any held-out app** (Preview, Finder, System Settings, Safari) to training data.
- **Don't edit answer keys** in `fixtures/` to raise a score. If you think a key is factually wrong, say so in chat.
- **Only report numbers you measured.**
