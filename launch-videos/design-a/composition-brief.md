# Hyperframes Composition Brief: Beside — Design A · Liquid Glass

## Objective
Create a short, Apple-style launch film for Beside rendered in Design A of the Claude Design handoff.

## Output
- Composition directory: `design-a/composition/`
- Rendered video: `design-a/brag.mp4`
- Format: landscape — 1920x1080, 30fps
- Duration: 31s (v2; user asked for a fuller premium launch film)

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
- Interpretation: kinetic type on white and over a defocused screen; the demo fills the whole frame; continuous camera, no hard cuts; long enough holds to read every instruction
- Hook: the Mac rises while Beside listens to “Make this photo smaller so I can email it.”
- Outro: Beside mark + “A patient guide for your Mac.”
- Avoid: generic SaaS language, accuracy stats, abstract filler, any change to the design's tokens

## Visual Identity
Light stage, glass cards (rgba(255,255,255,.74) + blur 30 + saturate 1.8), Beacon ring #F08A24 with 2px white inner ring and glow, Beacon Ink #B85A00 key words, Ink #1C1C1E text, SF Pro.

## Storyboard
Use `brag-plan.md` (Version 2 storyboard table) as the creative contract. Full-frame screen on a 3D rig; kinetic word-by-word type; defocus between beats; whip moves with motion blur; macro zooms on Tools, Width and Wi‑Fi Off.

## Audio
- Music: `assets/music/happy-beats-business-moves-vol-12-by-ende-dot-app.mp3` at 0.30, fade out from 23.6s
- Cue guidance: `.claude/skills/brag/assets/music/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.json`; beat-lock 13.11 (Adjust Size click), 17.47 (offline headline), 22.93 (logo); clicks on 9.29 / 12.02 beats
- Audio-reactive: subtle; `assets/audio-level.js` (pre-extracted with hyperframes-creative `extract-audio-data.py`) drives the glow behind the display
- SFX: `interface/click_003` on each human click, `keyboard/keypress-*` for typing 1200, `interface/drop_002` when the done card lands, `impact/impactSoft_medium_001` on the offline headline, `impact/impactBell_heavy_000` on the logo

## Hyperframes Instructions
Single standalone `index.html`, one paused GSAP timeline registered as `window.__timelines["main"]`. Run `npx hyperframes check` before render; render locally.
