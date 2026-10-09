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
        console.log(`PASS ${url}: ${snapshot.elements.length} elements, ${snapshot.ms.toFixed(1)}ms, mock table printed`);
      }
    }
  } finally {
    if (context) await context.close();
    mock.kill();
    rmSync(profile, { recursive: true, force: true });
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
