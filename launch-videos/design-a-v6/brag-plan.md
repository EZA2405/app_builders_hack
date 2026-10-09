# Brag Plan: Gabay — v6 "Kaya ko na"

Built from the user's storyboard (2026-10-09) on top of v4's motion language. Core message: *Hindi dapat mawala ang tech support mo kapag nawala ang internet.*

## Story (40s)
| Time | Scene | What happens |
|---|---|---|
| 0–12 | 1 · Walang internet | Safari "You Are Not Connected to the Internet" → camera finds the struck-through Wi‑Fi symbol → Rosa texts "Anak, nawala na naman internet 😭" → **Not Delivered** → Option + Space keycaps press → "Tulungan mo akong ibalik yung Wi‑Fi." → the ring hops from Gabay's icon to Wi‑Fi → Rosa clicks Bluetooth → SMALL DETOUR "That opened Bluetooth. Nothing changed. Look for Wi‑Fi" → Wi‑Fi menu → "Turn Wi‑Fi on." → Garcia Home joins ✓ → green ring, and her adobo recipe loads. Caption: "No internet? Gabay still works." |
| 12–21 | 2 · Puno na yung Mac | Ring wipe opens from the green Wi‑Fi ring: **Wednesday** → closes on the "Disk Almost Full" alert → she types "Sam…" and deletes it → Option + Space → "Paano ako maglilinis ng space?" → ring on Trash → "Click Empty." → the erase-forever sheet: the ring breathes slowly, the card says "This erases them for good. **Take your time.**" (label "YOUR CALL") → Rosa hesitates, then clicks Empty Trash ✓. Caption: "Gabay guides. Rosa decides." |
| 21–28.7 | 3 · Ayaw gumana ng headphones | Ring wipe from the Trash ✓: **Friday** → closes on the Bluetooth symbol → "🎧 Walang tunog…" → she types "Sam, paano—" and deletes it → Option + Space → "Gabay, tulungan mo akong i-connect headphones ko." → Bluetooth → "Click Rosa's Headphones." ✓ Connected → "Playing on Rosa's Headphones" ♪. Caption: "Ikaw pa rin ang nagki-click." |
| 28.7–33 | Climax | Sam: "Ma, kailangan mo ba ng tulong?" → typing… → Rosa: **"Okay na. Kaya ko na :)"** Delivered → Sam ♥. |
| 33–40 | End card | Quick glyph flashes (Finder, Safari, Settings, Wi‑Fi, Bluetooth) behind the ring drawing itself → Gabay mark → "Tulong na nandiyan **kahit offline.**" → • No cloud required. • Your screen stays on your Mac. • Ikaw pa rin ang nagki-click. → "Hindi nito ginagawa para sa'yo. Tinuturuan ka nitong gawin." |

Scene 1 gets the most time (offline proof); scenes 2 and 3 cut progressively faster, as the storyboard asked. The ring links every scene: it hops between controls, the wipe opens from each green ✓, and it draws the logo at the end.

## Grounding
| Element | Source |
|---|---|
| Option+Space hot key + on-device dictation | commit `6e06716` (`Voice.swift`, `requiresOnDeviceRecognition`) |
| Wi‑Fi / Bluetooth menu-bar icons | `app/Sources/ScreenGuide/ScreenState.swift` ("Menu bar status icons (Wi-Fi, Bluetooth, …)") |
| Dock icons on step 1 (Trash) | commit `726a074` |
| Goals "connect to wifi", "turn on bluetooth for my headphones", "empty the trash" | `ml/fixtures/systemsettings_real.json`, `ml/fixtures/finder_real.json` |
| Design voice: SMALL DETOUR, never red, green ✓, step labels | design handoff |

Fictional: the network names, the files, the song, the recipe site and the message text.

**Honesty note:** "No cloud required" and "kahit offline" describe the design and the local path (fine-tuned Laya runs on the Mac, 25–26/35 in `ml/RESULTS.md`). Today's Mac app can still relay decisions to hosted Jev until the local model lands (commit `6e06716`). Be ready for that question in Q&A, and demo with the local model if you show Wi‑Fi off live.

## Audio
vol-12 bed at 0.30. Message send and fail cues, key taps on Option and Space, a click for every one of Rosa's clicks, soft drops on each ✓, and a bell on the logo. Loudness normalised to -16 LUFS. Beat locks: 8.47, 9.84, 10.66, 17.47, 18.56, 20.19, 27.29, 28.92, 30.56, 31.1, 31.65, 33.29, 34.38, 36.02+.
