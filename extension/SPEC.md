# ScreenGuide browser extension: handoff spec

**Owner:** teammate · **Timebox:** ~2–3 hours · **Deadline context:** hackathon code freeze is 10:00 AM, Oct 10. Merge early and often.

## What we're building (30-second context)

ScreenGuide is a macOS app that guides non-technical people through tasks one click at a time.
1. The user states a goal ("turn on subtitles").
2. The app gets a list of things the user could click.
3. A **local** AI model (Laya, running on the Mac) picks the right one.
4. We highlight it with a one-line instruction. **The user clicks; we never click for them.**
5. We detect the click and move on to the next step.

For native apps we read controls through macOS accessibility. **Websites need this extension**: it reads the page's interactive elements, draws the highlight inside the page, and reports what the user does. All AI decisions happen in the Mac app; the extension has no AI and makes no network calls except to the local app.

This mirrors how browser-use agents (Claude in Chrome, Playwright MCP) see pages: a compact list of elements with roles, names and stable refs.

## Scope

**In scope:**
- Chrome Manifest V3 extension; it should also load in Edge, Arc, Dia and other Chromium browsers.
- Element snapshot, in-page highlight and instruction card, user-action events.
- A WebSocket link to the Mac app on localhost.
- A mock app script so you can build and test without the Mac app.

**Out of scope:** Safari (needs an Xcode wrapper; later), any AI or model code, clicking or typing on the user's behalf, a cloud backend.

## Repo layout

```
extension/
  manifest.json
  src/service_worker.js   # WebSocket to the app, routes messages to tabs
  src/content.js          # snapshot, highlight, events (runs in every frame)
  src/overlay.css         # injected into a shadow root
  mock/mock_app.py        # fake Mac app for testing (see below)
  README.md               # how to load unpacked + run the mock
```

No build step needed (plain JS). If you want TypeScript, keep the output committed so judges can load it unpacked.

## Architecture

```
Mac app (ScreenGuide) ── ws://127.0.0.1:47823/ext ── service_worker.js ── chrome.tabs.sendMessage ── content.js (active tab)
```

**Service worker:**
- Connects to `ws://127.0.0.1:47823/ext`. Reconnects with backoff (1s, then 2s, 5s, max 10s).
- Sends a `hello` on connect.
- Forwards app→tab messages to the **active tab of the focused window**, and tab→app messages to the socket.
- Keeps itself alive while connected (send a `ping` every 20s).

**Content script** (`all_frames: true`, `run_at: document_idle`): does all DOM work. The top frame coordinates; same-origin iframes are walked directly, and cross-origin frames answer through their own content script instance and merge their snapshot results in (tag elements with `frame` index).

### Manifest permissions (keep minimal; judges may read it)
- `host_permissions: ["<all_urls>"]`: content script on any site (the guide must work anywhere).
- `scripting`, `tabs`, `storage`.
- No `webRequest`, no remote code, no `eval`.

## Message protocol (JSON over WebSocket)

Every message has `type`, and requests have `id` (string) echoed in the response.

### App → extension

| type | fields | meaning |
|---|---|---|
| `snapshot_request` | `id`, `max_elements?` (default 400) | Return interactive elements on the current page |
| `highlight` | `id`, `ref`, `instruction`, `step?`, `hint?`, `style?` (`"ring"` \| `"spotlight"`), `candidates?` (refs[] for "not sure" mode) | Scroll the element into view, draw the highlight and instruction card |
| `clear` | `id` | Remove all overlays |
| `ping` | | Keepalive |

### Extension → app

| type | fields | meaning |
|---|---|---|
| `hello` | `browser`, `version` | Sent on connect |
| `snapshot` | `id`, `url`, `title`, `elements[]`, `ms` | Snapshot response |
| `highlight_ok` / `highlight_error` | `id`, `reason?` (`"ref_not_found"`, `"not_visible"`) | Result of a highlight |
| `user_action` | `kind` (`"click"` \| `"input"` \| `"change"` \| `"submit"` \| `"keydown_escape"`), `ref?` (if the target is a known element), `on_target` (bool: was it the highlighted element?) | The user did something |
| `page_changed` | `url`, `title`, `reason` (`"navigation"` \| `"spa_route"` \| `"dom_mutation"`) | Debounced 300ms; the app will re-snapshot |
| `card_button` | `button` (`"again"` \| `"stuck"` \| `"stop"` \| `"read_aloud"`) | User pressed a button on the instruction card |

