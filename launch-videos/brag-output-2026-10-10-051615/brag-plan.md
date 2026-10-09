# Brag Plan: Gabay

## What is this app?
A macOS helper for older Filipinos: ask in Taglish (voice or typing), and Gabay rings the next thing to click on the real screen with one calm sentence. Our own fine-tuned 421M model picks the control **on the laptop**, it warns when a request smells like a scam, and it never clicks for you and never sees your screen's pixels.

## The angle
**"The help scammers pretend to be — minus the scammer."** Today, the help seniors get is "share your screen", which is exactly how they get robbed (the 2026 fake-eGovPH scam guided victims step by step over a screen share). Gabay is that same step-by-step help, running on the laptop: nothing on her screen leaves it, and it works with the Wi‑Fi off. Honest, warm, Filipino; real product footage, not mockups.

## Hook (first 2–3 seconds)
A phone call card rings: **"PhilHealth"**. The caller's line builds word by word in Taglish: *"Ma'am, pakibasa po yung OTP na tinext namin."* (Ma'am, please read us the OTP we texted.) Clear the line, then match-cut: the word **OTP** becomes Gabay's amber **"Wait."** card.

## Key moments (the middle)
- **Real:** Lola asks Gabay; the amber **Wait** card slides in and is read aloud: "Never give the code sent to your phone to anyone…". Caption: **Caught on this laptop. Wi‑Fi off.** (Wi‑Fi-off icon visible.)
- **Real:** "Nawalan ako ng Wi‑Fi" (I lost my Wi‑Fi) → purple ring on the Apple logo → System Settings → **Wi‑Fi** → the switch → "Is it working?" Offline the whole way. Caption: **Works when the internet doesn't.**
- **Real, range montage (one beat each, then a grid):** YouTube "adobo, tapos subtitles" (adobo, then subtitles) → the **CC** button; Facebook "friend requests" → "Is this what you wanted?"; Preview "rotate this photo".
- **Real, honesty beat:** a wrong guess → **Not this one** → the next best. Caption: **When it isn't sure, it asks.**
- **Trust (kinetic numbers, measured only):** our model on apps it never saw **8/35 → 29/35**; cloud references Jev **35/35**, OpenAI **33/35**. Line: **Close to the cloud. Without the cloud.**

## Outro / punchline
**"It points. She clicks. Nothing leaves the laptop."** → product-hero end card: Gabay ring logo, address-bar CTA typing `github.com/EZA2405/app_builders_hack`, small line "Built in 24 hours · AppBuildersPH 2026 · Local AI".

## User flow worth showing
Ask (voice/typing) → purple ring on the exact control + one sentence → she clicks → next step / "Is this what you wanted?". Recorded live from the real app (one continuous screen recording, cut by the app's own step log timestamps).

## Tone
- Preset: polished (with cinematic hook)
- Creative direction: quiet Apple-keynote product film with a Filipino family heart; calm, not hype
- Interpretation: fast cuts and tight type for energy, but holds long enough to read; warm purple ring as the only color accent; one amber moment (the Wait card)

## Format: landscape — 1920x1080 (+ 4:5 feed 1080x1350 from the same generator)
## Duration: ~60 s (user choice; launch-video house style would be ~30 s — keep every beat earned)

## Visual identity (from the project, design/gabay_v2 + app Theme.swift)
- Background: flat near-black #0B0B0F (no gradients, no pulsing)
- Accent: ring purple #AF52DE (dark-mode #BF5AF2); warning amber #C27A00 on #FFF6E4 (Wait card); success #2FA35A
- Text: #F5F5F7 on dark; #1C1C1E on light cards
- Display/body font: system SF stack (-apple-system, BlinkMacSystemFont, system-ui), semibold, −0.045em tracking for big type
- Strongest visual: the breathing purple ring (4pt stroke, 2pt white inner edge, glow) around a real control, with the glass one-sentence card

## Share copy (draft)
Our 421M model runs on the laptop and shows Lola where to click: no screen sharing, no internet, no scammer. Built in 24 hours at #AppBuildersPH.

## Audio direction
- Role: warm modern bed + sparse, motion-matched accents
- Music: modern track (HeyGen catalog via media-use if available; fallback bundled vol-12 "steady and clean"), low-pass "exhale" on the Wait card, opening back up into the Wi‑Fi rescue/montage
- Music cue guidance: detect at composition time (`analyze_music_cues.py` or `hyperframes beats`); lock the montage start and the end-card logo to strong cues
- Audio-reactive treatment: none (flat background per house style)
- SFX posture: sparse — phone ring (hook), one soft impact on the Wait card, soft clicks on ring landings, one bell on the end card
- Restraint rule: no stingers over the read-aloud voice; nothing flashier than the product

## Storyboard (≈60 s)
1. **Hook: the call** (0–5 s): phone-call card "PhilHealth"; Taglish line builds word by word, held to read; clears; "OTP" match-cuts into the Wait card. Audio: ring, then hush.
2. **Caught** (5–11 s): REAL clip of the Wait card arriving + read aloud. Caption "Caught on this laptop." then "Wi‑Fi off." Transition: the card's amber floods to the flat background.
3. **The problem, in three lines** (11–19 s): "The help seniors get: *share your screen*." → "That's how scammers get in." → "Gabay never sees your screen." Each line fully exits before the next (~2.2 s holds).
4. **Wi‑Fi rescue, offline** (19–31 s): REAL clip sped ~2×, zooms onto each ring (Apple logo → System Settings → Wi‑Fi → switch). Caption "Nawalan ng Wi‑Fi? Gabay still works." The switch turning green grows into the next scene.
5. **Range** (31–43 s): REAL clips, ~3 s each on beats — YouTube CC, Facebook friend requests (names blurred), Preview rotate — then a 3-up grid held ~3 s. Caption "Any app. Any website. In Taglish."
6. **Honest** (43–48 s): REAL "Not this one" → next best. Caption "When it isn't sure, it asks."
7. **Numbers** (48–54 s): kinetic beats, one per beat: "29/35 on apps it never saw." → "Cloud: 33–35." → "Close to the cloud. Without the cloud."
8. **End card** (54–60 s): "It points. She clicks. Nothing leaves the laptop." → logo + address-bar CTA.

**Music mood:** calm-modern, quiet build. **Audio summary:** a ringing phone, a hush when Gabay says "Wait", then a warm build through the rescue and montage, resolving on the end-card bell.

## Privacy note
Real recordings may show personal data (Facebook names, menus with recent files). Crop to the active window, blur names/faces, and never show the Mail account dialog or notifications. Synthetic stand-ins only where needed.
