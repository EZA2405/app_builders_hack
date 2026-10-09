# Gabay

**A patient guide that shows people where to click on their Mac, one step at a time, with the AI running on their own computer.**

*Gabay* is Filipino for "guide". AppBuildersPH Hackathon 2026 · Theme: Local AI.

You say what you want, by voice or by typing ("make this photo smaller so I can email it", "paano mag-email ng picture"). Gabay reads the controls of the app in front of you. A **local, fine-tuned model** picks the next control, and Gabay puts a ring around it with one plain sentence ("Click **Tools**."). **You click; Gabay never clicks for you.** It watches for your click inside the ring, then shows the next step.

- **Works in any Mac app, and on websites.** It reasons over the app's real menus, buttons and dialogs, read through macOS Accessibility. These are not pre-written tutorials. A Chrome extension acts as a bridge for web pages: it reads the page and draws the ring, and the Mac app decides what to point at.
- **Never share your screen.** Remote "tech support" is how many older people get scammed. Gabay never needs to see pixels, and nothing on your screen leaves the Mac. A local risk check stops and warns when a request looks like a scam ("someone from the bank wants me to install AnyDesk").
- **Private by measurement.** App menus alone leak recent file names, browsing history, account names and emails (see [ml/RESULTS.md](ml/RESULTS.md#privacy-findings)). That is why the decision has to run locally.
- **Built for** older parents and non-technical adults, and for the kids who are the family's 24/7 tech support.

## How it works

```
 you: "make this photo smaller"          (typed, or on-device dictation)
        │
        ▼
 Gabay.app ── Accessibility ──► menus · window controls · dialogs · Dock      (Chrome: extension → ws://127.0.0.1:47823)
        │
        ▼
 Laya fine-tuned (421M, local, 127.0.0.1:8766) — 16-wide tournament over the real controls → one pick + confidence
        │                                       └─ same model: "is someone getting this person to share their screen / give a code?"
        ▼
 Apple on-device model words one plan sentence ("I'll help you save a smaller copy of your photo.")
        │
        ▼
 Overlay: purple ring + one sentence → waits for the click inside the ring → next step → "Done. You did it."
```

**UX that covers for a small model:**
- If the guess is wrong, **Not this one** asks for the next-best control.
- Clicking somewhere else gets a gentle "That's okay. Click **Tools** instead."
- When the model isn't sure, it shows two numbered rings and says "It's one of these."
- If nothing happens for a while, the rest of the screen dims around the ring.
- Text comes in three sizes, and every step can be read aloud.

## Measured results (all in [ml/RESULTS.md](ml/RESULTS.md))

These were measured on an Apple M4 (16 GB) or on the stated training GPU. Held-out apps are never used in training: Preview, Finder, System Settings and Safari.

| | Held-out apps (35 goals) | Held-out websites (45 steps) |
|---|---|---|
| Laya base (local) | 8/35 | 12/45 |
| Laya fine-tuned v1 (local) | 25/35 | 25/45 |
| Laya fine-tuned v3 (local) | 26/35 | 29/45 |
| **Laya fine-tuned v4e5 (local, current)** | **29/35** | 28/45 |
| Hosted Jev (cloud, reference only) | 35/35 | — |

Model selection uses a separate validation set: 127 goals in 4 other unseen apps. The scores are v1 79/127, v3 95/127 and v4e5 98/127. We also report the experiments that failed (Apple's on-device model as picker, goal rewriter and top-3 judge).

## Quick start

**Requirements:**
- Apple Silicon Mac, macOS 26
- Xcode command-line tools
- An Apple Development signing identity (keeps the Accessibility permission across rebuilds)
- Python 3.12 with `pip install "laya[serve]"`
- A fine-tuned checkpoint in `models/` (`models/laya-guide-v4e5`, or train your own, see below)

```bash
app/scripts/build_app.sh   # build and sign Gabay.app
./run.sh                   # start the local model server (127.0.0.1:8766) and Gabay
```

On first launch, Gabay walks you through turning on Accessibility. After that, click the round button in the bottom-right corner, or press **Option + Space**. Right-click the button for Settings (text size, read aloud, ring color).

**Websites:** load `extension/` as an unpacked extension in Chrome. It connects to the Mac app on `ws://127.0.0.1:47823/ext`, and only that extension ID is accepted.

**Dev modes:**
```bash
open -W -n app/build/ScreenGuide.app --args --dump Preview /tmp/preview.json        # read an app's commands
open -n app/build/ScreenGuide.app --args --guide Preview "make this photo smaller"   # start a session directly
open -n app/build/ScreenGuide.app --args --preview guide                             # render one UI state (ask/guide/notsure/wait/done/settings)
```

**Benchmarks and training:** see [ml/FINETUNE.md](ml/FINETUNE.md). Short version:
```bash
cd ml
python3 bench_localjev.py --url http://127.0.0.1:8766 --model guide --group 16 --fixture fixtures/preview_real.json
~/.venvs/modal/bin/modal run modal_train.py --version v6en --data data/v6/train.jsonl --epochs 5   # or finetune_colab.ipynb
```

## Repo layout

| Path | What |
|---|---|
| `app/` | Gabay macOS app (Swift 6.2, macOS 26): Accessibility reader, guide loop, overlay, Ask card, extension bridge |
| `extension/` | Chrome extension: reads the page and draws the ring. It makes no decisions ([SPEC](extension/SPEC.md)) |
| `ml/` | Fixtures, data builders, distillation, Laya fine-tuning (Colab / Modal), benchmarks, risk and routing evals |
| `ml/RESULTS.md` | **Every measured number**, with reproduce commands |
| `design/gabay_v2/` | UI design system, screens and copy sheet |
| `docs/` | Hackathon briefing, research (positioning, user tasks) |
| `run.sh` | One-command launcher |

## What runs locally vs. needs internet

| Component | Runs | Notes |
|---|---|---|
| Reading the screen (Accessibility tree; web page via extension) | Local | Text-field values are never read |
| Choosing the next step, risk check | Local | Fine-tuned Laya on `127.0.0.1:8766` (MPS) |
| Plan sentence | Local | Apple Foundation Models (on-device) |
| Voice input | Local | `SFSpeechRecognizer` with `requiresOnDeviceRecognition` |
| Read aloud | Local | `AVSpeechSynthesizer` |
| Overlay, click checking | Local | |
| Model download | Internet, once | Hugging Face |
| Hosted Jev | Internet | **Development only:** benchmark reference and training-data labeler, on sanitized menu text. Never in the product path |
| Extension mock orderer | Internet | **Extension testing only** (`extension/mock/`), from before the Mac app was the brain. Not used by Gabay |

## Models, tools, data and disclosures
- **Models in the product (local):**
  - [Laya](https://huggingface.co/convaiinnovations/laya) (Apache-2.0, Convai Innovations), fine-tuned by us. We trained English and multilingual variants.
  - Apple Foundation Models (on-device system model), used only to word the plan sentence.
  - Apple on-device speech recognition and speech synthesis.
- **Models used during development (cloud):**
  - TypeSafe **Jev** API (`jev-latest`): reference benchmark, plus soft labels, goal labels and risk labels for distillation into Laya. It only ever saw sanitized menu and page text: personal entries are removed by `ml/make_fixtures.py` (`is_personal`, `redact_names`).
  - **Claude** (Anthropic; Opus subagents in Claude Code) wrote the teacher goals, paraphrases, trap goals and web journeys from real menus. Every answer is verified programmatically against the real command list.
  - Claude Haiku via Claude Code CLI, or OpenAI Codex CLI, served as the stand-in step picker in the extension mock (testing only).
  - OpenAI **Decisions API** (`gpt-6-luna`, public beta): second cloud benchmark reference only, on sanitized fixtures and one logged-out public page; not used for training or in the product.
  - Also tested: Qwen3.5-4B via [local-jev](https://github.com/amithgc/local-jev) (MIT).
- **Training data sources:**
  - menus and dialogs of the training apps on the dev Mac (sanitized);
  - public web pages crawled with a fresh, logged-out headless Chrome profile (`ml/web/`);
  - teacher goals from the sources above.
  - The held-out apps (Preview, Finder, System Settings, Safari) and the validation apps (Activity Monitor, Disk Utility, Numbers, Terminal) are excluded from training.
- **Compute:** Google Colab (T4) and Modal (H100, free credits) for fine-tuning. All product inference runs on the Mac.
- **AI development tools:** Claude Code, OpenAI Codex. UI design explored with Claude Design.
- **Existing code:** none. Everything here was written during the hackathon (Oct 9–10, 2026). The extension was started by a teammate (Edu).