### Element shape (in `snapshot.elements[]`)

```json
{
  "ref": "e42",
  "role": "button",
  "name": "Subtitles/closed captions (c)",
  "context": "Video player controls",
  "tag": "button",
  "type": null,
  "enabled": true,
  "visible": true,
  "in_viewport": true,
  "rect": [x, y, w, h],
  "frame": 0,
  "value": null
}
```

- **`ref`:** stable within a page load. Store it on the node as `data-sg-ref`; reuse it if the node already has one.
- **`role`:** explicit ARIA role, otherwise the implicit one: `a[href]`→link, `button`→button, `input[type=checkbox]`→checkbox, `select`→combobox, `textarea`/text inputs→textbox, and so on.
- **`name`:** the accessible name, approximately, in this order:
  1. `aria-labelledby` text
  2. `aria-label`
  3. the associated `<label>`
  4. `alt` / `title`
  5. `placeholder`
  6. trimmed `innerText`

  Collapse whitespace, max 80 chars.
- **`context`:** nearest landmark or heading text (`aria-label` of the closest `nav`/`main`/`form`/`dialog`/`[role=region]`, or the nearest preceding `h1–h3`), max 60 chars. This helps the model tell apart "Search" in the header from "Search" in a form.
- **`rect`:** viewport CSS pixels from `getBoundingClientRect()`.
- **`value`:** **always `null` for password, credit-card (`autocomplete` contains `cc-`), and any `type=hidden` field.** For other fields, the current value is truncated to 40 chars. When in doubt, send null.

**Which elements to collect:**
- `a[href]`, `button`, `input:not([type=hidden])`, `select`, `textarea`, `summary`, `[contenteditable=true]`
- `[role]` in {button, link, tab, menuitem, menuitemcheckbox, menuitemradio, checkbox, radio, switch, combobox, textbox, searchbox, option, slider, treeitem}
- `[onclick]`, and `[tabindex]:not([tabindex="-1"])` that has a name

Walk open shadow roots. Skip `display:none`, `visibility:hidden`, zero-size, `aria-hidden=true` subtrees, and disabled `fieldset` descendants (keep them, but mark `enabled:false`).

**Order:** in-viewport first (top→bottom, left→right), then the rest of the page by distance from the viewport. Cap at `max_elements`. Target under 150ms for a typical page; report `ms`.

## Highlight and instruction card

The visual design is coming from Claude Design (`design/`). Until then, use these placeholders and keep the styling in CSS variables so we can swap tokens in later.

- **Isolation:** render everything inside **one shadow-root host** (`<sg-overlay>`) attached to `document.documentElement`, `position: fixed; inset: 0; z-index: 2147483647; pointer-events: none`. Page CSS must not leak in and ours must not leak out.
- **Scrolling:** before showing, run `el.scrollIntoView({block: "center", behavior: "smooth"})` if it isn't fully in the viewport, then wait for scroll end (or 400ms).
- **Ring style:**
  - a rounded rect 6px larger than the element on each side, 3px solid accent `#2F7DF6`
  - an outer glow, and a gentle 1.6s pulse (scale 1 → 1.04)
  - `prefers-reduced-motion`: no pulse
- **Spotlight style:**
  - a full-viewport dim of `rgba(0,0,0,.45)` with a rounded "hole" around the target (SVG mask or a 4-rect cutout), plus the ring
  - the dim **must not block clicks** on the target (`pointer-events: none` on the dim)
- **Instruction card:**
  - **Placement:** next to the target, never covering it. Try below, then above, right, left; keep 12px from the target and 8px from the viewport edges. Max width 360px.
  - **Text:** body text ≥ 20px, the step label ("Step 2") small above it, and `**word**` in the instruction rendered as bold.
  - **Buttons:** "Show me again", "I'm stuck", "Stop", and a speaker icon. Only the card has `pointer-events: auto`; buttons emit `card_button`.
