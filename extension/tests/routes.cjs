// Runs without a mock or loaded extension, so a separate live demo can keep its port.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  try {
    const page = await browser.newPage();
    await page.route('https://routes.test/**', (route) => route.fulfill({ contentType: 'text/html', body: '<h1>Route checks</h1><div id="changes"></div>' }));
    await page.goto('https://routes.test/');
    await page.evaluate(() => {
      window.messages = [];
      window.chrome = { runtime: { id: 'test', onMessage: { addListener() {} },
        sendMessage(message) { messages.push(message); return Promise.resolve(); } } };
    });
    await page.addScriptTag({ path: path.join(__dirname, '../src/navigation.js') });
    await page.addScriptTag({ path: path.join(__dirname, '../src/content.js') });
    await page.waitForFunction(() => messages.some((m) => m.reason === 'navigation'));
    for (const method of ['pushState', 'replaceState']) {
      await page.evaluate((method) => {
        messages.length = 0;
        History.prototype[method].call(history, {}, '', `/${method}`);
      }, method);
      await page.waitForFunction(() => messages.some((m) => m.reason === 'spa_route'));
      assert.equal(await page.evaluate(() => messages.filter((m) => m.reason === 'spa_route').length), 1);
    }
    await page.evaluate(() => {
      messages.length = 0;
      History.prototype.pushState.call(history, {}, '', '/busy-route');
      window.churn = setInterval(() => {
        const block = document.querySelector('#changes');
        for (let i = 0; i < 25; i++) block.append(document.createElement('span'));
        block.replaceChildren();
      }, 50);
    });
    await page.waitForFunction(() => messages.some((m) => m.reason === 'spa_route'), null, { timeout: 2000 });
    assert.equal(await page.evaluate(() => messages.find((m) => m.reason === 'spa_route').url), 'https://routes.test/busy-route');
    await page.evaluate(() => clearInterval(churn));
    console.log('PASS native History bypass, replaceState, and SPA notification during continuous DOM churn');
    if (process.argv.includes('--live')) {
      const context = await browser.newContext({ bypassCSP: true });
      const live = await context.newPage();
      await live.goto('https://www.youtube.com/watch?v=aircAruvnKk', { waitUntil: 'domcontentloaded' });
      await live.waitForTimeout(6000);
      // Stub only the local transport; leave the site's real history and DOM behavior intact.
      await live.evaluate(() => {
        window.messages = [];
        window.chrome = { runtime: { id: 'test', onMessage: { addListener() {} },
          sendMessage(message) { messages.push(message); return Promise.resolve(); } } };
      });
      await live.addScriptTag({ path: path.join(__dirname, '../src/navigation.js') });
      await live.addScriptTag({ path: path.join(__dirname, '../src/content.js') });
      const selected = await live.locator('a[href^="/watch"]').evaluateAll((links) => {
        const link = links.find((el) => {
          const rect = el.getBoundingClientRect();
          return rect.width >= 80 && rect.height >= 40 &&
            el.contains(document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)) &&
            new URL(el.href).searchParams.get('v') !== new URL(location.href).searchParams.get('v');
        });
        link?.setAttribute('data-route-check', 'target');
        return Boolean(link);
      });
      assert(selected, 'No visible related video thumbnail');
      await live.locator('[data-route-check="target"]').click();
      await live.waitForFunction(() => messages.some((m) => m.reason === 'spa_route'));
      const event = await live.evaluate(() => messages.find((m) => m.reason === 'spa_route'));
      console.log('PASS real YouTube video navigation with stubbed transport:', JSON.stringify(event));
      await context.close();
    }

  } finally { await browser.close(); }
})().catch((error) => { console.error(error); process.exitCode = 1; });
