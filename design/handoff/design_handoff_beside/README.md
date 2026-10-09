# Handoff: Beside — macOS on-device guide (SwiftUI)

## Overview
Beside is a macOS app that teaches people (primarily 60+, non-technical) how to do things on their Mac, one click at a time. The user states a goal by voice or text; the app reads the screen (Accessibility API + Vision OCR), a **local** model picks the next control, and an overlay highlights that control with one short instruction. **The user always clicks — the app never clicks for them.** It confirms each step by watching the screen change, redirects calmly on wrong turns, and works fully offline.

Two visual directions are included for comparison:
- **A · Liquid Glass** — instruction card sits *beside* the target; warm "Beacon" orange ring. Light-first.
- **B · Island** (inspired by Vorssaint, original interpretation) — instructions always in a black island hanging from the top-center; target marked with blue corner brackets + tag. Dark-first.

Pick one before building; tokens below are listed per direction.

## About the Design Files
`Beside-standalone.html` (open in any browser, works offline — pan/scroll the canvas) and `source/Beside.dc.html` are **design references built in HTML**, not production code. Recreate them natively in **SwiftUI/AppKit for macOS 26** (Liquid Glass APIs: `.glassEffect()`, `GlassEffectContainer`, `.buttonStyle(.glass/.glassProminent)`). Faked desktop elements (wallpaper, Preview window, menu bar, Image Dimensions sheet) are context only — they are other apps, not part of Beside.

## Fidelity
**High-fidelity.** Final colors, type, spacing, radii and copy. Copy is final and deliberately plain — do not rewrite into jargon ("menu bar item", "dialog", "AI model" are banned in user-facing text).

## Architecture (implied by the design)
- **Overlay window**: borderless `NSPanel`, `.nonactivatingPanel`, level `.statusBar` (or above), `ignoresMouseEvents = true` for the ring/brackets layer; a separate small panel for the card/island that *does* accept clicks (its buttons only). Clicks must always pass through to the real app.
- **Target geometry**: from `AXUIElement` `kAXPositionAttribute`/`kAXSizeAttribute` (fallback: Vision OCR text boxes). Convert to screen coords (flip Y).
- **Menu bar extra**: `MenuBarExtra(style: .window)` hosts the Ask panel (A) — or the island in Full size (B).
- **Speech**: on-device (SpeechAnalyzer/SFSpeechRecognizer with `requiresOnDeviceRecognition`). TTS: `AVSpeechSynthesizer`.
- **No network entitlement.**

## Screens / Views
Artboards are 1200×750 (a scaled desktop). IDs match the badges in the HTML.

### A · Liquid Glass
**sys — Visual system sheet.** Tokens, ring states, placement rules, voice do/don't.

**Setup (helper-facing window, 780×580, radius 28, glass `rgba(250,250,252,.86)` + blur 40, padding 56/64)**
- **1a Welcome** — App icon 84pt, "Welcome to Beside" 36 Bold, subtitle 19. Three promise tiles (3-col grid, gap 14, radius 20, white 70%): "It points. You click." / "Works in any app." / "Stays on this Mac." Radio cards "I'm setting it up for someone" (selected: 2.5pt Beacon ring) / "It's for me". Primary "Continue" ink capsule 48pt.
- **1b Permissions** — "STEP 2 OF 4" label; title "Let Beside see the screen and hear you"; three white rows (radius 20, padding 18/20): title 17 Semibold, plain explanation 15, mono 12 system path (`System Settings › Privacy › Accessibility` etc.). Status: green "✓ Allowed" or ink "Open Settings" capsule; pending row gets Beacon ring. Continue disabled (25% ink) until required ones granted.
- **1c Ready offline** — three rows (Listening / Reading the screen / Deciding the next step — 3.1 GB · Ready). Green success panel "Offline test passed — With Wi-Fi off, Beside found the Tools menu in Preview." Menu bar shows "Wi-Fi Off".
- **1d Comfort** — name field, word size segmented M/L/XL, live preview card, toggles "Read each step out loud", "Speak a little slower", stuck-contact field "Sam (son) (555) 014-2290". Primary "Finish and hand over".

