Redesign **Gabay**, a macOS app, to be radically minimal and calm. This replaces the earlier "Beside" design: same product, far fewer elements on screen. Everything must be buildable in SwiftUI on macOS 26; the web version is drawn by a browser extension in HTML/CSS and must look identical.

## The product in one paragraph
Gabay ("guide" in Filipino) helps people who aren't comfortable with technology do things on their computer: older parents, grandparents, anyone who always calls a relative for help. They say or type what they want ("make this photo smaller so I can email it", "paano palakihin yung text"). Gabay looks at the screen and **shows them where to click**: a ring around the exact button, plus one short sentence beside it, spoken aloud. **They click; Gabay never clicks for them.** It watches the screen change, then shows the next place. It works in any Mac app and on websites. The AI runs entirely on the computer: nothing on screen is ever sent anywhere, it works without internet, and that is how it protects people from "share your screen" scams.

## Design principles (non-negotiable)
1. **One sentence, one ring.** At any moment the user sees at most one ring and one short card. No panels, toolbars, step counters or button rows by default.
2. **Help only when needed.** Secondary actions ("Not this one", "Stop", the speaker) appear on hover, or by themselves after about 8 seconds without progress.
3. **Voice first.** Every instruction is spoken. The card text matches the spoken words exactly. Big mic and big type.
4. **The screen is the progress.** No "Step 2 of 4". Success is a brief green tick on the ring.
5. **Never blame, never red.** Wrong turns: "That's okay. Click **Tools** instead." Warnings use calm amber.
6. **Quiet trust.** A tiny lock with "On this Mac" in the card corner, always present, never loud.
7. **Senior-legible.** Instruction text ≥ 24pt (with Larger and Largest options), WCAG AAA contrast, 44pt+ targets, reduced-motion variants, readable on a projector from the back of a room.
8. **Identical everywhere:** Mac apps and web pages show exactly the same ring and card.

## Screens and states to design
Show each over a realistic 1440×900 macOS desktop. Use Preview with a photo, System Settings, and a Philippine website in Chrome (e.g. a utility "Pay Bills" page). Show light mode, plus dark mode for the guiding states.

1. **Gabay button:** a small, friendly round button floating in a screen corner. Always there, because seniors forget hotkeys. Also show the menu bar icon and the Option+Space hint.
2. **Ask:** tapping opens one rounded field near the button: "What do you need help with?" with a large mic as the primary action and typing as secondary. States:
   - empty
   - listening (live words appearing, a gentle level animation)
   - typed
   - first-run only: 3 example chips. In-app copy is English, with one Taglish chip such as "Paano mag-email ng picture"
3. **Thinking:** the field collapses into a soft pulsing dot near the cursor. Show the dot alone (under 1 s) and with "Looking…" (longer).
4. **Pointing (the core; design most carefully):**
   - The **ring** hugs the target with a warm accent, a subtle glow and a gentle breathing motion.
   - The **card** sits beside the ring (below, then right, then left, then above, never covering the target or an open menu). It holds one sentence with the key word emphasized, e.g. "Click **Tools**." An optional second line in smaller text only when truly needed ("It's at the very top of your screen"). The small lock with "On this Mac" sits in a corner.
   - Show 4 target types: a top menu bar item; an item inside an open menu; a button in a dialog; a link on a web page.
   - Show the **hover / idle state** where "Not this one", "Stop" and a speaker icon fade in.
5. **Typing step:** ring on a text box: "Type **1200** here, then press Enter." No Done button; it moves on when they press Enter.
6. **Confirmed:** the ring turns green with a small tick for half a second, then the next ring appears. No text.
7. **Not sure:** two rings with ① and ② badges, and one card: "It's one of these. Pick either one."
8. **Wrong turn:** the ring stays on the right target: "That's okay. Click **Tools** instead."
9. **Stuck** (after ~20 s idle, or asked): the rest of the screen dims, the ring grows, and the card gets slightly larger, with "Not this one" and "Stop" visible.
10. **Done:** a soft check and one line, e.g. "Done. Your photo is ready to email." It fades after ~4 s. A small "What I did" disclosure expands into a numbered list.
11. **Scam warning:** a calm amber card, not alarming: "Wait. Real banks and government offices never ask you to share your screen or install apps like this." Buttons "I understand" and "Call my family". Shown when the goal or page involves screen sharing, remote-access apps (AnyDesk, TeamViewer) or sharing an OTP.
12. **Private field:** when the next step is a password or one-time-code box: "Type your password here. I won't look."
13. **First run:** one welcome screen ("Gabay shows you where to click. It needs permission to see your screen.") with one button. Then show **Gabay guiding its own permission setup**: the ring on the Accessibility toggle inside System Settings, using the normal pointing UI.
14. **Settings:** one small window with three choices only: text size (Large / Larger / Largest, with a live preview), read aloud (on/off), ring color (2–3 friendly options, no blue, since it clashes with system selection).

## Deliverables
1. High-fidelity mockups of every state above (light; dark for 4–10).
2. **One component sheet** with tokens:
   - colors, light and dark: ring, glow, success, warning, card surface, text
   - type scale at all three text sizes
   - spacing, radii, shadows and materials (macOS 26 Liquid Glass via `.glassEffect()` where it helps legibility)
3. **Ring spec:** stroke widths, padding around the target, glow, breathing animation (duration and easing), and a reduced-motion version.
4. **Card spec:** max width, padding, placement rules, behavior over busy and dark backgrounds.
5. **Motion notes** for: thinking dot → ring, card in and out, confirm tick, not-sure, stuck dim, and done fade.
6. **Copy sheet:** every user-facing string, in plain words (no "menu bar item", "dialog", "AI", "model"). Include Taglish variants for the 5 most common lines.
7. **Web parity:** the same card and ring as they appear inside a web page (drawn by the extension), with notes on keeping them identical.
8. **Projector check:** one frame showing the pointing state at 1920×1080 as seen on a projector.

## Constraints
- Native macOS feel: SF Pro / SF Rounded, SF Symbols, continuous corner radii.
- The overlay is click-through except the card's own buttons; real clicks always reach the app underneath.
- No dark patterns, no gamification, no mascots. Warm, calm, respectful of adults.
