# Beside launch videos

Two launch films for Beside, made with [/brag](https://github.com/latent-spaces/brag) and [Hyperframes](https://hyperframes.heygen.com/). They tell the same story, each in one of the two directions from the Claude Design handoff (`../design/handoff/design_handoff_beside/`).

| Folder | Design | Video |
|---|---|---|
| `design-a/` | A · Liquid Glass (chosen). v2, 31s: full-screen 3D camera, kinetic type, macro zooms | `design-a/brag.mp4` |
| `design-a-v15/` | **A, v15 (newest):** v14 with even pacing (Wednesday and Friday get the most extra time, shorter static holds) and fixes for cut-off cards, a blank sliver, the carousel/phone overlap and the heart position. 60s | `design-a-v15/brag.mp4` |
| `design-a-v14/` | A, v14: v13 slowed to 60 s (day changes 2× slower), all motion blur removed, softer transition easing. 60s | `design-a-v14/brag.mp4` |
| `design-a-v13/` | A, v13: keynote cut, take 2. v12 plus: "time passes" transition (camera dives into the menu-bar clock, days roll like a clock face, pulls out of the next day's clock), texts on a 3D iPhone, Mac drawn as hardware (bezel, notch, glass), calmer lighting. 47s | `design-a-v13/brag.mp4` |
| `design-a-v12/` | A, v12: keynote cut. v11's story on a black stage with purple light, device bezel, film grain; device rises from a steep tilt, turntable flips between days, deep camera zooms with motion blur, light sheens, cinematic whooshes/bass hits/riser. 47s | `design-a-v12/brag.mp4` |
| `design-a-v11/` | A, v11: v10 with natural Taglish (only Rosa ↔ Sam and her requests; headlines in English), no caption pills, and launch-film motion: masked word rises, product-reveal tilt, continuous 3D orbit, depth swing between days. 47s | `design-a-v11/brag.mp4` |
| `design-a-v10/` | A, v10: v9's story redrawn with the collaborator's v2 screens (`design/gabay_v2`: purple ring, one-sentence cards, corner Gabay button, Ask pill, thinking dot). Day changes now use a Spaces-style slide instead of the expanding circle. 47s | `design-a-v10/brag.mp4` |
| `design-a-v9/` | A, v9: v4 approach + all v6 scenes (Lunes Wi‑Fi, Miyerkules storage, Biyernes headphones) + "At marami pang iba" carousel (photo, bigger text, brightness), Filipino/Taglish. 47s | `design-a-v9/brag.mp4` |
| `design-a-v8/` | A, v8: v3/v4 approach (English, gravity opener, iris, ring motif, "Works in any app" carousel, "I did it myself") with v6's use cases (Wi‑Fi offline hero; Trash, headphones, photo as live carousel cards). 36s | `design-a-v8/brag.mp4` |
| `design-a-v7/` | A, v7: v6's three problems played side by side on three screens, each turning green as Rosa fixes it, then the climax and end card. 25s | `design-a-v7/brag.mp4` |
| `design-a-v6/` | A, v6: "Kaya ko na" (the user's storyboard). Three moments she'd usually call Sam for (Wi‑Fi offline, full disk, headphones), Taglish, ring wipes between days. 40s | `design-a-v6/brag.mp4` |
| `design-a-v5/` | A, v5: "When the internet is the problem". Wi‑Fi rescue offline + private screens; positions against cloud helpers like HeyClicky. 40s | `design-a-v5/brag.mp4` |
| `design-a-v4/` | A, v4: v3 + more motion: gravity-drop opening, iris reveal, 3D float, "Works in any app" carousel. 37s | `design-a-v4/brag.mp4` |
| `design-a-v3/` | A, v3: "Help shouldn't have to wait". Family-text opening, ring motif, studio framing, Gabay. 33s | `design-a-v3/brag.mp4` |
| `design-a-studio/` | A, Screen Studio-style edit: inset rounded window on slate, gentle zooms, product named **Gabay**. 31s | `design-a-studio/brag.mp4` |
| `design-b/` | B · Island. v1, 25s: dark, black island at the top, blue corner brackets | `design-b/brag.mp4` |

Each folder holds `brag-plan.md` (story + storyboard), `composition-brief.md` (Hyperframes handoff), `share-copy.txt`, `brag.jpg` (poster, also frame 0 of the video) and `composition/` (editable source).

## Edit and re-render

Requirements: Node 22+, FFmpeg, Google Chrome.

```bash
cd launch-videos/design-a/composition   # or design-b
npx hyperframes@0.8.143 preview          # open the Studio timeline
npx hyperframes@0.8.143 check            # pre-render gate
npx hyperframes@0.8.143 render --quality delivery --output ../brag.mp4
```

Copy, timing and camera moves live in `composition/index.html`; every scene is commented with its time range.

## Other files

- `product app video*.mp4`: reference launch films used for the v2 style.
- `archive/`: Design A v1 video and source.

- `.claude/skills/`: the /brag skill and the five Hyperframes skills it uses, installed with `npx skills add` (project scope, copied).
- `reference/design-screens/`: every artboard from the design handoff, captured by `tools/capture-design.mjs`.
- `reference/gabay-v2-screens/`: every artboard of the v2 redesign (`design/gabay_v2/Gabay Screens.dc.html`), captured the same way.
- `tools/`: helper script plus its pinned packages (`npm install` inside `tools/` restores them).

The persona (Rosa), the photo and the timestamps come from the design mockups. The videos show the designed experience. The overlay UI is still being built in `../app/` (see `../README.md`).
