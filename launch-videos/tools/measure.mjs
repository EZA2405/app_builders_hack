// Print design-space rects (relative to #cam) for selectors, with every element made visible.
import puppeteer from 'puppeteer-core';
import path from 'node:path';
const [file, ...sels] = process.argv.slice(2);
const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
const p = await b.newPage(); await p.setViewport({ width: 1920, height: 1080 });
await p.goto('file://' + path.resolve(file), { waitUntil: 'load' });
const out = await p.evaluate((sels) => {
  document.querySelectorAll('*').forEach((e) => { e.style.transform = 'none'; e.style.translate = 'none'; e.style.scale = 'none'; e.style.rotate = 'none'; }); const cam = document.getElementById('cam');
  const c = cam.getBoundingClientRect();
  return sels.map((q) => { const r = document.querySelector(q).getBoundingClientRect(); return [q, Math.round(r.left - c.left), Math.round(r.top - c.top), Math.round(r.width), Math.round(r.height)]; });
}, sels);
console.log(out.map((o) => o.join(' ')).join('\n')); await b.close();
