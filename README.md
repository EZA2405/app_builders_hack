# ScreenGuide (working name)

**A patient guide that shows people how to do things on their Mac, one click at a time, with the AI running on their own computer.**

AppBuildersPH Hackathon 2026 · Theme: Local AI.

You say what you want ("make this photo smaller so I can email it"). ScreenGuide reads the controls of whatever app is open, a **local** model picks the right next step, and an overlay highlights exactly where to click with one plain-language instruction. **You click; it never clicks for you.** It checks that the step happened, then shows the next one.

- **Works in any app:** it reasons over the app's real menus and controls, not pre-written tutorials.
- **Local by design:** your screen holds your bank, email and medical portals. App menus alone leak recent files, history, account names and emails (we measured it, see [ml/RESULTS.md](ml/RESULTS.md)). Nothing on screen needs to leave the Mac.
- **Built for** older parents and non-technical adults, and their kids who are the family's 24/7 tech support.

> **Status (Oct 9, evening):** the core decision pipeline is validated. 35/35 on 4 held-out apps with a hosted reference model; local model results are pending (see [RESULTS](ml/RESULTS.md)). The overlay UI and browser extension are in progress.

## Repo layout

| Path | What |
|---|---|
| `app/` | macOS app (Swift 6.2, macOS 26). Reads any app's menus/controls via Accessibility. Overlay UI goes here |
| `ml/` | Benchmarks, fixtures, teacher-generated training data, fine-tuning for the local decision model |
| `ml/RESULTS.md` | **All measured numbers.** Only measured results go here |
| `extension/SPEC.md` | Chrome extension spec for website support (teammate handoff) |
| `design/CLAUDE_DESIGN_PROMPT.md` | Prompt for the full UI, design system and pitch assets |
| `docs/hackathon/` | Official briefing slides and kickoff transcript (rules, judging, submission) |
| `docs/research/` | Idea research and competitor analysis |

## Quick start

**Requirements:**
- Apple Silicon Mac, macOS 26, Xcode command-line tools
- An Apple Development signing identity (keeps the Accessibility permission valid across rebuilds)

```bash
# 1. Build and sign the app
app/scripts/build_app.sh
open app/build/ScreenGuide.app        # grant Accessibility when prompted (System Settings › Privacy & Security › Accessibility)

# 2. Read another app's commands (it must be running)
open -W -n app/build/ScreenGuide.app --args --dump Preview /tmp/preview.json
open -W -n app/build/ScreenGuide.app --args --dump Preview /tmp/preview.json --menus-only

# 3. Run the benchmark against a local decision model
#    Laya (open, ~0.4B): pip install "laya[serve]"
LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=mps laya-serve &
cd ml && python3 bench_localjev.py --url http://127.0.0.1:8766 --model convaiinnovations/laya --group 16 --fixture fixtures/preview_real.json
```

**Build training data and fine-tune:**
```bash
ml/dump_apps.sh /tmp/sg/train                # dump menus of the training apps
cd ml && python3 build_trainset.py /tmp/sg/train
laya-train --data data/train.jsonl --eval data/val.jsonl --base convaiinnovations/laya --out ../models/laya-guide --device mps
```

## What runs locally vs. needs internet

| Component | Runs | Notes |
|---|---|---|
| Reading the screen (Accessibility tree, menus) | Local | macOS Accessibility API |
| Choosing the next step | Local | Laya (fine-tuned) or Qwen3.5-4B via local-jev |
| Overlay, step verification | Local | |
| Speech input (planned) | Local | On-device speech recognition |
| Model download | Internet, once | Hugging Face |
| Hosted Jev | Internet | **Benchmark comparison only**, not used by the product |

## Models, tools and disclosures
- **Local models:**
  - [Laya](https://huggingface.co/convaiinnovations/laya) (Apache-2.0, Convai Innovations), base and fine-tuned
  - Qwen3.5-4B via [local-jev](https://github.com/amithgc/local-jev) (MIT)
  - Apple Foundation Models (on-device, tested and rejected, see RESULTS)
- **Cloud, comparison only:** TypeSafe Jev API.
- **Training data:** goals written by Claude Opus (Anthropic) subagents from real app menus; labels verified programmatically.
- **AI development tools:** Claude Code.
- **Existing code:** none. Everything here was written during the hackathon (Oct 9–10, 2026).
