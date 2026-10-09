# ScreenGuide Chrome extension

The guide points; you click. Plain JavaScript, Manifest V3, no build step. Chrome 116+ is required for WebSocket service-worker keepalive. Chromium browsers such as Edge, Arc and Dia can load it unpacked; Safari is outside this build.

## Load and run

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

AI development tool: OpenAI Codex. Runtime dependency: none. Mock dependency: Python `websockets`. Browser-test dependency: Playwright. The WebSocket message names and fields match [SPEC.md](SPEC.md).
