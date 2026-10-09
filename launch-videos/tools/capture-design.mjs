// Screenshot each artboard (data-screen-label) of the Beside design handoff for reference.
// Usage: node tools/capture-design.mjs <Beside-standalone.html> <outdir>
import puppeteer from 'puppeteer-core';
import path from 'node:path';
const [src, out] = process.argv.slice(2);
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
const page = await browser.newPage();
await page.setViewport({ width: 1600, height: 1000, deviceScaleFactor: 1 });
await page.goto('file://' + path.resolve(src), { waitUntil: 'networkidle0' });
await new Promise(r => setTimeout(r, 1500));
const els = await page.$$('[data-screen-label]');
for (const el of els) {
  const label = await el.evaluate(e => e.getAttribute('data-screen-label'));
  await el.screenshot({ path: path.join(out, label.replace(/[^\w]+/g, '-') + '.png') });
}
console.log(els.length, 'artboards');
await browser.close();