**Asking (panel 440 wide, radius 32, padding 28, anchored under menu bar extra, right 70 / top 36)**
- **2a Ask** — "Hi Rosa." 17 + "What would you like to do?" 28 Bold; 58pt field + 58pt circular Beacon mic; "YOU COULD SAY" 3 suggestion rows; footer green dot "Private. Works without the internet."
- **2b Listening** — 96pt mic with 2 halo rings (Beacon 22% / 10%), level bars, live transcript 26 Semibold (unconfirmed words in #8E8E93), "Take your time. I'm listening.", buttons "Start over" / "I'm done talking".
- **2c Looking** — "GOT IT" + restated goal; checklist (✓ Preview is open, ✓ Found your photo, spinner Working out the first step…); "Nothing on your screen leaves this Mac."

**Guiding (hero task: shrink a photo in Preview, 4 steps)**
Common parts:
- *Ring* on target (see tokens). *Card*: width 340–380, radius 28, padding 20/22, gap 8: label "STEP n OF 4" 13 Bold +6% #48484D → instruction 26/32 Semibold (key word in Beacon Ink #B85A00) → hint 17/24 #48484D → buttons "Say it again" / "I'm stuck" (40pt capsules, 6% ink fill). *Leader*: 2pt Beacon line from ring edge to card when there's room.
- *Progress capsule* bottom-left (24/24): 56pt glass capsule — mark, task name 16 Semibold, step dots (done green 8pt, current Beacon 20×8, todo 18% ink), "● On this Mac", "Stop".
- **3a Step 1** — "Click **Tools** at the top of your screen." / "It's between Go and Window." Card below target.
- **3b Step 2** — Tools list open; ring on "Adjust Size…"; card right of the list (never over it).
- **3c Step 3** — Image Dimensions sheet; ring on Width field; card right of the sheet. "Click in the **Width** box and type **1200**." / "Height will change by itself. That keeps the photo's shape."
- **3d Confirmed** — ring turns green + ✓ badge; label "STEP 3 OF 4 · DONE" in #1F7A41; "That's right. Width is 1200."; 4pt auto-advance bar; no buttons. Auto-advance ≈1.5 s.
- **3i Step 4** — ring on OK; "Click **OK**." / "It's the blue button at the bottom right of this box." label "STEP 4 OF 4 · LAST ONE".
- **3e Small detour** — user opened Edit; ring stays on Tools; label "SMALL DETOUR" #8A4300; "That opened Edit. Nothing has changed." / "Click Tools instead…". Never red, never "wrong".
- **3f I'm stuck** — spotlight (dim 50% everything except target), 220pt magnifier lens showing enlarged "Go [Tools] Win", larger card (420, white 90%): "Let's find it together." + options "Read it out loud", "Try a different way", "Call Sam (555) 014-2290", footnote "Or stop here. Nothing has been changed."
- **3g Not sure** (low confidence) — two candidates: dashed 3pt Beacon outline offset 4 + numbered badges 1/2; "I think it's one of these two." / "Say "one" or "two", or just click the one you think."; button "Describe them to me".
- **3h All done** — centered card 500, radius 36: 64pt green check, "All done, Rosa." 32 Bold, result "4.2 MB to 380 KB…", "WHAT YOU DID" numbered recap, buttons "Close" / "Now email it".

**Legibility**
- **4a Dark Mode** — card `rgba(36,36,40,.74)`, text #F5F5F7, key word #FFB066, hint #D1D1D6; ring unchanged (white inner ring keeps it visible).
- **4b Busy page** — card tint raised to 0.9 when OCR detects dense text/high contrast behind the card.

**Settings (window 900×600, radius 26, glass sidebar 230 inset 10, radius 18; items 36pt; selected = white pill)**
- **5a Privacy** — "Everything happens on this Mac." table: Internet use — None. / Pictures of the screen — Looked at, then deleted right away. / What you say — Never recorded. Toggle "Keep a list of finished tasks" + "Clear list". Mono tech footnote.
- **5b Comfort** — Word size M/L/XL + preview; Highlight color Orange (default) / Pink #E0457B / Yellow #E8B500 (no blue — conflicts with system selection); toggles Dim when stuck (on), Show progress at the bottom (on), Gentler movement (off → fades only).
- **5c Voice** — Read each step out loud; Listen when I press Fn twice (voice commands "next", "again", "I'm stuck"); voice radio list Ava/Evan/Zoe with "Play sample"; speed slider Slower–Normal–Faster (default ~30%).
- **5d Helper** — Name, Phone, "Show Sam's number when Rosa is stuck"; "Lock settings with this Mac's password"; "WHAT ROSA DID RECENTLY" (✓ done, Beacon ring = stopped partway); "Export settings for another Mac…".

### B · Island
- **Bsys** system sheet. **Ba** Setup permissions (dark window 860×600 with numbered step rail, mono chips ACCESSIBILITY/REQUIRED etc., primary "Allow" Signal blue). **Bb** Ask (island Full 640 wide). **Bc** Step 1 (island 520 wide, brackets + tag "1 · Tools"). **Bd** Step 3 (island Compact so it clears the sheet; number badge "3" instead of full tag). **Be** Detour (amber "SMALL DETOUR" chip). **Bf** Stuck (spotlight + enlarged top-bar strip inside island + options). **Bg** Done (720 island, 4 recap cards). **Bh** Settings · Comfort (top segmented tabs Comfort/Voice/Privacy/Helper; mono section headers; live island preview).
- Island: always `#0B0B14`, attached to top edge, `UnevenRoundedRectangle` bottom radius 30 (26 compact, 34–36 full), top padding ~40 to clear the menu bar. Sizes: Resting pill (step counter + bars) / Compact (~110 tall, one line) / Full.
- Rule: if the island overlaps the target → shrink to Compact; still overlapping → slide to the opposite top corner.

## Interactions & Behavior
- **Step loop**: plan step → find AX element → draw ring/brackets + card/island → speak instruction (if enabled) → observe AX notifications / screen diff → on expected change: Confirmed state 0.8 s → next step. On unexpected change: Detour state. No progress for ~20 s or "I'm stuck": Stuck state.
- **Low confidence** (model below threshold or ≥2 matching elements): Not-sure state with numbered candidates; accept voice "one/two" or a click on either.
- **Motion (A)**: ring "breathes" scale 1.0→1.08, 1.6 s ease-in-out, 3 cycles then holds. Card arrives with 8pt slide toward target, `spring(response: 0.35, dampingFraction: 0.85)`. Reduce Motion / "Gentler movement": opacity fades only.
- **Card placement (A)**: below → right → left → above target; 12pt gap; keep-out = target frame + 24pt, any open menu, and the text the step refers to.
- **Stop** always visible; stopping never undoes anything and says "Nothing has been changed" when true.
- **Keyboard/voice**: Fn-Fn to talk; voice commands next / again / I'm stuck / stop.

## State Management
`appState`: `idle | listening | understanding | guiding(step) | confirming | detour | stuck | unsure(candidates) | done | error`
`task`: goal text, steps[] (label, keyWord, axRef, frame, status), currentIndex
`settings`: userName, wordScale (1.0/1.2/1.4), highlightColor, readAloud, slowSpeech, voiceId, speechRate, listenShortcut, dimWhenStuck, showProgress, reduceMotion, helperName, helperPhone, showHelperWhenStuck, lockSettings, keepHistory
`history`: [{goal, date, completed, stoppedAtStep}]
No network calls anywhere.

## Design Tokens

### A · Liquid Glass
- Beacon `#F08A24` (ring, mark, mic) · Beacon Ink `#B85A00` (key word on light) · Beacon Ink Dark `#FFB066` · Detour label `#8A4300`
- Done `#2FA35A` (text on light `#1F7A41`) · Ink `#1C1C1E` · Ink Soft `#48484D` · Tertiary `#6E6E73`
- Card glass light: `rgba(255,255,255,.74)`, blur 30 + saturate 1.8, 1px `rgba(255,255,255,.85)` border, inset top highlight, shadow `0 18 50 rgba(18,22,40,.28)` + `0 2 8 rgba(18,22,40,.14)`. Busy-background tint .90. Dark: `rgba(36,36,40,.74)`, border `rgba(255,255,255,.16)`.
  SwiftUI: `.glassEffect(.regular.tint(.white.opacity(0.55)), in: .rect(cornerRadius: 28))`
- **Ring**: shadows `0 0 0 2 #FFF`, `0 0 0 5 #F08A24`, `0 0 0 6 rgba(0,0,0,.25)`, glow `0 0 22 6 rgba(240,138,36,.5)`; hugs AX frame + 4pt, radius 6–8. Confirmed = same in `#2FA35A` + 22pt ✓ badge top-right. Candidate = 3pt dashed outline offset 4 + 22pt numbered badge. Spotlight = `0 0 0 9999 rgba(0,0,0,.45–.5)`.
- Type (SF Pro): Instruction 26/32 Semibold −1% · Title 30–36 Bold · Hint 17/24 · Button 16 Semibold · Label 13 Bold +6% uppercase. Scale ×1.0/1.2/1.4 with Word size. Floor 15pt.
- Radii: card 28 · panel 32 · done card 36 · window 26–28 · row 18–20 · capsule 999 · control 6–8.
- Buttons: secondary 40pt capsule `rgba(0,0,0,.06)`; primary 48pt ink `#1C1C1E` / white text (`.glassProminent`).

### B · Island
- Island `#0B0B14` · Raised `#171724` · Hairline `rgba(255,255,255,.07–.09)` · Text `#F4F4F8` · Text Soft `#B4B4C4`
- Signal `#4C8DFF` (brackets, tag, primary) · Signal Text `#8DB6FF` · Done `#3CCB7F` · Detour `#FFB547` (chip only, dark text)
- Brackets: 4 L-corners, 10–12pt arms, 3pt stroke, 7pt outside the frame, corner radius 4. Tag: 30pt capsule Signal fill, `#0B0B14` 15 ExtraBold text, 2pt `#0B0B14` outline, 10pt below target. Badge (tight spaces): 24pt circle.
- Type: SF Pro Rounded (`.fontDesign(.rounded)`) — Instruction 28/34 Semibold, Title 32 Bold, Hint 18/25; SF Mono 13 Semibold +4% for labels/counters only.
- Island buttons: 44pt capsules `rgba(255,255,255,.10)` + inset top highlight (`.glassEffect(.regular.interactive())` on black).

## Assets
No external images. App icons are simple shapes (A: orange gradient squircle with white ring; B: black tile with four blue corners) — produce final icons in Icon Composer. Photo/web content in mocks are striped placeholders. Use SF Symbols in the real app (mic.fill, speaker.wave.2, checkmark, etc.) where the mocks use simple shapes.

## Files
- `Beside-standalone.html` — single offline file; open in a browser to view every screen (A on the left, B on the right).
- `source/Beside.dc.html` + `source/support.js` — editable source of the same design.
