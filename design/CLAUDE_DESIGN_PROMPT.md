Design the complete visual system and every screen for a macOS app built at a 24-hour hackathon, plus the pitch and submission assets. Everything in Part A must be implementable in SwiftUI. Part B is for the demo.

---

# The product

**A patient guide that shows people how to do things on their Mac, one click at a time, with the AI running entirely on their own computer.**

The user says or types a goal ("make this photo smaller so I can email it"). The app reads what's on screen in whatever app is open: the real buttons, menus and fields, through macOS accessibility data plus on-device OCR. A local AI model picks the next control. The app highlights that exact control on screen and shows one short instruction beside it. **The user clicks; the guide never clicks for them.** The app watches the screen change, confirms the step, and shows the next one. If the user goes the wrong way, it calmly redirects them.

- **Works in any app.** There are no pre-built tutorials; it reasons about whatever is on screen.
- **Fully local.** Speech recognition, screen reading and the AI decisions all run on the Mac. It works with Wi-Fi off, and nothing on screen (bank pages, emails, medical portals) is ever uploaded.
- **Not an agent.** It teaches and points; the person stays in control and learns.

**Hackathon context:** the theme is "Local AI, an AI product that stays genuinely useful when the cloud disappears." The live demo runs on stage with Wi-Fi visibly turned off. Judges weigh: real problem (25%), how fundamental the local AI is (25%), works reliably live (20%), innovation (15%), UX and demo quality (15%).

## Who it's for
- **Primary:** older parents and non-technical adults (60+). They feel anxious with computers, can't describe what's on screen when calling for help, fear "breaking something", and hate being talked down to.
- **Secondary:** the adult child who's the family's "24/7 tech support". They install it and set it up for the parent.

**Voice and tone:** calm, warm, encouraging, plain words, never patronizing, never blaming. Use short sentences and one instruction at a time. Say "Click **Tools** at the top of your screen", not "Navigate to the Tools menu". No jargon (no "menu bar item", "dialog", "AI model" in user-facing copy unless explained).

## Design principles
1. **One thing at a time.** Only the current step is prominent.
2. **Point, don't cover.** The overlay must never hide the control it points at, or the thing the user needs to read.
3. **Legible over anything:** white documents, dark photos, busy web pages, light and dark mode.
4. **Calm motion.** Gentle pulses, no flashing; every animation has a reduced-motion version.
5. **Trust is visible.** Make "this runs on your Mac, nothing leaves it" felt, not buried.
6. **Big and clear.** Instruction text at least 20pt; minimum hit target 44×44pt; WCAG AA contrast at minimum, AAA where possible.
7. **Native feel.** SF Pro / SF Rounded, macOS materials and vibrancy, continuous-corner rounded rectangles, SF Symbols for icons.

---

# Part A: The app

Render every screen over a realistic **1440×900 macOS desktop**. The demo scenario is the **Preview app with a vacation photo open**; use it throughout. Also show at least 3 states over other apps (System Settings, Safari with a busy web page, Finder) to prove it works anywhere, and dark-mode versions of the core screens.

## 1. First run and setup
1. **Welcome**: what this is in one sentence, a friendly illustration, "Get started".
2. **How it works**: 3 simple panels: you ask → it points → you click.
3. **Privacy promise**: "Everything happens on this Mac." What it sees, what it never does (never uploads, never clicks for you, never types passwords). Plain words, visual.
4. **Permissions walkthrough**, one screen each, for Accessibility, Screen Recording and Microphone. Each explains why in plain words, shows a mini illustration of the macOS System Settings toggle they'll see, has an "Open Settings" button, and **auto-detects** when the permission is granted, then celebrates and moves on. Include the "waiting for you to turn it on" state and a "permission still off" help state. These system prompts frighten older users, so be very gentle.
5. **Download the brain (local model)**: one-time download of the on-device AI (~3–9 GB). Show size, a progress bar with time remaining, "Works offline once this finishes", plus paused, failed/retry and complete states.
6. **Pick your shortcut and voice**: hotkey choice (show the keys visually), read-aloud on/off with a voice preview, text size slider with live preview.
7. **Try it**: a guided practice task on a safe sample, ending with a success moment.
8. **Family setup (optional)**: a screen for the adult child setting it up. Explains how to start it, plus a printable "how to ask for help" cheat card with the hotkey.

