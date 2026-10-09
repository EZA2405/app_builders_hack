// NODE_PATH=<temporary playwright install>/node_modules TEST_PYTHON=<mock venv>/bin/python node extension/tests/browser.cjs [--live]
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { mkdtempSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const path = require('node:path');
const { chromium } = require('playwright');
const extension = path.resolve(__dirname, '..');
const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function waitFor(check, timeout = 10000) {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    if (check()) return;
    await pause(50);
  }
  throw Error('Timed out waiting for mock output');
}

(async () => {
  let output = '';
  const mock = spawn(process.env.TEST_PYTHON || 'python3', [path.join(extension, 'mock/mock_app.py')]);
  mock.stdout.on('data', (data) => { output += data; });
  mock.stderr.on('data', (data) => process.stderr.write(data));
  const profile = mkdtempSync(path.join(tmpdir(), 'screenguide-test-'));
  let context;
  try {
    await waitFor(() => output.includes('Listening'));
    context = await chromium.launchPersistentContext(profile, {
      ...(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : { channel: 'chromium' }),
      headless: true,
      args: [`--disable-extensions-except=${extension}`, `--load-extension=${extension}`],
    });
    const worker = context.serviceWorkers()[0] || await context.waitForEvent('serviceworker');
    const page = await context.newPage();
    const request = (message) => worker.evaluate(async (message) => {
      const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
      return chrome.tabs.sendMessage(tab.id, message, { frameId: 0 });
    }, message);
    await page.route('https://fixture.test/**', (route) => route.fulfill({ contentType: 'text/html', body: `
      <title>ScreenGuide checks</title><style>body{margin:24px}button,input{padding:12px}#far{margin-top:1800px}</style>
      <h1>Video player controls</h1><button id="captions" aria-label="Subtitles/closed captions (c)"><span>CC</span></button>
      <button id="wrong">Other button</button><form action="/next"><label>Search <input type="search" name="query"></label><button>Submit</button></form>
      <label>Password <input id="password" type="password" value="SECRET_PASSWORD"></label>
      <label>Payment <input id="payment" autocomplete="cc-number" value="SECRET_CARD"></label>
      <div aria-hidden="true"><button>Hidden</button></div><fieldset disabled><button>Disabled</button></fieldset>
      <button id="far">Far below the fold</button>` }));
    await page.goto('https://fixture.test/');
    await page.bringToFront();
    await page.waitForTimeout(500);
    let snapshot = await request({ type: 'snapshot_request', id: 'fixture' });
    assert.equal(snapshot.id, 'fixture');
    assert(snapshot.elements.some((el) => el.name.includes('Subtitles')));
    assert(snapshot.elements.some((el) => el.role === 'searchbox'));
    assert(!snapshot.elements.some((el) => el.name === 'Hidden'));
    assert.equal(snapshot.elements.find((el) => el.name === 'Disabled').enabled, false);
    assert.equal(snapshot.elements.find((el) => el.type === 'password').value, null);
    assert.equal(snapshot.elements.find((el) => el.name === 'Payment').value, null);
    assert(!JSON.stringify(snapshot).includes('SECRET_'));
    const again = await request({ type: 'snapshot_request', id: 'again', max_elements: 2 });
    assert.equal(again.elements.length, 2);
    assert.equal(again.elements[0].ref, snapshot.elements[0].ref);
    let mark = output.length;
    mock.stdin.write('snap\n');
    await waitFor(() => output.slice(mark).includes('Subtitles/closed captions'));
    console.log('PASS fixture snapshot, stable refs, cap, sensitive values, mock routing');
    const captions = snapshot.elements.find((el) => /Subtitles/.test(el.name));
    mark = output.length;
    mock.stdin.write(`hl ${captions.ref}\n`);
    await waitFor(() => output.slice(mark).includes('highlight_ok'));
    await page.waitForSelector('sg-overlay');
    async function checkPlacement(selector) {
      const geometry = await page.evaluate((selector) => {
        const root = document.querySelector('sg-overlay').shadowRoot;
        const card = root.querySelector('.card').getBoundingClientRect();
        const ring = root.querySelector('.ring');
        const target = document.querySelector(selector).getBoundingClientRect();
        return { card: { l: card.left, t: card.top, r: card.right, b: card.bottom },
          target: { l: target.left, t: target.top, r: target.right, b: target.bottom },
          ring: { l: parseFloat(ring.style.left), t: parseFloat(ring.style.top) } };
      }, selector);
      assert(Math.abs(geometry.ring.l - geometry.target.l + 6) < 1);
      assert(Math.abs(geometry.ring.t - geometry.target.t + 6) < 1);
      const c = geometry.card, t = geometry.target;
      assert(c.r <= t.l || c.l >= t.r || c.b <= t.t || c.t >= t.b, 'Card covers target');
    }
    await checkPlacement('#captions');
    let result = await request({ type: 'highlight', id: 'safe-text', ref: captions.ref,
      instruction: 'Click **captions** <img src=x onerror=alert(1)>', step: 2 });
    assert.equal(result.type, 'highlight_ok');
    assert.equal(await page.locator('sg-overlay img').count(), 0);
    assert.equal(await page.locator('sg-overlay strong').textContent(), 'captions');
    const far = snapshot.elements.find((el) => el.name === 'Far below the fold');
    result = await request({ type: 'highlight', id: 'far', ref: far.ref, instruction: 'Click below' });
    assert.equal(result.type, 'highlight_ok');
    await page.waitForTimeout(500);
    assert(await page.evaluate(() => scrollY > 1000));
    await checkPlacement('#far');
    await page.evaluate(() => scrollBy(0, -120));
    await page.waitForTimeout(100);
    await checkPlacement('#far');
    await page.setViewportSize({ width: 480, height: 640 });
    await page.waitForTimeout(100);
    await checkPlacement('#far');
    await page.setViewportSize({ width: 1280, height: 720 });
    const password = snapshot.elements.find((el) => el.type === 'password');
    await request({ type: 'highlight', id: 'password', ref: password.ref, instruction: 'Enter password' });
    assert((await page.locator('sg-overlay .card').textContent()).includes("I'll look away"));
    result = await request({ type: 'highlight', id: 'missing', ref: 'missing', instruction: 'Click' });
    assert.equal(result.reason, 'ref_not_found');
    console.log('PASS mock highlight, safe bold text, card geometry, long-page scroll/resize tracking, password instruction');


    if (process.argv.includes('--live')) {
      for (const [url, match] of [
        ['https://en.wikipedia.org/wiki/Philippines', (el) => el.role === 'searchbox'],
        ['https://www.youtube.com/watch?v=jNQXAC9IVRw', (el) => /subtitles|captions/i.test(el.name)],
        ['https://www.youtube.com/', () => true],
      ]) {
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await page.waitForTimeout(6000);
        snapshot = await request({ type: 'snapshot_request', id: 'live' });
        assert(snapshot.elements.some(match), `Missing element on ${url}`);
        assert(snapshot.elements.length <= 400);
        assert(snapshot.ms < 300, `Snapshot took ${snapshot.ms}ms`);
        mark = output.length;
        mock.stdin.write('snap\n');
        await waitFor(() => output.slice(mark).includes('ref | role | name'));
        if (url.includes('/watch')) {
          const captions = snapshot.elements.find((el) => /subtitles|captions/i.test(el.name));
          mark = output.length;
          mock.stdin.write(`hl ${captions.ref}\n`);
          await waitFor(() => output.slice(mark).includes('highlight_ok'));
          const selector = `[data-sg-ref="${captions.ref}"]`;
          await checkPlacement(selector);
          console.log('PASS live YouTube captions highlight through mock, ring and card placement');
        }
        console.log(`PASS ${url}: ${snapshot.elements.length} elements, ${snapshot.ms.toFixed(1)}ms, mock table printed`);
      }
    }
  } finally {
    if (context) await context.close();
    mock.kill();
    rmSync(profile, { recursive: true, force: true });
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
