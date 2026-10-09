// Seek the composition and print computed opacity / visibility for selectors.
import puppeteer from 'puppeteer-core';
import path from 'node:path';
const [file, t, ...sels] = process.argv.slice(2);
const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
const p = await b.newPage(); await p.setViewport({ width: 1920, height: 1080 });
await p.evaluateOnNewDocument(() => { window.__timelines = {}; });
await p.goto('file://' + path.resolve(file), { waitUntil: 'load' });
const out = await p.evaluate((t, sels) => { window.__timelines.main.seek(+t);
  return sels.map((q) => { const e = document.querySelector(q); const c = getComputedStyle(e); return [q, c.opacity, c.display, c.visibility, c.transform.slice(0, 60), e.getBoundingClientRect().top|0]; }); }, t, sels);
console.log(out.map((o) => o.join(' | ')).join('\n')); await b.close();
