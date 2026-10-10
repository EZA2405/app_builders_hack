# Gabay browser extension

The guide points; you click. Plain JavaScript, Manifest V3, no build step. Chrome 116+ is required for WebSocket service-worker keepalive. Chromium browsers such as Edge, Arc and Dia can load it unpacked; Safari is outside this build.

## Use with the Gabay app

1. Follow the [app setup instructions](../README.md#quick-start), including the local Laya checkpoint. From the repo root, build with `app/scripts/build_app.sh`, then start Gabay with `./run.sh`.
2. In Chrome, open `chrome://extensions`, enable **Developer mode**, choose **Load unpacked**, and select this `extension/` directory (the directory containing `manifest.json`). Chromium browsers such as Dia have the same extension settings.
3. Reload any website tab that was open before installation. Keep Gabay running and the browser in front, then press **Option + Space** or click Gabay's round button to ask for help.
4. Click the highlighted control yourself. The extension reads the page and draws highlights; Gabay and its local model choose each step.

The development mock is not required for this flow. Stop any mock before launching Gabay, since both use port 47823. The toolbar entry retains its development name **ScreenGuide**.

## Development mock

Use this stand-in to inspect snapshots or test the extension without the Mac app:

1. In Chrome, open `chrome://extensions`, enable **Developer mode**, choose **Load unpacked**, and select this `extension/` directory (the directory containing `manifest.json`).
2. Run the mock from the repository root:

   ```sh
   python3 -m venv extension/.venv
   extension/.venv/bin/pip install -r extension/mock/requirements.txt
   extension/.venv/bin/python extension/mock/mock_app.py
   ```

3. Open a normal website tab and focus its browser window. If the tab was open before installation, reload it. The mock prints a table when the extension connects; type `snap` after opening another page.
4. The mock and Mac app both listen on `ws://127.0.0.1:47823/ext`. Run only one at a time. Stop the mock with Ctrl+C before using the real app. The mock validates the exact extension origin using the committed **public** manifest key. No private key is included. Its startup line shows the ID needed by the Mac app's origin allowlist.

Stable extension ID: `iokhdpnepbjnngdafdfafcjlpdbnolio`. The Mac app should allow the WebSocket origin `chrome-extension://iokhdpnepbjnngdafdfafcjlpdbnolio`.

## Try it as a standalone guide (dev orderer)

While the Mac app is unfinished, a hosted model can stand in for the local one and pick each step:

```sh
extension/.venv/bin/python extension/mock/mock_app.py --orderer jev      # hosted TypeSafe Jev (key from JEV_API_KEY, ml/.env or ~/.config/jev/jev.env)
extension/.venv/bin/python extension/mock/mock_app.py --orderer laya     # local laya-serve on 127.0.0.1:8766, model "guide" (fine-tuned weights)
extension/.venv/bin/python extension/mock/mock_app.py --orderer claude   # Claude Haiku via Claude Code; or claude:sonnet, or codex
```

With `--orderer jev` the helper also serves a relay on 127.0.0.1:8766 so the Mac app (Gabay, whose planner expects laya-serve there) can guide Mac apps through Jev; menu entries go through `is_personal` and name/email/number redaction first, and answers are mapped back. Gabay hands goals asked while a Chromium browser is in front to this helper (`GET /goal?text=…` with header `X-Gabay: 1`; requests carrying an `Origin` header are refused, so web pages cannot start guidance) and guides natively when no extension is connected.

`jev` and `laya` use the Mac app's planner contract (`app/Sources/ScreenGuide/Planner.swift`, `ml/web_data.py`): elements as `role "name" · context`, the state `…web browser, on the website "<title>". Their goal: "…" Already done: clicked …`, a 16-wide tournament keeping 3, "not sure" below 0.3 confidence, and fixed wording per role. A goal ends when the model re-picks something already clicked, after an OK/Save/Send-style button, or after 8 steps. Measured Oct 9 on live Wikipedia/YouTube snapshots: 0.8–1.6 s per step with Jev.

Click the ScreenGuide toolbar button (pin it from the puzzle-piece menu), type a goal such as "turn on subtitles", and press **Guide me**. A "Working out the next step…" pill shows while it decides; the ring and card follow in about 1–3s per step with Haiku (one warmed-up Claude session per goal), ~10s with Codex. A text-box step finishes when you press Enter, not when you click into the box. When the goal is reached, an "All done" pill appears. Click the highlighted control yourself; the next step follows. **I'm stuck** asks again with a spotlight, the speaker button reads the step aloud with macOS `say`, and **Stop** ends the goal. You can also type `goal <text>` in the terminal.

**This sends data off the Mac**, so it is for testing only and never the product path: element role, name and heading context plus the page title and host/path go to Anthropic or OpenAI after `ml/make_fixtures.py` sanitizing (`is_personal`, `redact_names`) plus email and long-number redaction. Field values, positions and URL query strings are never sent. It needs a logged-in `claude` or `codex` CLI. Advancing waits for a click on the target, so steps that only need typing move on when the user clicks the next control or submits.

## Demo: YouTube captions

Open a video with captions available, such as [3Blue1Brown’s neural network introduction](https://www.youtube.com/watch?v=aircAruvnKk). Start playback, leave captions off, and move your mouse over the video if player controls have faded out.

```text
snap
captions
```

The keyword chooses the first snapshot element whose name contains it. Alternatively type `hl e42`, replacing `e42` with the captions button's ref from the table. The mock sends the instruction; a blue ring and a card appear. **Click the actual captions button yourself.** The mock should print:

```json
{"type":"user_action","kind":"click","ref":"e42","on_target":true}
```

A different click reports `on_target:false`. Card buttons emit `card_button`; speech and next-step decisions belong to the Mac app. Password/payment focus suppresses actions except submit. Reload or navigate after testing to clear stale page refs, then use `snap` again.

Ring and `style:"spotlight"` highlights are supported. `notsure` numbers each candidate and accepts target clicks on any candidate. Snapshots walk open shadow roots and same-origin frame documents; the top frame merges cross-origin frame snapshots and converts their rectangles to the top viewport. Refs are opaque strings (including frame-prefixed refs); pass them back unchanged. Only the first candidate gets an instruction card.

Mock commands: `snap`, `hl <ref>`, `clear`, `notsure <ref> <ref> <ref>`, or a name keyword. The mock prints highlight acknowledgments, page changes, user actions and card-button events. The service worker retries at 1s, 2s, 5s, then 10s, and sends a ping every 20s.

## Reproduce checks

Mock protocol and security check:

```sh
extension/.venv/bin/python -m unittest discover -s extension/tests
```

Browser checks use Playwright as a **test tool**, not an extension dependency. Install it outside the repository:

```sh
npm install --prefix /tmp/screenguide-browser-test playwright
/tmp/screenguide-browser-test/node_modules/.bin/playwright install chromium
NODE_PATH=/tmp/screenguide-browser-test/node_modules \
TEST_PYTHON="$PWD/extension/.venv/bin/python" \
node extension/tests/browser.cjs
# Add --live for actual Wikipedia and YouTube checks (requires internet for those pages).
```

Route regression (can run while a separate demo owns the mock's port):

```sh
NODE_PATH=/tmp/screenguide-browser-test/node_modules node extension/tests/routes.cjs
# Add --live to exercise a real YouTube video change with stubbed local transport.
```

The route check covers sites that bypass/replace history hooks and pages with continuous DOM changes. The live route check runs the same content code with a stubbed local transport; it does not open another WebSocket or interrupt the demo.

The browser check loads the unpacked extension and talks to the real mock. It checks snapshots, ref stability, caps, sensitive-value suppression, ring/card placement, scrolling and resize, safe bold text, click correctness, navigation, DOM changes, spotlight, numbered candidates, open shadow DOM, same-origin/cross-origin/nested frames, a 2,000-button stress page and reconnection after an outage longer than the service-worker idle timeout. `CHROMIUM=/path/to/Chrome-for-Testing` can select an existing test browser. Keep the real app and any other mock stopped during checks.

Chrome's own pages, the Chrome Web Store and other protected pages cannot run content scripts; their snapshots are empty. Site permission must be enabled. Snapshot values for ordinary input/select/textarea fields are limited to 40 characters; **user-action events never contain typed text or coordinates**. Sensitive fields are identified by input type, `autocomplete` and common password/payment names; unknown custom payment widgets should declare `autocomplete="cc-*"`. Snapshots should be requested only for the user's current task.

Closed shadow roots and rotated/skewed iframe geometry are unsupported. An oversized target can leave only a scrollable card; if no free area exists, the card stays hidden to avoid covering the target. Frame page permissions still apply. Site layouts and video controls can change, so rehearse the chosen subtitled video before judging.

Measured in headless Chromium on Oct 9, 2026: the live YouTube captions highlight → click → `on_target:true` flow passed, with captions actually enabled after the click; Wikipedia snapshots returned 400 elements in about 115–127ms; the YouTube watch page took about 11ms. A 2,000-button fixture took 33–65ms, capped at 400. The anonymous YouTube homepage returned only 12 elements in this profile, so that result does **not** verify a fully populated heavy homepage. Restarting the mock after a 35s outage reconnected in about 3.1s without reloading. The browser check prints fresh timings; these are observations, not guarantees. The real Mac app bridge has not been exercised by these mock tests. The final YouTube SPA fix passed the separate route regression, including a real related-video click with stubbed transport; the complete mock-backed suite has not been rerun after that fix while the visible demo owns the port.

## Submission disclosure

The browser extension reads the page's interactive elements and draws highlights locally. It contains no AI and sends data only to the ScreenGuide app on the same Mac (127.0.0.1). Field values from password and payment fields are never read.

AI development tools: OpenAI Codex, Claude Code. Overlay styling follows direction A ("Liquid Glass") of the Beside design handoff in `design/handoff/`, made with Claude Design. Runtime dependency: none. Mock dependency: Python `websockets`. Browser-test dependency: Playwright. The WebSocket message names and fields match [SPEC.md](SPEC.md).
