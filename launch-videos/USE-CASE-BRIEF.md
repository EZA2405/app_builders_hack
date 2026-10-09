# Gabay launch video: use-case brainstorm brief

Purpose: give a fresh collaborator everything needed to brainstorm **the single use case the launch video should showcase**. Facts are cited to files in this repo. Anything not cited is opinion and labelled as such.

## 1. The product in one paragraph

**Gabay** (working names: ScreenGuide, Beside) is a macOS app that teaches people how to do things on their Mac, one click at a time. You say what you want ("make this photo smaller so I can email it"). Gabay reads the controls of whatever app is open: menus, windows, dialogs, Dock and menu-bar status icons, via the macOS Accessibility API. A **local** model picks the next control. An overlay rings that exact control and shows **one** plain-language instruction. **The person clicks; Gabay never clicks for them.** It watches the screen change to confirm the step, calmly redirects wrong turns ("Small detour. Nothing has changed."), and then shows the next step. Built for older parents and non-technical adults, and for their kids who are the family's 24/7 tech support. (`README.md`, `design/handoff/design_handoff_beside/README.md`)

## 2. Context: the hackathon

AppBuildersPH Local AI Hackathon 2026 (build day Oct 9, demo day Oct 10). Judging criteria (`docs/hackathon/briefing.pdf`, p.14):

| Weight | Criterion | Question judges ask |
|---|---|---|
| 25% | Problem & usefulness | Does it solve a genuine problem for a clear target user? |
| 25% | Local AI implementation | Is local inference fundamental, and does it give a meaningful advantage? |
| 20% | Technical execution | Does it actually work, reliably enough for a live demonstration? |
| 15% | Innovation | Is it meaningfully different? Does local AI enable something new? |
| 15% | Product & demo | Is the UX usable, and is the live demo convincing? |

"Half the score is usefulness and how real your Local AI is." The pitch is 5 minutes plus 3 minutes of Q&A, with a live demo. The research handoff notes: "A visible offline demonstration is more persuasive than a privacy slogan." (`docs/research/HANDOFF.md`)

**So the use case must make local inference *fundamental*, not decorative.** That is the bar.

## 3. What actually exists today (be honest in the video)

- **Mac app (`app/`):**
  - Reads any app's menus, windows/dialogs, Dock and menu-bar status icons (Wi‑Fi, Bluetooth, Sound, Battery, Control Center) through Accessibility (`app/Sources/ScreenGuide/ScreenState.swift`).
  - Option+Space hot key opens the Ask panel, with on-device dictation only (`requiresOnDeviceRecognition`).
  - It asks "which app?" first, then "which control?", and follows the person into the app they open (recent commits on `main`).
- **Decision model:**
  - Validated pipeline: hosted reference model (TypeSafe Jev) scored **35/35** on 4 held-out apps.
  - **Local** fine-tuned Laya (421M): **25–26/35**, at 1.2–2.2 s per decision on an M4 (`ml/RESULTS.md`).
  - Today the Mac app can relay to hosted Jev "until the fine-tuned Laya lands", with personal menu entries dropped and names redacted first (commit `6e06716`). **The fully local path is real but less accurate. Do not claim more than that.**
- **Chrome extension (`extension/`):** guides websites with the same ring and card design. In development it uses a Claude/Codex or Jev stand-in, or local Laya on :8766.
- **Measured privacy finding:** "even 'just menu names' leak private data to a cloud model": recent file names, account name and email (Music), and window titles with user, host and email (Terminal). An early hosted run actually leaked 10 recent Preview file names before filtering existed (`ml/RESULTS.md`).
- **Benchmark goals (real, held-out):**
  - Finder: "empty the trash", "make a new folder"
  - Safari: "make the words on this page bigger", "clear my browsing history"
  - System Settings: "make the screen brighter", "connect to wifi", "turn on bluetooth for my headphones", "update my mac"
  - Preview: photo resizing

  (`ml/fixtures/*_real.json`)

## 4. Design (what the video must look like)

The chosen look is **Design A · Liquid Glass**:
- light, frosted glass cards;
- the orange **Beacon** ring around the control to click;
- the key word in orange;
- "Say it again" / "I'm stuck" buttons;
- a green ring with ✓ on confirm;
- "SMALL DETOUR" in amber, never red, never "wrong".

The persona is **Rosa** (older user); the helper contact is **Sam (son)**. The design's privacy screen says verbatim: *"Everything happens on this Mac. — Internet use: None. — Pictures of the screen: Looked at, then deleted right away. Never saved. — What you say: Turned into words on this Mac. Never recorded."* Reference frames are in `launch-videos/reference/design-screens/`.

## 5. Competitors: what "local" must beat

| Product | What it does | Where inference runs |
|---|---|---|
| **HeyClicky / Clicky** (heyclicky.com, github.com/farzaa/clicky) | AI buddy next to your cursor: sees the screen on hotkey, talks, points; an "agent" mode does tasks for you. Aimed at creators and coders (FL Studio, Claude Code). | Cloud: screenshot + voice go to Claude, AssemblyAI and ElevenLabs through a Cloudflare Worker. Needs internet. Keeps text summaries. |
| GuideLayer | Mac app that highlights controls and saves tutorials | "Local-first", but uses a Codex or Claude API key |
| ScreenDone | Browser screen-share and spoken guidance | Google Gemini (cloud) |
| Copilot Vision | Screen-aware guidance and highlights, never clicks | Cloud; no documented offline mode |
| Metis (Windows) | Screen companion with highlights; also autonomous | Advertises Ollama offline (unverified) |