- **Tracking:** reposition on scroll, resize and layout changes with a `requestAnimationFrame` loop while visible. If the element disappears from the DOM, hide the overlay and send `page_changed` (`dom_mutation`).
- **Not-sure mode** (`candidates` present): ring each candidate, add a numbered badge (1, 2, 3), and anchor the card to the first one.
- **Sensitive fields:** if the highlighted element is a password or `cc-` field, show the card ("Type your password yourself — I'll look away") but **do not** report `input` values. While focus is in such a field, send no `user_action` other than `submit`.

## User-action events
- **Listeners:** capture-phase `click`, `change`, `submit`, and `keydown` (Escape only) on `document`, in every frame.
- **Reporting:** report `ref` if the event target or its closest collected ancestor has `data-sg-ref`, plus `on_target` = whether that ref equals the currently highlighted ref. Don't report coordinates or text typed.
- **Navigation:** full-page navigation is detected by the content script loading again, which sends `page_changed` with `navigation`. SPA routes: patch `history.pushState`/`replaceState` and listen for `popstate` → `spa_route`. Large DOM changes: a `MutationObserver` on `body` with `childList, subtree`, debounced 300ms, only firing if more than 20 nodes were added or removed → `dom_mutation`.

## Security
- **Origin check:** the Mac app's WebSocket server will reject connections whose `Origin` isn't `chrome-extension://<our id>`, since any website can try to open `ws://127.0.0.1`. To give the extension a stable ID across machines, put a fixed `"key"` in `manifest.json`; generate one and commit the **public** key only.
- **No outside connections:** the extension never opens connections to anything except `127.0.0.1:47823`.
- **Messages are data:** treat every incoming message as data. Never inject HTML from messages; render `instruction` with `textContent`, plus our own bold parsing.

## Mock app (so you're not blocked on the Mac app)

`extension/mock/mock_app.py` uses Python 3 with the `websockets` package. It should:
1. Listen on `127.0.0.1:47823/ext`.
2. On `hello`, send `snapshot_request`, then print the elements as a table: `ref | role | name | context | in_viewport`.
3. Let the user type a keyword. The mock picks the first element whose name contains it and sends `highlight` with `instruction: "Click **<name>**"`.
4. Print every `user_action`, `page_changed` and `card_button` as it arrives.
5. Support the commands `snap`, `hl <ref>`, `clear` and `notsure <ref> <ref> <ref>`.

## Acceptance tests (demo-critical first)

1. **YouTube video page:** a snapshot includes the captions button (name contains "Subtitles" or "captions"). `hl` on it scrolls it into view, rings it, and places the card without covering it. Clicking it sends `user_action` with `on_target: true`.
2. **Wikipedia article:** the search box is found (role `searchbox` or `textbox`). Typing sends no values. Submitting sends `submit`, then a `page_changed` `navigation`.
3. **Long page:** highlighting an element far below the fold scrolls to it smoothly, and the ring stays glued to it while you scroll by hand.
4. **SPA navigation** (e.g. GitHub or YouTube clicking between videos): emits `spa_route`, and the overlay clears or updates.
5. **Wrong click:** with a target highlighted, clicking a different element sends `on_target: false`.
6. **Password field** (any login page): no values are ever sent; the card shows the "I'll look away" text.
7. **Not-sure mode:** 3 candidates ringed with numbered badges.
8. **Performance:** a snapshot of a heavy page (YouTube home) is under 300ms and ≤ 400 elements, in-viewport first.
9. **Reconnect:** kill the mock and restart it. The extension reconnects within 10s without a page reload.

## Priority if time runs short
1. Snapshot + protocol + mock
2. Ring highlight + card with scroll-into-view and tracking
3. `user_action` with `on_target`
4. `page_changed`
5. Spotlight style, not-sure mode, iframes and shadow DOM

## Submission disclosure (for README)
"The browser extension reads the page's interactive elements and draws highlights locally. It contains no AI and sends data only to the ScreenGuide app on the same Mac (127.0.0.1). Field values from password and payment fields are never read."