## 2. Menu bar presence
- The menu bar icon in all its states: idle, listening, thinking, guiding, needs permission, model missing.
- The dropdown: "Ask for help…" with the shortcut, recent goals, the local status line ("Running on this Mac · Offline ready"), Settings, Pause, Quit.

## 3. Asking for help
- **Ask bar**: a floating, Spotlight-like but friendlier input, centered or near the cursor. Big mic button, text field, and 3 example goal chips ("Make a photo smaller", "Connect to Wi-Fi", "Make text bigger").
- **Listening**: a live waveform, the live transcript appearing as they speak, "Done" and "Cancel". Include silence ("I didn't catch that — try again?") and mic-permission-off states.
- **Confirm understanding** (optional): "You want to make this photo smaller. Right?" with Yes / Not quite.
- **Clarifying question**: when the goal is ambiguous, show 2–3 big tappable choices ("Smaller on screen" vs "Smaller file to email").

## 4. Guiding (the core: design this most carefully)
- **Thinking**: the local model takes 2–5 seconds per step. Make waiting feel calm and alive, not frozen. Optional plain-language status ("Looking at your screen…", "Finding the right button…").
- **Pointing at the next step.** Design and compare **3 highlight styles**:
  - (a) a spotlight that dims everything except the target
  - (b) a glowing, pulsing ring around the target with no dimming
  - (c) a large animated arrow or hand plus a ring

  The **instruction card** sits next to the target and smartly repositions (above, below, left, right) to avoid covering it. It holds:
  - the step number ("Step 2"; never a fake total)
  - one instruction with the key word in bold
  - an optional secondary hint ("It's next to Edit")
  - small actions: 🔊 Read aloud, "Show me again", "I'm stuck", "Stop"
- **Target types**, each needing its own treatment:
  - a menu-bar item (tiny target at the top edge)
  - an item inside an open menu
  - a toolbar icon with no text label
  - a text field where they must **type** something ("Type **50** in the Width box"), showing the value to type
  - a dropdown/popup choice
  - a checkbox
  - a keyboard step ("Press **Esc**" or "Press **⌘S**"), with visual key caps since there's nothing on screen to point at
  - a step that needs **scrolling** (the target is below the visible area: arrow toward the edge, "Scroll down a little")
  - the target is **in another window or app**, or hidden behind something
  - the target is on a **second display**
- **Step confirmed**: a quick, satisfying tick at the target, then a smooth transition to the next step.
- **Wrong turn**: a friendly correction when the user clicked something else. "That opened the **Edit** menu. No problem — press **Esc**, then click **Tools**." No red, no error icons, no blame.
- **Not sure (low confidence)**: highlight 2–3 candidates at once with numbered badges. "I think it's one of these. Let's look in **Tools** first."
- **"I'm stuck" flow**: options are "Show me again", "Explain it another way", "Start over", "I'll try something else".
- **Paused**: the user moved away or switched apps. A small "Paused — continue when you're ready" pill.
- **Done**: a warm but brief success moment. "Your smaller photo is saved on your Desktop." Actions: "Do something else", "Show me where it is", "Close".
- **Recap card**: after success, a short list of the steps they just did, with "Save these steps" so they can repeat it next time with less help. This is the "learning" angle.
- **Couldn't do it**: graceful failure with no dead end. "I couldn't find a way to do that here." Suggest rephrasing or a related app.
- **Blocked for safety**: if the next step involves a password field, payment or a security prompt, say "This step needs your password — I'll look away. Type it yourself, then press Continue." Show the guide visibly hiding/blurring while they type.