(`docs/research/SCREEN_GUIDE_RESEARCH.md`; HeyClicky checked 2026-10-09.)

**Feedback to address:** the user said the video "feels kinda like heyclicky" and is "cool, not useful". The use case has to show something a cloud helper **can't do, or shouldn't be trusted to do**.

## 6. The videos so far

All in `launch-videos/`, built with /brag + Hyperframes (HTML compositions you can edit, rendered to MP4).

| Version | Use case | What the user said |
|---|---|---|
| v1 / v2 / studio | Shrink a photo in Preview to email it | v2 "too zoomed in"; the studio edit was liked for framing |
| v3 | Same task, plus a family-text frame (Rosa → Sam "In meetings all day") and the ring motif | Liked direction |
| **v4 (favourite)** | v3 + more motion: bubbles fall away under gravity, iris reveal, 3D float, "Works in any app" carousel (Finder / Safari / Settings real goals), springy logo | **Liked most** |
| v5 | Wi‑Fi is off → "Not Delivered" → Gabay walks her back online; then "Your bank. Your health. Your mail." + privacy screen | Not preferred over v4 |

**What v4 has that should be kept:**
- the emotional frame: the helper is busy, Rosa ends with "Never mind. I did it myself.";
- the ring as one continuous motif;
- studio framing with gentle zooms;
- kinetic type;
- springy physics;
- the "Works in any app" carousel;
- 33–37 s length.

**What v4 lacks:** a reason the task *needed* local AI. Photo-shrinking is low-stakes, so "offline" reads as a spec-sheet bullet.

## 7. What a winning use case needs (proposed criteria)

1. **A real, frequent pain** for older or non-technical Mac users. Ideally they'd otherwise call family or get scammed.
2. **Local is the reason it works, not a bonus.** At least one of:
   - (a) no or unreliable internet;
   - (b) the screen shows something you must not send to a cloud (money, health, passwords, family photos, legal or government IDs);
   - (c) the person can't or won't create accounts or paste API keys.
3. **Gabay's "never clicks for you" is a feature here.** Safety, consent and learning matter in this task.
4. **Showable in about 10 steps of real macOS UI**, with one natural "small detour" moment.
5. **Honest:** uses capabilities the app has or plausibly will have (menus, dialogs, Dock, status icons; native apps plus browser via the extension). No autonomous clicking, no claims of perfect accuracy.
6. **Demo-able live on stage** with Wi‑Fi visibly off.

## 8. Seed ideas to react to (opinion: not decided, not exhaustive)

| Idea | Why local matters | Risk |
|---|---|---|
| **Scam-call moment:** "Microsoft support" on the phone tells Rosa to install remote-access software. She asks Gabay instead, which shows how to check that and close the window. | Cloud helpers stream her screen while a scammer is on it; Gabay never clicks or uploads. | Tone; must not give security guarantees Gabay can't make. |
| **Bank or benefits portal task** (download a statement, turn on 2-step sign-in) | The screen shows balances and IDs; local means nothing leaves. | Web flow runs through the extension; mocks of real banks are off-limits (fictional only). |
| **Health portal** (download lab results to send to a doctor) | Medical data | Same as above |
| **Wi‑Fi down → get back online** (v5) | The only helper that works when the internet is the problem | User preferred v4's feel |
| **Travel / rural / spotty connection:** on a plane or in the province, "make the text bigger", "connect to hotel Wi‑Fi" | Offline by necessity; strong for the Philippines context | Less emotional |
| **Grief / estate:** a parent organises a late spouse's photos and accounts | Deeply private | Heavy tone |
| **Accessibility:** "make the words bigger", "turn on zoom", "make the pointer bigger" | Low vision; frequent need; nothing private | Weak local argument by itself |
| **Learning, not delegating:** the second time, Rosa does it with fewer hints ("Do what I did last Tuesday" is in the design) | Local history stays on the Mac | Harder to show in 30 s |

## 9. Constraints for whatever you pick

- 30–40 s video, landscape 1920×1080, Design A tokens, Rosa and Sam personas, Gabay name.
- All UI copy in the guidance cards must follow the design's voice: plain words; banned words are "menu bar item", "dialog" and "AI model".
- No real brand impersonation; fictional banks, portals and names only.
- Every on-screen claim must trace to the repo (README, design handoff, RESULTS, fixtures) or be clearly narrative framing.

## 10. Useful files

`README.md` · `design/handoff/design_handoff_beside/README.md` · `docs/research/HANDOFF.md` · `docs/research/SCREEN_GUIDE_RESEARCH.md` · `ml/RESULTS.md` · `ml/fixtures/*_real.json` · `app/Sources/ScreenGuide/ScreenState.swift` · `launch-videos/design-a-v4/brag-plan.md` · `launch-videos/design-a-v5/brag-plan.md` · `docs/hackathon/briefing.pdf`
