# Gabay: submission answers

These are ready to paste into the submission form on the event page (cerebralvalley.ai/e/appbuildersph-hackathon-2026).
- **Deadline:** 10:00 AM, Oct 10, 2026 (PH time).
- **Only once:** each team submits once and can't edit afterwards, so check every field first.
- **Sources:** every model number comes from [ml/RESULTS.md](../ml/RESULTS.md); every source for the other claims is in the [README](../README.md#why-local).

The answers are plain text so they paste cleanly.

## Fill in before submitting
- **Team name and members:** the official names listed on appbuildersph.com/hackathon.
- **Public GitHub repository:** https://github.com/EZA2405/app_builders_hack (it must be public at the deadline).
- **Demo video:** VIDEO_LINK_HERE (about 1 minute; see [video-shotlist.md](video-shotlist.md)).
- **X / LinkedIn video URL:** POST_LINK_HERE (text in [post.md](post.md); the post must tag Cognition and include #AppBuildersPH).

## Project name

Gabay

## Short description

*(278 characters)*

Gabay shows older and non-technical people where to click next on their Mac. Ask in English or Taglish, by voice or typing. A small model we fine-tuned runs on the laptop and rings the next button with one plain sentence. You click, not the AI. Your screen never leaves the Mac.

## What runs locally

Everything Gabay does to help runs on the Mac. It reads the app's real controls through macOS Accessibility (never screenshots), and web pages through our browser extension, which talks only to the Mac app over 127.0.0.1. Whisper large-v3-turbo (whisper.cpp) turns speech into text on the Mac's GPU, with Apple's on-device speech recognition as a fallback. Our fine-tuned Laya model (421M parameters, checkpoint v6en) picks the next control to ring and runs the scam check; it is served on 127.0.0.1 with PyTorch on the Mac's GPU. Apple's on-device Foundation Model writes each step sentence (checked, with a fixed template as fallback) and sends System Settings jobs to the right pane. On websites it also names the site to open and splits two-part requests. The overlay, click checking and read-aloud are local too. With Wi-Fi off, Gabay still guides Mac apps and System Settings.

## What requires internet

Websites themselves: the page has to load, but what Gabay reads from it goes only to the local model. One-time setup downloads: the Laya model and the Whisper weights (Hugging Face) and whisper.cpp (Homebrew); macOS downloads Apple's on-device model when Apple Intelligence is turned on. Nothing in the product calls a cloud AI API. During development only: hosted TypeSafe Jev (benchmark reference and training labels, on sanitized menu and page text), OpenAI's Decisions API (benchmark reference only), Claude (writing training goals, and coding through Claude Code), and Modal and Google Colab GPUs for fine-tuning.

## Models used

In the product (all run on the Mac):
- Laya (Convai Innovations, Apache-2.0), 421M parameters, fine-tuned by us. Shipped checkpoint: v6en, chosen by validation accuracy. It picks every control and runs the scam check.
- Whisper large-v3-turbo (OpenAI, MIT), 5-bit quantized, run with whisper.cpp (MIT), for voice input.
- Apple Foundation Models, the on-device system model in macOS 26: step wording, System Settings routing, choosing the website, splitting web requests. It never picks the control.
- Apple on-device speech recognition (dictation fallback) and speech synthesis (read aloud).

Development only, never in the product:
- TypeSafe Jev (jev-latest, hosted): benchmark reference and training-data labeler.
- OpenAI gpt-6-luna via the Decisions API: benchmark reference only.
- Claude Opus (in Claude Code): wrote teacher goals for training.
- Claude Haiku and the OpenAI Codex CLI: stand-in picker for extension testing.
- Also tried: Qwen3.5-4B via local-jev. No benchmark was recorded.

## Technologies and frameworks

macOS app in Swift 6.2 (AppKit, SwiftUI, the Accessibility API, FoundationModels, Speech, AVFoundation, Network), targeting macOS 26 on Apple Silicon. Browser extension: Manifest V3 in plain JavaScript, for Chrome and other Chromium browsers such as Dia, connected to the app by a local WebSocket. Model serving: laya / laya-serve (PyTorch on the Mac's GPU via MPS). Speech: whisper.cpp, installed with Homebrew. Training and evaluation: Python 3.12 standard-library scripts, laya-train, Hugging Face, Modal (H100) and Google Colab (T4). Testing: Playwright, for the extension. Launch-video drafts: Hyperframes.

## APIs and cloud services

In the product: none. Every model call goes to 127.0.0.1 (Laya on port 8766, Whisper on 8767) or to Apple's on-device model.

Development only:
- TypeSafe Jev API (hosted jev-latest): benchmark reference and training-data labeler, on sanitized menu and page text only.
- OpenAI Decisions API (gpt-6-luna, public beta): benchmark reference only, on sanitized fixtures and one logged-out public page. Not used for training.
- Anthropic Claude, through Claude Code: teacher-written training goals and coding.
- Modal (H100, free credits) and Google Colab (T4): fine-tuning and benchmark runs.
- Also: Hugging Face for model downloads, Homebrew for whisper.cpp, GitHub for code hosting.

## Existing code and assets

No pre-existing project code: the Mac app, the extension, the data and training scripts, the benchmarks and the design were all made during the hackathon (Oct 9–10, 2026). Used as-is from others: Laya weights and laya-serve (Apache-2.0), Whisper weights and whisper.cpp (MIT), and Apple's system frameworks. launch-videos/ includes the /brag skill (latent-spaces/brag) and HeyGen's Hyperframes skills, copied in with their bundled music and sound effects, plus two reference launch films used for style. docs/hackathon/ holds the organizers' briefing and kickoff transcript.

## AI development tools

Claude Code (Anthropic) for coding, research and data work; its Claude Opus subagents wrote the teacher goals used for training. OpenAI Codex CLI. Claude Design for UI exploration. The /brag skill with Hyperframes for launch-video drafts. The hosted TypeSafe Jev API also labeled training data (see APIs and cloud services).

## Why does this product benefit from running AI locally?

*(142 words)*

Gabay has to read the screen to help, and the screens people need help with are private: PhilHealth and SSS records, bank pages, their own files and email. We measured that even app menus leak recent file names, browsing history and email addresses; one early cloud benchmark run sent 10 file names before we added filtering. Banks and GCash teach one rule: never share your screen. Scammers now guide victims step by step over shared screens. Gabay gives the same step-by-step help with nothing leaving the Mac and never clicks for you. A local check pauses scam-style requests: on our test set it caught 13 of 14, with 0 false alarms out of 16. It also works when the internet is the problem: with Wi-Fi off, it still walks you to the Wi-Fi switch. There is no account, subscription or per-question cost.
