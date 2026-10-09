# Brag Plan: Gabay — v5 "When the internet is the problem"

## Why this version
User feedback: the video was "cool" but not obviously *useful*, it didn't say why offline matters, and it felt "kinda like heyclicky".

**HeyClicky / Clicky** (heyclicky.com, open source at github.com/farzaa/clicky), checked 2026-10-09:
- It sends a screenshot plus your voice to Claude, AssemblyAI and ElevenLabs through a Cloudflare Worker proxy, so it needs internet.
- It keeps text summaries of sessions.
- It's aimed at creators and coders ("FL Studio", "Claude Code") and has an agent mode that does the task for you.

The other inspected competitors (ScreenDone → Gemini, GuideLayer → Codex/Claude key) are cloud too (`docs/research/SCREEN_GUIDE_RESEARCH.md`).

**Gabay's honest, structural edge**:
1. **When the internet itself is broken, cloud helpers can't run, and Gabay can.** This is the use case only local inference makes possible.
2. **Private screens.** "Your screen holds your bank, email and medical portals. App menus alone leak recent files, history, account names and emails (we measured it)" (`README.md`, `ml/RESULTS.md`).
3. **It teaches a non-technical person instead of acting for them.** It never clicks, calls a wrong turn a "small detour", and checks every step.

## Story (40s)
| Time | Beat |
|---|---|
| 0–2.2 | Rosa's Safari: "You Are Not Connected to the Internet." |
| 2.2–4.9 | She texts Sam: "Sam, my internet stopped working. Can you help?" → **Not Delivered**. The helper can't even be reached. |
| 4.9–7.5 | The message falls away. "When the internet is the problem, cloud help **can't help.**" |
| 7.5–9.1 | The ring draws; the iris opens on her Mac. Gabay is in the menu bar. |
| 9.1–13.7 | "my internet stopped working" → it reads the screen: ✓ Wi‑Fi is turned off ✓ Found your home network, Garcia Home. Caption: "No internet needed. It runs on this Mac." |
| 13.7–18.6 | The ring hops to the Wi‑Fi status icon: "Click the Wi‑Fi symbol…". Rosa clicks Bluetooth: "SMALL DETOUR — That opened Bluetooth. Nothing has changed." Captions: "It points. You click." / "No wrong turns. Just small detours." |
| 18.6–22.9 | Switch on → the network list expands → "Click Garcia Home" → connecting… ✓ The Wi‑Fi icon fills. |
| 22.9–25.4 | Green ring on Wi‑Fi: "You're back online, Rosa." Safari reloads her inbox. Caption: "Every step, checked." |
| 25.4–28.3 | Her message goes through (Delivered). "Never mind. I fixed it myself." Sam ♥. |
| 28.4–33.3 | Privacy: "Your bank. Your health. Your mail." Bank / patient portal / mail cards, each with the ring on the right control and "Stays on this Mac". Then: "Your screen stays on your Mac." |
| 33.3–36.5 | The design's own privacy screen (artboard 5a): Internet use — None. / Pictures of the screen — Looked at, then deleted right away. Never saved. / What you say — Turned into words on this Mac. Never recorded. |
| 36.5–40 | Ring → Gabay logo, "A patient guide for your Mac." |

## Grounding
- **Menu bar status icons:** reading Wi‑Fi and Bluetooth status icons is implemented in `app/Sources/ScreenGuide/ScreenState.swift` ("Menu bar status icons (Wi-Fi, Bluetooth, Sound, Battery, Control Center, ...)").
- **Wi‑Fi as a goal:** "connect to wifi" is a goal in the held-out fixture `ml/fixtures/systemsettings_real.json`.
- **Privacy rows:** verbatim from design artboard 5a, with Beside → Gabay.
- **Fictional content:** the bank, portal, mail content, network names and messages are fictional illustrations, built on the design's personas (Rosa, Sam).
- **Not claimed:** the guided Wi‑Fi flow itself is the designed experience, not a recording.

## Visual system
Same as v3/v4: warm paper stage, studio-framed Mac window with gentle zooms (at most 1.5×), a 3D float, the ring motif with an iris reveal, a "Rosa" pointer tag with click ripples, caption pills, and springy message physics.
