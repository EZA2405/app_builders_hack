# Gabay

**A patient guide that shows people where to click on their Mac, one step at a time, with the AI running on their own computer.**

*Gabay* is Filipino for "guide". AppBuildersPH Hackathon 2026 · Theme: Local AI.

## What it is

Gabay shows older and non-technical people where to click next on their Mac, so they don't have to wait for family or share their screen with a stranger. You ask in English or Taglish, by voice or by typing ("nawalan ako ng Wi-Fi", "make this photo smaller so I can email it"). Gabay reads the real controls of the app or web page in front of you, a small model we fine-tuned picks the next one **on the Mac**, and a ring appears around it with one plain sentence. **You click; Gabay never clicks for you.**

## Demo

**Video (about 1 minute):** VIDEO_LINK_HERE

Demonstrated live on the dev Mac during the hackathon (Oct 9–10, 2026). These are demonstrations, not benchmarks. The benchmarks are under [Measured results](#measured-results).
- **Preview:** rotate a photo, print it, add text to it.
- **TextEdit:** make the words bigger.
- **System Settings:** Apple menu → System Settings → Wi-Fi, ending on the Wi-Fi switch.
- **YouTube:** search → an adobo cooking video → turn on subtitles (CC).
- **Facebook:** friend requests; Marketplace.
- **Instagram:** Reels.
- **FaceTime:** opened from the browser when the request named it.

## Why local

This is our answer to "Why does this product benefit from running AI locally?"

- **What's on screen is private, even the menus.** We measured it: app menus alone list recent file names, browsing history, an account name and email, device names, and window titles with user, host and email. One early cloud benchmark run sent 10 recent Preview file names before we added filtering ([details](ml/RESULTS.md#privacy-findings)). Many pages people need help with (PhilHealth, SSS, banks) show health records and government IDs. The Data Privacy Act treats these as sensitive personal information ([RA 10173 §3(l)](https://lawphil.net/statutes/repacts/ra2012/ra_10173_2012.html)).
- **Help that never asks for your screen.** GCash tells users never to share their OTP, MPIN, passwords or screen ([GCash](https://mynt.com.ph/newsroom/gcash-cautions-the-public-against-new-scams-forcing-users-to-download-fake-mobile-apps-from-suspicious-websites)). In 2026, fake eGovPH callers guided victims step by step over a shared screen into installing a banking trojan ([Trend Micro](https://news.trendmicro.com/2026/04/24/fake-egovph-app/)). 52% of Filipinos have been scammed at least once ([GSMA, Nov 2025](https://www.gsma.com/newsroom/press-release/rising-scam-exposure-in-the-philippines-underscores-need-for-cross-sector-action-warns-new-gsma-report/)).
  - A cloud screen helper is a screen share. Gabay sends nothing off the Mac and never clicks, so there is nothing to watch or hijack.
  - A local check pauses scam-style requests like "a man from PhilHealth needs my OTP" with a calm "Wait" card. On our 30-request test set it caught 13 of 14, with 0 false alarms out of 16.
- **It works when the internet is the problem.** Connecting to Wi-Fi is the basic task older people fail most: 35% of UK over-65s can't do it ([Age UK](https://www.ageuk.org.uk/latest-press/articles/2023/age-uk-analysis-reveals-that-almost-6-million-people-5800000-aged-65-are-either-unable-to-use-the-internet-safely-and-successfully-or-arent-online-at-all/)). Only 48.8% of Philippine households had home internet in 2024 ([PSA](https://insiderph.com/internet-access-in-ph-expands-but-cost-still-a-barrier-psa-dict-survey)). Voice, decisions, wording and the scam check all run on the Mac, so Gabay can walk someone to the Wi-Fi switch while they are offline.
- **No account, subscription or message cap.** People who need help ask many times per task. Cloud screen helpers meter this: HeyClicky's free tier is 25 messages a month, and its paid plans are $20 or $100 a month ([heyclicky.com](https://www.heyclicky.com/), checked Oct 9, 2026). On the person's own Mac, each extra question costs nothing.

## How it works

```
 you: "nawalan ako ng Wi-Fi"            (typed, or spoken: Whisper large-v3-turbo on this Mac)
        │
        ▼
 Gabay.app ── Accessibility ──► menus · window controls · dialogs · Dock · menu bar    (browser: extension → ws://127.0.0.1:47823)
        │
        ├─ scam check: keyword rules + the fine-tuned Laya (yes/no) ──► calm "Wait" card
        ├─ System Settings job? Which pane? ── Apple on-device model, request text only
        ▼
 Laya fine-tuned v6en (421M, 127.0.0.1:8766): 16-wide tournament over the real controls → one pick + confidence
        │
        ▼
 Apple on-device model words the step. It must name that exact control, or a fixed template is used.
        │
        ▼
 Overlay: ring + one sentence → your click inside the ring → screen read again → next step → "Did that do it?"
```

On websites, the browser extension (Chrome, or Dia) reads the page and draws the ring; the Mac app decides. Apple's on-device model also names the site to open and splits two-part requests ("find an adobo video and turn on subtitles"). Laya picks every element.

**UX that covers for a small model:**
- **Not this one** drops the guess and asks the model for its next best.
- A correction right after a request ("No, I meant…", "hindi…") rules out what Gabay just showed.
- It asks instead of assuming. It says "Is this what you wanted?" when a page looks like the goal, and "Did that do it?" before it finishes. **Not yet** keeps going.
- Clicking somewhere else gets a gentle "That's okay. Click **Tools** instead."
- When it isn't sure, it shows two numbered rings: "It's one of these."
- If nothing happens for a while, the rest of the screen dims around the ring.
- On websites it never rings Like, Share, Follow, Delete, Pay and similar buttons unless you asked for that.
- Text comes in three sizes, and every step can be read aloud.

## Measured results

Every number below is in [ml/RESULTS.md](ml/RESULTS.md), with its date and reproduce command. They were measured on an Apple M4 (16 GB) or on the stated training GPU.
- **Held-out test sets** are never used in training, and their answer keys were written before any model ran:
  - apps: Preview, Finder, System Settings and Safari (35 goals);
  - websites: YouTube, Wikipedia, Shopee and PhilHealth (45 single steps).
- **Models are chosen by validation:** 127 goals in 4 other unseen apps (Activity Monitor, Disk Utility, Numbers, Terminal).

| Model | Runs | Validation (127) | Held-out apps (35) | Held-out web steps (45) | Scam check: caught / false alarms |
|---|---|---|---|---|---|
| Laya base (421M) | Local | — | 8 | 12 | 6/14, 0/16 (at 0.4) |
| Laya fine-tuned v1 | Local | 79 | 25 | 25 | 7/14, 0/16 (at 0.6) |
| Laya fine-tuned v3 | Local | 95 | 26 | 29 | — |
| Laya fine-tuned v4e5 | Local | 98 | 29 | 28 | — |
| **Laya fine-tuned v6en (in Gabay)** | **Local** | **100** | **29** | **32** | **13/14, 0/16 (at 0.3–0.7)** |
| Laya fine-tuned v6ml (multilingual base) | Local | 91 | 23 | 29 | 14/14, 0/16 (at ≤ 0.5) |
| Laya fine-tuned v7en | Local | 98 | 28 | 32 | 13/14, 0/16 (at 0.3–0.7) |
| Laya fine-tuned v8en | Local | 95 | 28 | 32 | 14/14 at 0.3–0.5, 13/14 at 0.6–0.7; 0/16 |
| TypeSafe Jev (`jev-latest`) | Cloud, reference only | — | **35** | — | 14/14, 0/16 (at 0.4–0.5) |
| OpenAI Decisions API (`gpt-6-luna`) | Cloud, reference only | 29/30 (Activity Monitor only) | 33 | — | — |

- **The scam check** uses 30 requests written before any run: 14 scam-style (share your screen, install a remote-control app, give away a code, password or PIN) and 16 normal look-alikes.
  - The decision threshold is in parentheses.
  - Gabay uses v6en at 0.6, plus keyword rules.
- **v6en ships because it has the best validation score.**
  - v7en (+1,526 targeted rows) and v8en (+762 rows) scored lower on validation (98 and 95), so v6en stays.
  - Their single held-out runs are still reported above.
- **The gap to the cloud is real.**
  - Held-out apps: v6en 29/35, against 35/35 (Jev) and 33/35 (OpenAI).
  - Websites it never trained on: v6en gets 32 of 45 single steps right, about 7 in 10.
  - That's why Gabay asks "Is this what you wanted?" and offers **Not this one**.
- **v6en per app and site:**
  - Apps: Finder 8/8, Preview 7/10, Safari 8/9, System Settings 6/8.
  - Sites: YouTube 8/10, Wikipedia 9/10, Shopee 8/10, PhilHealth 7/15.
- **Speed (median per decision):**
  - v6en on the M4 (MPS): 2.1 s on Preview, where the same checkpoint reproduced 7/10.
  - Cloud references, depending on the app: 0.35–1.6 s (Jev) and 0.38–1.01 s (OpenAI).
  - Local is slower, but it doesn't depend on the connection.
- **"Which app?" check** (162 goals from the held-out and validation apps): v6en 97/162.
- **Teacher labels:** hosted Jev agreed with 733 of 774 (94.7%) Claude-written training labels. The 41 disagreements were dropped from training.

**Real requests on this Mac (dev set, not a benchmark).**
- **The requests:** taken from [USER_TASKS.md](docs/research/USER_TASKS.md), plus "stay in the app" sets for TextEdit, Preview and Music. Acceptable answers were written before running.
- **The run:** Gabay's real decision path on the live apps, first step only.
- **Why it's a dev set:** the System Settings routing was built while looking at these results.

| Start app | First step right |
|---|---|
| Finder | 12/14 |
| System Settings | 12/12 |
| TextEdit | 8/9 |
| Preview | 5/6 |
| Music | 3/3 |
| Scam check | 7/7 |
| **Total (Mail not scored)** | **47/51** |

- **"Is this a System Settings job?"** (27 dev requests, 12 of them settings jobs): Apple's on-device model caught 12/12 with 2/15 false alarms. The fine-tuned Laya caught 5/12 with 1/15. That's why Apple's model does this one job.
- **Rejected experiments, reported anyway:**
  - Apple's on-device model as the picker scored 4/10 on a hand-typed Preview menu.
  - Having it rewrite the request first lowered validation from 102 to 92/127.
  - Having it judge Laya's top 3 gave no real gain: 102–103/127, against 102/127 without it.

## What runs locally vs. needs internet

| Component | Runs | Notes |
|---|---|---|
| Reading the screen | Local | macOS Accessibility tree for apps; page elements via the browser extension over `ws://127.0.0.1:47823`. Never pixels. Text-field values are never read |
| Voice input | Local | Whisper large-v3-turbo (q5_0) via whisper.cpp on the Mac's GPU, as a server Gabay starts on `127.0.0.1:8767`. Falls back to Apple's on-device speech recognition (`requiresOnDeviceRecognition`) if Whisper isn't installed |
| Choosing the next control; scam check | Local | Fine-tuned Laya v6en on `127.0.0.1:8766` (MPS), plus keyword rules |
| Step wording, plan sentence, System Settings routing, which website, splitting web requests | Local | Apple Foundation Models (on-device). Sees the request, the app or page title, and the control Laya already chose. Never picks the control |
| Read aloud | Local | `AVSpeechSynthesizer` |
| Overlay, click checking | Local | |
| The websites themselves | Internet | The page has to load. What Gabay reads from it goes only to the local model |
| Setup downloads | Internet, once | Laya (Hugging Face), whisper.cpp (Homebrew), Whisper weights (Hugging Face). macOS downloads Apple's on-device model when Apple Intelligence is turned on |
| Hosted Jev | Internet | **Development only:** benchmark reference and training-data labeler, on sanitized menu and page text. Never in the product path |
| OpenAI Decisions API | Internet | **Development only:** second benchmark reference, on sanitized fixtures and one logged-out public page. Not used for training |
| Extension mock orderer | Internet | **Extension testing only** (`extension/mock/`), from before the Mac app was the brain. Not used by Gabay |

With Wi-Fi off, Gabay still guides Mac apps and System Settings.

## Limitations

- **Some apps hide their controls.** Telegram, WhatsApp, Spotify and Zoom don't expose their buttons to macOS Accessibility, so Gabay sees only their menus.
- **Web pages need internet** to load. The decisions still run on the Mac. The extension runs in Chromium browsers (Chrome, Dia), not Safari.
- **A 0.4B model gets steps wrong.**
  - On websites it never trained on, it gets about 7 in 10 single steps right (32/45). PhilHealth is the weakest site, at 7/15.
  - On unseen apps it scores 29/35, where the cloud references score 33–35/35.
  - So Gabay asks ("Is this what you wanted?", "Did that do it?") and recovers ("Not this one", corrections) instead of assuming.
- **Long journeys rely on the person staying in control.** By design, it points and you click. It doesn't type for you either: passwords, messages and search words are yours to type.
- **The scam check is not scam detection.** It only pauses requests to share a screen, install a remote-control app, or give away a code, password or PIN. It caught 13 of 14 on our test set, so rewordings can slip through.
- **Instructions are in English.** Requests can be in Taglish, but the step sentences are written in English. There is no Taglish benchmark yet.
- **Mac only** (Apple Silicon, macOS 26). Mac is about 7% of Philippine desktop traffic ([StatCounter](https://gs.statcounter.com/os-market-share/desktop/philippines)). Windows and phones aren't built.

## Quick start

**Requirements:**
- Apple Silicon Mac, macOS 26, with Apple Intelligence turned on (for Apple's on-device model)
- Xcode command-line tools
- An Apple Development signing identity (keeps the Accessibility permission across rebuilds)
- Python 3.12 with `pip install "laya[serve]"`
- A fine-tuned checkpoint in `models/`: `models/laya-guide` → `laya-guide-v6en`. Weights aren't in git; train it with the command below.
- Optional, for voice: whisper.cpp and the Whisper model (without them, dictation uses Apple's on-device recognizer):
  ```bash
  brew install whisper.cpp
  mkdir -p ~/Library/Application\ Support/Gabay/whisper
  curl -L -o ~/Library/Application\ Support/Gabay/whisper/ggml-large-v3-turbo-q5_0.bin \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
  ```

```bash
app/scripts/build_app.sh   # build and sign Gabay (app/build/ScreenGuide.app)
./run.sh                   # start the local model server (127.0.0.1:8766) and Gabay
```

On first launch, Gabay walks you through turning on Accessibility. After that, click the round button in the bottom-right corner, or press **Option + Space**. Right-click the button for Settings (text size, read aloud, ring color).

**Websites:** load `extension/` as an unpacked extension in Chrome (or another Chromium browser such as Dia). It connects to the Mac app on `ws://127.0.0.1:47823/ext`, and only that extension ID is accepted.

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
~/.venvs/modal/bin/modal run modal_train.py --version v6en --data data/v6/train.jsonl --epochs 5 --head 320   # or finetune_colab.ipynb
```

## Repo layout

| Path | What |
|---|---|
| `app/` | Gabay macOS app (Swift 6.2, macOS 26): Accessibility reader, guide loop, overlay, Ask card, Whisper dictation, extension bridge |
| `extension/` | Browser extension: reads the page and draws the ring. It makes no decisions ([SPEC](extension/SPEC.md)) |
| `ml/` | Fixtures, data builders, distillation, Laya fine-tuning (Colab / Modal), benchmarks, risk and routing evals |
| `ml/RESULTS.md` | **Every measured number**, with reproduce commands |
| `design/gabay_v2/` | UI design system, screens and copy sheet |
| `docs/` | Hackathon briefing, research (positioning, user tasks), submission answers, launch post, video shot list |
| `launch-videos/` | Launch-film drafts (Hyperframes projects) |
| `run.sh` | One-command launcher |

## Models, tools, data and disclosures
- **Models in the product (all run on the Mac):**
  - [Laya](https://huggingface.co/convaiinnovations/laya) (Apache-2.0, Convai Innovations), 421M parameters, fine-tuned by us. We trained English and multilingual variants. The shipped checkpoint is **v6en**, chosen by validation. It picks every control and runs the scam check, served locally with `laya-serve`.
  - [Whisper](https://github.com/openai/whisper) large-v3-turbo (OpenAI, MIT), 5-bit quantized, run with [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT) for voice input.
  - Apple Foundation Models (the on-device system model). It writes the step sentence (checked, with a fixed template as fallback) and the plan sentence. It also routes System Settings jobs, names the website to open and splits two-part web requests. It never picks the control.
  - Apple on-device speech recognition (dictation fallback) and speech synthesis (read aloud).
- **Models used during development (cloud):**
  - TypeSafe **Jev** API (`jev-latest`): reference benchmark, plus soft labels, goal labels and risk labels for distillation into Laya. It only ever saw sanitized menu and page text: personal entries are removed by `ml/make_fixtures.py` (`is_personal`, `redact_names`).
  - **Claude** (Anthropic; Opus subagents in Claude Code) wrote the teacher goals, paraphrases, trap goals, web journeys and the v7/v8 contrast goals from real menus. Every answer is verified programmatically against the real command list.
  - Claude Haiku via Claude Code CLI, or OpenAI Codex CLI, served as the stand-in step picker in the extension mock (testing only).
  - OpenAI **Decisions API** (`gpt-6-luna`, public beta): second cloud benchmark reference only, on sanitized fixtures and one logged-out public page. It is not used for training (OpenAI's terms, §3.3(e)) or in the product.
  - Also tried: Qwen3.5-4B via [local-jev](https://github.com/amithgc/local-jev) (MIT). No benchmark result was recorded.
- **Training data sources:**
  - menus and dialogs of the training apps on the dev Mac (sanitized);
  - public web pages crawled with a fresh, logged-out headless Chrome profile (`ml/web/`);
  - teacher goals from the sources above. The v6 training set has 28,250 rows (`ml/data/v6/train.jsonl`).
  - The held-out apps (Preview, Finder, System Settings, Safari), the held-out websites (YouTube, Wikipedia, Shopee, SSS, PhilHealth) and the validation apps (Activity Monitor, Disk Utility, Numbers, Terminal) are excluded from training. The data scripts refuse to build rows from them.
- **Compute:** Google Colab (T4) and Modal (H100, free credits) for fine-tuning and benchmark runs. All product inference runs on the Mac.
- **Frameworks and tools:**
  - Swift: AppKit, SwiftUI, Accessibility, FoundationModels, Speech, AVFoundation, Network.
  - Extension: Manifest V3 browser extension in plain JavaScript.
  - Models and data: laya / `laya-serve` (PyTorch), whisper.cpp via Homebrew, Python 3.12 (stdlib scripts), Hugging Face.
  - Testing and video: Playwright (extension tests only), Hyperframes (launch-video drafts).
- **AI development tools:** Claude Code and OpenAI Codex. UI design was explored with Claude Design. Launch-video drafts were made with the /brag skill and Hyperframes.
- **Existing code and assets:**
  - No pre-existing project code. Everything here was written during the hackathon (Oct 9–10, 2026). The extension was started by a teammate (Edu).
  - Third-party pieces are used as-is: Laya weights and `laya-serve`, Whisper weights and whisper.cpp, and Apple's system frameworks.
  - `launch-videos/.claude/skills/` holds the /brag skill ([latent-spaces/brag](https://github.com/latent-spaces/brag)) and HeyGen Hyperframes skills, copied in with their bundled music and sound effects.
  - `launch-videos/product app video*.mp4` are reference launch films used for style.
