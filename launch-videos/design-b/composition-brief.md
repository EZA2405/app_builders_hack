# Hyperframes Composition Brief: Beside — Design B · Island

## Objective
Create a short, Apple-style launch film for Beside rendered in Design B of the Claude Design handoff.

## Output
- Composition directory: `design-b/composition/`
- Rendered video: `design-b/brag.mp4`
- Format: landscape — 1920x1080, 30fps
- Duration: 25s

## Source Material
- Project root: repository root (branch `launch-videos`, from `origin/main`)
- Primary files read: `README.md`, `design/handoff/design_handoff_beside/README.md`, `design/handoff/design_handoff_beside/source/Beside.dc.html` (same file as the shared Claude Design link), `ml/RESULTS.md`, `docs/research/*`
- Reference frames: `launch-videos/reference/design-screens/*.png` (captured from the handoff)
- Product name: Beside
- Tagline / strongest claim: “It points. You click.” + “Nothing on your screen leaves this Mac.”
- Key UI moment to recreate: the guided Preview task (shrink beach-day.jpg) — highlight on Tools, detour on Edit, Width 1200 confirmed, all done; Wi-Fi Off in the menu bar
- Copy that must appear verbatim: see the storyboard in `brag-plan.md` (all UI strings come from the design)

## Creative Direction
- Tone preset: polished
- Creative direction: Apple-style product launch film
- Interpretation: one short headline per beat above a Mac display; camera push-ins inside the display; soft transitions; long enough holds to read every instruction
- Hook: the Mac rises while Beside listens to “Make this photo smaller so I can email it.”
- Outro: Beside mark + “A patient guide for your Mac.”
- Avoid: generic SaaS language, accuracy stats, abstract filler, any change to the design's tokens

## Visual Identity
Dark stage #05050A, island #0B0B14 hanging from top-center (bottom radius 30), Signal #4C8DFF corner brackets + tag, Signal Text #8DB6FF key words, Text #F4F4F8, SF Pro Rounded + SF Mono labels, amber #FFB547 detour chip.

## Storyboard
Use `brag-plan.md` as the creative contract. Scenes: Ask 0–3.3 · Reading 3.3–6.6 · Points 6.6–9.5 · Wrong turn 9.5–13.3 · Checked 13.3–17.4 · Offline/private 17.4–21.4 · Logo 21.4–25.

## Audio
- Music: `assets/music/happy-beats-business-moves-vol-12-by-ende-dot-app.mp3` at 0.30, fade out from 23.6s
- Cue guidance: `.claude/skills/brag/assets/music/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.json`; beat-lock 13.11 (Adjust Size click), 17.47 (offline headline), 22.93 (logo); clicks on 9.29 / 12.02 beats
- Audio-reactive: subtle; `assets/audio-level.js` (pre-extracted with hyperframes-creative `extract-audio-data.py`) drives the glow behind the display
- SFX: `interface/click_003` on each human click, `keyboard/keypress-*` for typing 1200, `interface/drop_002` when the done card lands, `impact/impactSoft_medium_001` on the offline headline, `impact/impactBell_heavy_000` on the logo

## Hyperframes Instructions
Single standalone `index.html`, one paused GSAP timeline registered as `window.__timelines["main"]`. Run `npx hyperframes check` before render; render locally.
