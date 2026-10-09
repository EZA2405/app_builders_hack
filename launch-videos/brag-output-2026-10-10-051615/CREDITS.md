# Credits: Gabay launch video

- **Footage:** real screen recordings of Gabay on our own Mac (2026-10-10). Personal details are blurred: account name, family, nearby Wi‑Fi networks and the Facebook side panel. We cut one 0.6 s stretch from the Wi‑Fi clip where the user's mouse drifted onto the Finder menu; the steps Gabay showed are unchanged.
- **Music:** three short tracks from the HeyGen audio catalog, fetched with `hyperframes media-use` (HeyGen account of the maker). They are chained on bar lines at 120 BPM. Check HeyGen's terms before reusing them outside this video.
- **Voice-over:** Kokoro-82M (hexgrad, Apache-2.0) run locally with kokoro-onnx, voice `af_heart`, speed 0.95 (`make-vo.py`, lines in `vo-lines.json`). "Gabay" uses hand-set phonemes (ɡˌɑbˈaɪ) so it isn't read as "GAB-ay"; mid-video lines avoid the name. Every line was checked with our local Whisper.
- **Logo:** `design/logos/round2/14-purple-path.svg` (team logo explorations, branch `launch-videos`).
- **SFX:** HyperFrames/brag bundled library (whooshes, impacts, interface clicks, keypresses). The phone buzz is synthesized with ffmpeg.
- **Numbers on screen:** from `ml/RESULTS.md` and `README.md`: base Laya 8/35 → our fine-tune v6en 29/35 on held-out apps, versus OpenAI Decisions API 33/35 and TypeSafe Jev 35/35 (cloud, comparison only).
- **Built with:** HyperFrames 0.8.143 (GSAP), generator `build.mjs`, render/poster `finish.sh` (−14 LUFS master).
- Third-party pages seen in the footage (YouTube, macOS) belong to their owners; we are not affiliated.