## 5. Trust and local indicators
- **Persistent local badge** (small, near the instruction card or menu bar): "On this Mac · Offline". Variants: online-but-local and fully offline (Wi-Fi off). It must feel reassuring, not technical.
- **"Behind the scenes" panel (for judges and curious users)**: a toggleable side panel showing, in real time:
  - what the guide "sees": a list of detected on-screen controls
  - the candidates it considered, with confidence bars
  - the chosen control
  - the local model name
  - time per step (e.g. "1.8s on this Mac")
  - network status: "0 bytes sent"

  It's the visual proof of local AI on stage, so make it look impressive and readable on a projector while staying clean.

## 6. Settings (one simple window, tabs or sections)
- **General**: hotkey, launch at login, language
- **Guidance**: highlight style (a b c), dim intensity, instruction text size, guide speed / extra patience
- **Voice**: read aloud, voice choice, speaking rate, voice input on/off
- **Privacy**: what stays local, clear history, "never guide in these apps" list
- **AI model**: installed model, size, status, re-download, "Check it works offline" test button
- **Permissions**: status of each with a fix button
- **About**

## 7. Errors and edge states
Design each:
- an accessibility permission revoked mid-task
- a model not downloaded or corrupted
- a model running slowly (show "Taking a little longer…" after 6s)
- an app with no readable controls ("This app is hard for me to read — I'll do my best")
- a full-screen video or game
- the screen locked
- low battery

## 8. Design system deliverable
A component sheet with:
- color tokens for light and dark mode (accent, highlight ring, dim overlay opacity, success, gentle-warning, surfaces, text)
- the type scale
- spacing scale
- corner radii
- shadows / materials
- every component in all its states: instruction card, highlight styles, ask bar, buttons (primary, secondary, quiet), chips, key caps, badges, progress, confidence bars, toasts
- the iconography (SF Symbols names)
- **motion specs**: durations, easing and reduced-motion alternatives for highlight appear/pulse, card reposition, step transitions, thinking, success

---

# Part B: Brand, pitch and submission assets

1. **Name**: propose 5 friendly names that work for a 70-year-old (easy to say, not techy), each with a one-line rationale. Pick a favorite and apply it everywhere.
2. **App icon**: a macOS-style icon (1024px), plus a monochrome menu bar template icon (16/18pt).
3. **Pitch deck**, 6 slides max. The pitch is 5 minutes and mostly a live demo, so slides only frame it:
   - title
   - the problem ("Mom, what do you see on your screen?")
   - live demo cue slide
   - how it works locally (architecture)
   - why local matters (privacy, offline, no per-use cost)
   - closing

   Projector-friendly, big type, minimal words.
4. **Architecture diagram**: a clean visual for the README and pitch. The pipeline: Voice → local speech recognition → goal; screen → accessibility tree + on-device OCR → candidate controls; candidates + goal → **local AI model** (scores the next step) → highlight + instruction overlay → user clicks → verify. Mark clearly that **everything runs on the Mac** and the only internet use is the one-time model download.
5. **1-minute demo video storyboard**: 8–10 frames with captions and on-screen text. Arc:
   - hook: an anxious parent
   - Wi-Fi turned off
   - asks by voice
   - guided steps
   - a wrong click, gently corrected
   - success
   - the "0 bytes sent" panel
   - name + tagline

   Include title-card and lower-third designs.
6. **Social post card**: a 1200×675 image for the required X/LinkedIn post, with name, tagline and a key screenshot.
7. **GitHub README header banner**: 1280×400.
8. **Tagline options**: 5 of them, under 8 words each.

---

# Output format
- Organize by the sections above, with clear labels for every screen and state.
- Use realistic copy everywhere (no lorem ipsum), written in the product's voice.
- Annotate key measurements (card max width, text sizes, ring thickness, offsets from target, dim opacity) so engineers can build it in SwiftUI directly.
- Prioritize: if you must go in order, do **4 Guiding → 8 Design system → 3 Asking → 5 Trust → 1 Setup → B assets → the rest**.
