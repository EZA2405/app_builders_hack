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
  const startMock = () => {
    const app = spawn(process.env.TEST_PYTHON || 'python3', [path.join(extension, 'mock/mock_app.py')]);
    app.stdout.on('data', (data) => { output += data; });
    app.stderr.on('data', (data) => process.stderr.write(data));
    return app;
  };
  let mock = startMock();
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
    await page.evaluate(() => {
      const host = document.createElement('shadow-demo');
      const root = host.attachShadow({ mode: 'open' });
      const button = document.createElement('button');
      button.textContent = 'Open shadow button';
      root.append(button);
      document.body.prepend(host);
    });
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
    const shadowButton = snapshot.elements.find((el) => el.name === 'Open shadow button');
    assert(shadowButton, 'Open shadow DOM was skipped');
    let shadowResult = await request({ type: 'highlight', id: 'shadow', ref: shadowButton.ref, instruction: 'Click shadow button' });
    assert.equal(shadowResult.type, 'highlight_ok');
    mark = output.length;
    await page.locator('shadow-demo button').click();
    await waitFor(() => output.slice(mark).includes('"on_target": true'));
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
    let optional = await request({ type: 'highlight', id: 'spotlight', ref: captions.ref, instruction: 'Click captions', style: 'spotlight' });
    assert.equal(optional.type, 'highlight_ok');
    assert.equal(await page.locator('sg-overlay .spotlight').count(), 1);
    assert.equal(await page.locator('sg-overlay .spotlight').evaluate((el) => getComputedStyle(el).pointerEvents), 'none');
    mark = output.length;
    await page.locator('#captions').click();
    await waitFor(() => output.slice(mark).includes('"on_target": true'));
    const candidates = snapshot.elements.filter((el) => el.tag === 'button' && el.in_viewport).slice(0, 3).map((el) => el.ref);
    mark = output.length;
    mock.stdin.write(`notsure ${candidates.join(' ')}\n`);
    await waitFor(() => output.slice(mark).includes('highlight_ok'));
    assert.equal(await page.locator('sg-overlay .ring').count(), 3);
    assert.deepEqual(await page.locator('sg-overlay .badge').allTextContents(), ['1', '2', '3']);
    console.log('PASS open shadow DOM snapshot/click, spotlight click-through, numbered candidates');

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
    await request({ type: 'highlight', id: 'click', ref: captions.ref, instruction: 'Click captions' });
    mark = output.length;
    await page.locator('#captions span').click();
    await waitFor(() => output.slice(mark).includes('"on_target": true'));
    mark = output.length;
    await page.locator('#wrong').click();
    await waitFor(() => output.slice(mark).includes('"on_target": false'));
    mark = output.length;
    await page.locator('sg-overlay button').filter({ hasText: 'Show me again' }).click();
    await waitFor(() => output.slice(mark).includes('"button": "again"'));
    assert(!output.slice(mark).includes('user_action'), 'Overlay button leaked a page action');
    mark = output.length;
    await page.locator('#password').fill('DO_NOT_SEND_PASSWORD');
    await page.keyboard.press('Escape');
    await pause(500);
    assert(!output.slice(mark).includes('user_action'), 'Sensitive focus leaked action');
    await page.locator('#payment').fill('DO_NOT_SEND_CARD');
    await pause(100);
    assert(!output.slice(mark).includes('user_action'), 'Payment focus leaked action');
    await page.evaluate(() => document.activeElement.blur());
    mark = output.length;
    await page.locator('input[type=search]').fill('DO_NOT_SEND_TYPED_TEXT');
    await waitFor(() => output.slice(mark).includes('"kind": "input"'));
    assert(!output.includes('DO_NOT_SEND_'));
    mark = output.length;
    await page.keyboard.press('Enter');
    await waitFor(() => output.slice(mark).includes('"kind": "submit"'));
    await waitFor(() => output.slice(mark).includes('"reason": "navigation"'));
    // Discard old refs after a real document navigation.
    snapshot = await request({ type: 'snapshot_request', id: 'new-page' });
    const current = snapshot.elements.find((el) => /Subtitles/.test(el.name));
    await request({ type: 'highlight', id: 'route-target', ref: current.ref, instruction: 'Click captions' });
    mark = output.length;
    await page.evaluate(() => history.pushState({}, '', '/spa-route'));
    await waitFor(() => output.slice(mark).includes('"reason": "spa_route"'));
    assert.equal(await page.locator('sg-overlay').count(), 0);
    mark = output.length;
    await page.evaluate(() => history.replaceState({}, '', '/replaced-route'));
    await waitFor(() => output.slice(mark).includes('"reason": "spa_route"'));
    mark = output.length;
    await page.evaluate(() => {
      const block = document.createElement('div');
      for (let i = 0; i < 25; i++) block.append(document.createElement('span'));
      document.body.append(block);
    });
    await waitFor(() => output.slice(mark).includes('"reason": "dom_mutation"'));
    await request({ type: 'highlight', id: 'removed', ref: current.ref, instruction: 'Click captions' });
    mark = output.length;
    await page.locator('#captions').evaluate((el) => el.remove());
    await waitFor(() => output.slice(mark).includes('"reason": "dom_mutation"'));
    assert.equal(await page.locator('sg-overlay').count(), 0);
    console.log('PASS nested target and wrong clicks, card events, sensitive focus suppression, input without values, submit/navigation, SPA routes, DOM changes and removed target');
    mock.kill();
    await new Promise((resolve) => mock.once('exit', resolve));
    // Longer than MV3's idle timeout, so this checks retries while disconnected too.
    await pause(35000);
    mark = output.length;
    const restart = Date.now();
    mock = startMock();
    await waitFor(() => output.slice(mark).includes('ref | role | name'), 11000);
    assert(Date.now() - restart < 10000, 'Reconnect exceeded 10s');
    console.log(`PASS mock restart after 35s outage: reconnected in ${Date.now() - restart}ms without reloading page`);




    await page.route('https://fixture.test/same-frame', (route) => route.fulfill({ contentType: 'text/html', body:
      '<button>Same frame button</button><input type="password" value="FRAME_SECRET">' }));
    await page.route('https://frame.test/root', (route) => route.fulfill({ contentType: 'text/html', body:
      '<button>Remote frame button</button><iframe src="https://frame.test/child" style="display:block;width:600px;height:120px"></iframe><iframe src="https://nested-frame.test/" style="display:block;width:600px;height:220px"></iframe>' }));
    await page.route('https://frame.test/child', (route) => route.fulfill({ contentType: 'text/html', body: '<button>Nested same button</button>' }));
    await page.route('https://nested-frame.test/', (route) => route.fulfill({ contentType: 'text/html', body: '<button>Nested remote button</button>' }));
    await page.goto('https://fixture.test/frame-check');
    await page.evaluate(() => {
      document.body.replaceChildren();
      for (const src of ['https://fixture.test/same-frame', 'https://frame.test/root']) {
        const frame = document.createElement('iframe');
        frame.src = src;
        frame.style.cssText = 'display:block;width:700px;height:500px;margin:20px;';
        document.body.append(frame);
      }
    });
    await pause(1200);
    snapshot = await request({ type: 'snapshot_request', id: 'frames' });
    const names = ['Same frame button', 'Remote frame button', 'Nested same button', 'Nested remote button'];
    const frameElements = names.map((name) => snapshot.elements.find((el) => el.name === name));
    assert(frameElements.every(Boolean), `Missing frame snapshot: ${JSON.stringify(snapshot)}`);
    assert.equal(new Set(frameElements.map((el) => el.frame)).size, 4);
    assert.equal(new Set(snapshot.elements.map((el) => el.ref)).size, snapshot.elements.length);
    assert(!JSON.stringify(snapshot).includes('FRAME_SECRET'));
    const stableFrames = await request({ type: 'snapshot_request', id: 'stable-frames' });
    for (const el of frameElements) assert.equal(stableFrames.elements.find((e) => e.name === el.name).ref, el.ref);
    mock.stdin.write('snap\n');
    await pause(500);
    for (let i = 0; i < names.length; i++) {
      const el = frameElements[i];
      mark = output.length;
      mock.stdin.write(`hl ${el.ref}\n`);
      await waitFor(() => output.slice(mark).includes('highlight_ok'));
      const frame = page.frames().find((f) => f.url() === [
        'https://fixture.test/same-frame', 'https://frame.test/root', 'https://frame.test/child', 'https://nested-frame.test/'
      ][i]);
      mark = output.length;
      await frame.getByRole('button', { name: names[i], exact: true }).click();
      await waitFor(() => output.slice(mark).includes('"on_target": true'));
      assert(output.slice(mark).includes(`"ref": "${el.ref}"`));
      const actions = output.slice(mark).split('\n').filter((line) => line.includes('"type": "user_action"'));
      assert.equal(actions.length, 1, 'Duplicate iframe action');
    }
    mark = output.length;
    mock.stdin.write(`notsure ${frameElements.slice(0, 3).map((el) => el.ref).join(' ')}\n`);
    await waitFor(() => output.slice(mark).includes('highlight_ok'));
    assert.equal(await page.locator('sg-overlay .badge').textContent(), '1');
    const remoteFrame = page.frames().find((f) => f.url() === 'https://frame.test/root');
    assert.deepEqual(await remoteFrame.locator('sg-overlay .badge').allTextContents(), ['2', '3']);
    assert.equal(await remoteFrame.locator('sg-overlay .card').isVisible(), false);
    mark = output.length;
    mock.stdin.write('clear\n');
    await pause(200);
    for (const frame of page.frames()) assert.equal(await frame.locator('sg-overlay').count(), 0);
    console.log(`PASS same-origin, cross-origin and nested frame snapshots/highlights/clicks, unique refs, multi-frame candidates and clear (${snapshot.ms.toFixed(1)}ms)`);

    await page.goto('https://fixture.test/performance');
    await page.evaluate(() => {
      const fragment = document.createDocumentFragment();
      for (let i = 0; i < 2000; i++) {
        const button = document.createElement('button');
        button.textContent = `Control ${i}`;
        fragment.append(button);
      }
      document.body.replaceChildren(fragment);
    });
    snapshot = await request({ type: 'snapshot_request', id: 'heavy-fixture' });
    assert.equal(snapshot.elements.length, 400);
    assert(snapshot.ms < 300, `Heavy fixture took ${snapshot.ms}ms`);
    let outside = false;
    for (const el of snapshot.elements) {
      if (!el.in_viewport) outside = true;
      if (outside) assert.equal(el.in_viewport, false, 'Viewport ordering is broken');
    }
    console.log(`PASS 2,000-button fixture: capped at 400, viewport first, ${snapshot.ms.toFixed(1)}ms`);

    if (process.argv.includes('--live')) {
      for (const [url, match] of [
        ['https://en.wikipedia.org/wiki/Philippines', (el) => el.role === 'searchbox'],
        ['https://www.youtube.com/watch?v=aircAruvnKk', (el) => /subtitles|captions/i.test(el.name)],
        ['https://www.youtube.com/', () => true],
      ]) {
        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await page.waitForTimeout(6000);
        if (url.includes('/watch')) {
          if (await page.locator('video').evaluate((video) => video.paused)) await page.locator('.ytp-play-button').click();
          await page.locator('#movie_player').hover();
          // Prepare captions off with a user gesture, so the guided click demonstrates turning them on.
          if (await page.locator('.ytp-subtitles-button').getAttribute('aria-pressed') === 'true') await page.locator('.ytp-subtitles-button').click();
          await page.waitForFunction(() => document.querySelector('.ytp-subtitles-button')?.getAttribute('aria-pressed') === 'false');
        }
        snapshot = await request({ type: 'snapshot_request', id: 'live' });
        assert(snapshot.elements.some(match), `Missing element on ${url}`);
        assert(snapshot.elements.length <= 400);
        assert(snapshot.ms < 300, `Snapshot took ${snapshot.ms}ms`);
        mark = output.length;
        mock.stdin.write('snap\n');
        await waitFor(() => output.slice(mark).includes('ref | role | name'));
        if (url.includes('wikipedia')) {
          const search = snapshot.elements.find((el) => el.role === 'searchbox');
          const input = page.locator(`[data-sg-ref="${search.ref}"]`);
          mark = output.length;
          await input.fill('Cebu');
          await waitFor(() => output.slice(mark).includes('"kind": "input"'));
          const events = output.slice(mark).split('\n').filter((line) => line.startsWith('{')).map((line) => JSON.parse(line));
          for (const event of events.filter((event) => event.type === 'user_action')) assert(!('value' in event));
          mark = output.length;
          await input.press('Enter');
          await waitFor(() => output.slice(mark).includes('"kind": "submit"'));
          await waitFor(() => output.slice(mark).includes('"reason": "navigation"'), 45000);
          console.log('PASS live Wikipedia: input without value, submit, full-page navigation');
        }
        if (url.includes('/watch')) {
          const captions = snapshot.elements.find((el) => /subtitles|captions/i.test(el.name));
          mark = output.length;
          mock.stdin.write(`hl ${captions.ref}\n`);
          await waitFor(() => output.slice(mark).includes('highlight_ok'));
          const selector = `[data-sg-ref="${captions.ref}"]`;
          await checkPlacement(selector);
          mark = output.length;
          await page.locator(selector).click();
          await waitFor(() => output.slice(mark).includes('"on_target": true'));
          await page.waitForFunction((ref) => document.querySelector(`[data-sg-ref="${ref}"]`)?.getAttribute('aria-pressed') === 'true', captions.ref, { timeout: 15000 });
          console.log('PASS live YouTube captions: mock highlight → browser click → on_target:true, captions enabled');
          await page.screenshot({ path: path.join(tmpdir(), 'screenguide-youtube-demo.png') });
          mock.stdin.write('clear\n');
          await page.waitForSelector('sg-overlay', { state: 'detached' });
          const other = await page.locator('a[href^="/watch"]').evaluateAll((links) => {
            const link = links.find((el) => {
              const rect = el.getBoundingClientRect();
              const hit = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2);
              return rect.width >= 80 && rect.height >= 40 && el.contains(hit) &&
                el.getAttribute('data-sg-ref') && new URL(el.href).searchParams.get('v') !== new URL(location.href).searchParams.get('v');
            });
            return link?.getAttribute('data-sg-ref');
          });
          assert(other, 'No visible related video thumbnail to exercise live SPA navigation');
          mark = output.length;
          await page.locator(`[data-sg-ref="${other}"]`).click();
          await waitFor(() => output.slice(mark).includes('"reason": "spa_route"'));
          console.log('PASS live YouTube click to another video: spa_route');

        }
        console.log(`PASS ${url}: ${snapshot.elements.length} elements, ${snapshot.ms.toFixed(1)}ms, mock table printed`);
      }
    }
  } catch (error) {
    console.error('Mock output tail:', output.slice(-2000));
    throw error;
  } finally {
    if (context) await context.close();
    mock.kill();
    rmSync(profile, { recursive: true, force: true });
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
