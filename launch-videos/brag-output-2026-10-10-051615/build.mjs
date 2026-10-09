// Gabay launch video (~60 s). One generator → composition-landscape (1920x1080) + composition-feed (1080x1350).
// Times are authored in seconds on a 120 BPM grid (1 beat = 0.5 s). All three music beds are 120.19 BPM and are
// started on their own downbeats, so cuts on whole/half seconds land on the beat.
import fs from 'node:fs';
import path from 'node:path';

const HERE = path.dirname(new URL(import.meta.url).pathname);
const END = 60.0;
const VER = '0.8.143';

// ---------- voice-over (Kokoro-82M on this Mac; make-vo.py writes shared-assets/vo) ----------
function wavDur(file) { const b = fs.readFileSync(file); let o = 12, rate = 0, ch = 0, bits = 0; while (o < b.length - 8) { const id = b.toString('ascii', o, o + 4), sz = b.readUInt32LE(o + 4); if (id === 'fmt ') { ch = b.readUInt16LE(o + 10); rate = b.readUInt32LE(o + 12); bits = b.readUInt16LE(o + 22); } if (id === 'data') return sz / (rate * ch * bits / 8); o += 8 + sz + (sz % 2); } return 0; }
const VO = JSON.parse(fs.readFileSync(path.join(HERE, 'vo-lines.json'), 'utf8'));
VO.forEach(v => { v.d = +wavDur(path.join(HERE, 'shared-assets/vo', v.id + '.wav')).toFixed(3); });
const underVO = t => VO.some(v => t > v.t - 0.2 && t < v.t + v.d + 0.1);
const VOICE = VO.map((v, i) => `<audio id="vo-${i}" src="assets/vo/${v.id}.wav" data-start="${v.t}" data-duration="${v.d}" data-volume="1" data-track-index="${60 + (i % 3)}"></audio>`).join('\n  ');
// music ducks ~7 dB under each line; close lines merge so the bed doesn't pump
function duck(start, len, V, fin = 0.03, foutAt = len - 0.03) {
  const D = 0.45, m = [];
  VO.map(v => [v.t - start - 0.15, v.t + v.d - start + 0.2]).filter(([a, b]) => b > fin && a < foutAt).forEach(w => { if (m.length && w[0] < m[m.length - 1][1] + 0.5) m[m.length - 1][1] = Math.max(m[m.length - 1][1], w[1]); else m.push(w.slice()); });
  const pts = [[0, 0], [fin, m.length && m[0][0] <= fin ? V * D : V]];
  m.forEach(([a, b]) => { const a1 = Math.max(a, fin + 0.01), b1 = Math.min(b, foutAt - 0.01); if (b1 <= a1) return; pts.push([a1, V], [Math.min(a1 + 0.15, b1), V * D], [b1, V * D], [Math.min(b1 + 0.25, foutAt), V]); });
  pts.push([foutAt, V], [len, 0]);
  const out = []; pts.sort((x, y) => x[0] - y[0]).forEach(([t, v]) => { t = +t.toFixed(3); if (out.length && out[out.length - 1].t >= t) out[out.length - 1].v = +v.toFixed(3); else out.push({ t, v: +v.toFixed(3) }); });
  return out;
}

// ---------- audio ----------
const DUR = {
  'buzz.wav': 1.4, 'click_003.ogg': 0.01, 'drop_001.ogg': 0.11, 'drop_002.ogg': 0.19, 'impact-bass-1.mp3': 2.1,
  'impact-bass-2.mp3': 2.59, 'impactBell_heavy_000.ogg': 1.48, 'impactSoft_medium_001.ogg': 0.18,
  'keypress-001.wav': 0.25, 'keypress-002.wav': 0.25, 'keypress-003.wav': 0.25, 'keypress-004.wav': 0.25,
  'riser.mp3': 10.03, 'sparkle.mp3': 1.8, 'whoosh-cinematic.mp3': 5.54, 'whoosh-short.mp3': 0.57,
};
let aid = 0; const audio = [];
const sfx = (file, t, vol, dur) => { dur = Math.min(dur || DUR[file] || 0.3, END - t); if (underVO(t) && !/click|keypress/.test(file)) vol = +(vol * 0.65).toFixed(2); audio.push(`<audio id="sfx-${++aid}" src="assets/sfx/${file}" data-start="${t}" data-duration="${dur.toFixed(3)}" data-volume="${vol}" data-track-index="${30 + (aid % 12)}"></audio>`); };
[
  ['buzz.wav', 0.0, 0.55], ['drop_002.ogg', 0.12, 0.35],
  ['whoosh-short.mp3', 3.3, 0.3], ['whoosh-cinematic.mp3', 3.85, 0.45, 2.2], ['impact-bass-1.mp3', 4.45, 0.3],
  ['whoosh-short.mp3', 5.45, 0.3], ['impactSoft_medium_001.ogg', 5.98, 0.7], ['drop_001.ogg', 6.0, 0.45],
  ['whoosh-short.mp3', 8.3, 0.25], ['impactSoft_medium_001.ogg', 8.5, 0.4],
  ['whoosh-cinematic.mp3', 10.05, 0.3, 1.5], ['drop_002.ogg', 10.6, 0.4], ['impactSoft_medium_001.ogg', 10.7, 0.45],
  ['drop_001.ogg', 11.1, 0.4], ['impactSoft_medium_001.ogg', 12.45, 0.45], ['click_003.ogg', 13.45, 0.6],
  ['whoosh-short.mp3', 14.0, 0.35], ['impactSoft_medium_001.ogg', 14.4, 0.45], ['sparkle.mp3', 15.0, 0.3],
  ['riser.mp3', 14.2, 0.22, 1.8], ['whoosh-cinematic.mp3', 15.5, 0.35, 1.2], ['impact-bass-2.mp3', 16.0, 0.5],
  ['whoosh-short.mp3', 17.65, 0.35], ['click_003.ogg', 18.7, 0.7], ['drop_002.ogg', 18.72, 0.35],
  ['whoosh-short.mp3', 20.75, 0.25], ['click_003.ogg', 21.08, 0.7], ['drop_002.ogg', 21.1, 0.3],
  ['whoosh-cinematic.mp3', 22.55, 0.25, 1.2], ['drop_001.ogg', 22.8, 0.4],
  ['whoosh-short.mp3', 24.7, 0.3], ['click_003.ogg', 25.13, 0.7], ['drop_002.ogg', 25.15, 0.3],
  ['whoosh-short.mp3', 25.9, 0.3], ['impactSoft_medium_001.ogg', 26.25, 0.55],
  ['whoosh-cinematic.mp3', 27.55, 0.35, 1.2], ['impact-bass-1.mp3', 28.0, 0.35],
  ['click_003.ogg', 28.17, 0.6], ['whoosh-short.mp3', 29.65, 0.32], ['click_003.ogg', 30.0, 0.6], ['drop_002.ogg', 31.6, 0.35],
  ['whoosh-short.mp3', 31.65, 0.32], ['impactSoft_medium_001.ogg', 32.4, 0.4],
  ['whoosh-short.mp3', 33.65, 0.32], ['click_003.ogg', 34.21, 0.6], ['drop_001.ogg', 35.27, 0.4],
  ['whoosh-short.mp3', 35.65, 0.32], ['click_003.ogg', 36.85, 0.6], ['click_003.ogg', 37.38, 0.6],
  ['whoosh-cinematic.mp3', 37.9, 0.35, 1.4], ['drop_002.ogg', 38.1, 0.3], ['drop_001.ogg', 38.3, 0.3],
  ['impactSoft_medium_001.ogg', 40.5, 0.45], ['impactSoft_medium_001.ogg', 41.3, 0.5],
  ['whoosh-short.mp3', 42.55, 0.3], ['drop_002.ogg', 42.7, 0.35], ['drop_002.ogg', 42.9, 0.35], ['drop_002.ogg', 43.1, 0.35],
  ['impactSoft_medium_001.ogg', 44.6, 0.45], ['impactSoft_medium_001.ogg', 45.2, 0.5],
  ['impactSoft_medium_001.ogg', 46.5, 0.45], ['sparkle.mp3', 46.75, 0.25], ['click_003.ogg', 47.65, 0.9], ['drop_001.ogg', 47.67, 0.45],
  ['impact-bass-2.mp3', 48.0, 0.4], ['drop_002.ogg', 49.2, 0.35], ['drop_002.ogg', 49.52, 0.35], ['drop_002.ogg', 49.84, 0.35], ['whoosh-short.mp3', 51.7, 0.3],
  ['whoosh-cinematic.mp3', 51.85, 0.3, 1.5], ['sparkle.mp3', 52.0, 0.35], ['impactBell_heavy_000.ogg', 52.05, 0.3],
  ['drop_002.ogg', 53.2, 0.35], ['impactSoft_medium_001.ogg', 54.75, 0.45],
].forEach(([f, t, v, d]) => sfx(f, t, v, d));
const URL_TEXT = 'github.com/EZA2405/app_builders_hack';
for (let i = 0; i < URL_TEXT.length; i += 2) sfx(`keypress-00${1 + (i * 3) % 4}.wav`, +(53.45 + i * 0.03).toFixed(3), 0.22);

const q = o => JSON.stringify(o).replace(/&/g, '&amp;').replace(/"/g, '&quot;');
const edge = (len, v, fadeIn = 0.03, fadeOut = 0.03) => [{ t: 0, v: 0 }, { t: fadeIn, v }, { t: +(len - fadeOut).toFixed(3), v }, { t: len, v: 0 }];
// M1: quiet intro under the hook, low-pass "exhale" on the Wait card, then the drop at 16.0 (Wi‑Fi rescue).
const lp = q({ version: 1, nodes: [{ type: 'lowpass', id: 'n1', label: 'Exhale', params: { frequency: 20000, q: 0.9, poles: '2' } }] });
const m1Auto = q({ version: 1, lanes: [
  { target: 'volume', points: duck(0, 24, 0.7, 0.6) },
  { target: 'fx.n1.frequency', points: [{ t: 0, v: 20000 }, { t: 5.95, v: 20000 }, { t: 6.05, v: 900 }, { t: 8.2, v: 1300, curve: 0.7 }, { t: 9.6, v: 20000 }] },
] });
const m2Auto = q({ version: 1, lanes: [{ target: 'volume', points: duck(24, 8, 0.62) }] });
const m3Auto = q({ version: 1, lanes: [{ target: 'volume', points: duck(32, 16, 0.95) }] });
const m4Auto = q({ version: 1, lanes: [{ target: 'volume', points: duck(48, 12, 0.66, 0.03, 10.6) }] });
const MUSIC = `
  <audio id="m1" src="assets/music/pop.wav" data-start="0" data-duration="24" data-media-start="0.02" data-volume="1" data-track-index="20" data-fx-chain="${lp}" data-automation="${m1Auto}"></audio>
  <audio id="m2" src="assets/music/pop.wav" data-start="24" data-duration="8" data-media-start="16.02" data-volume="1" data-track-index="21" data-automation="${m2Auto}"></audio>
  <audio id="m3" src="assets/music/drive.wav" data-start="32" data-duration="16" data-media-start="8.02" data-volume="1" data-track-index="22" data-automation="${m3Auto}"></audio>
  <audio id="m4" src="assets/music/pop.wav" data-start="48" data-duration="12" data-media-start="16.02" data-volume="1" data-track-index="23" data-automation="${m4Auto}"></audio>`;

// ---------- helpers ----------
// Words wrapped in masks so they can rise from a baseline. *word* = purple accent, _word_ = amber.
const words = (s, id) => s.split(' ').map((w, i) => {
  let cls = 'w';
  if (/^\*.*\*[.,!?]*$/.test(w)) { cls += ' acc'; w = w.replace(/\*/g, ''); }
  if (/^_.*_[.,!?]*$/.test(w)) { cls += ' amb'; w = w.replace(/_/g, ''); }
  if (/^~.*~[.,!?]*$/.test(w)) { cls += ' red'; w = w.replace(/~/g, ''); }
  return `<span class="m"><span class="${cls}"${id ? ` id="${id}-${i}"` : ''}>${w}</span></span>`;
}).join(' ');
const lines = (arr, cls = '') => arr.map(l => `<div class="ln ${cls}">${words(l)}</div>`).join('');
const PHONE = '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/>';
const POINTER = '<svg width="64" height="64" viewBox="0 0 24 24" aria-hidden="true"><path d="M5 3.5l13.5 7.3-6 1.6-2.9 5.8z" fill="#fff" stroke="#1d1d1f" stroke-width="1.3" stroke-linejoin="round"/></svg>';
const chars = s => Array.from(s).map(c => `<span class="ch">${c}</span>`).join('');
const dev = (id, src, pv) => `<div class="dev${pv ? ' pv' : ''} h" id="${id}"><div class="tilt"><div class="scr">${src}</div></div></div>`;
const vid = (id, file, start, dur, mstart, rate, track) => `<video id="${id}" class="clip" src="assets/clips/${file}" muted playsinline data-start="${start}" data-duration="${dur}" data-media-start="${mstart}"${rate !== 1 ? ` data-playback-rate="${rate}"` : ''} data-track-index="${track}"></video>`;

// ---------- formats ----------
const FORMATS = {
  landscape: {
    dir: 'composition-landscape', W: 1920, H: 1080, crumbOut: 27.55,
    quote: ["Ma'am, pakibasa po yung", '_OTP_ na tinext namin.'],
    B: { punch: { x: 110, y: 90, w: 1700, h: 760, clamp: 1 }, side: { x: 900, y: 110, w: 940, h: 860 }, hero: { x: 60, y: 170, w: 880, h: 740 } },
    css: `
:root{--W:1920px;--H:1080px}
#call{left:630px;top:150px}
#q{left:0;right:0;top:380px;text-align:center;font-size:112px}
#qen{left:0;right:0;top:665px;text-align:center;font-size:40px}
.side{left:110px;width:760px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center}
.side .big{font-size:96px}
.side .sub{font-size:44px;margin-top:26px}
.bot{left:0;right:0;bottom:58px;display:flex;justify-content:center}
.topc{left:0;right:0;top:34px;display:flex;justify-content:center}
.pcap .big{font-size:76px}
.ctr{left:0;right:0;text-align:center}
#p1lab{top:330px;font-size:44px}#p1{top:400px;font-size:150px}
#p2{top:330px;font-size:150px}
#p3{top:330px;font-size:150px}
#gh{top:56px;font-size:84px}
#gsub{top:156px;font-size:38px}
#grid{left:0;top:0;width:var(--W);height:var(--H)}
.tile{width:520px;height:326px}
#t0{left:120px;top:250px}#t1{left:700px;top:250px}#t2{left:1280px;top:250px}
#t3{left:120px;top:630px}#t4{left:700px;top:630px}#t5{left:1280px;top:630px}
#nlab{top:250px;font-size:44px}
#nbase{top:330px;font-size:150px}
#nours{top:330px;font-size:230px}
#nourlab{top:610px;font-size:44px}
#bars{left:330px;width:1260px;top:300px}
.brow{height:150px}
.blab{font-size:42px}.bval{font-size:64px}
.btrack{height:34px}
#c1{top:330px;font-size:150px}#c2{top:500px;font-size:150px}
#tg1{top:280px;font-size:180px}#tg2{top:520px;font-size:180px}
#tg3{top:250px;font-size:170px}
#chips{top:690px}.chip{font-size:38px}
#brand{left:1010px;top:250px}
#logo{width:150px;height:150px}
#wm{font-size:150px}
#edesc{left:1014px;top:450px;font-size:44px}
#ebar{left:1010px;top:580px;width:850px;height:108px;font-size:32px}
#efoot{left:1014px;top:760px;font-size:30px}
`,
  },
  feed: {
    dir: 'composition-feed', W: 1080, H: 1350, crumbOut: 25.9,
    quote: ["Ma'am, pakibasa", 'po yung _OTP_', 'na tinext namin.'],
    B: { punch: { x: 40, y: 250, w: 1000, h: 720, clamp: 1 }, side: { x: 50, y: 470, w: 980, h: 780 }, hero: { x: 90, y: 90, w: 900, h: 600 } },
    css: `
:root{--W:1080px;--H:1350px}
#call{left:210px;top:170px}
#q{left:0;right:0;top:430px;text-align:center;font-size:104px}
#qen{left:60px;right:60px;top:820px;text-align:center;font-size:38px}
.side{left:70px;right:70px;top:90px;height:360px;display:flex;flex-direction:column;justify-content:center;text-align:center}
.side .big{font-size:96px}
.side .sub{font-size:38px;margin-top:20px}
.bot{left:0;right:0;bottom:64px;display:flex;justify-content:center}
.topc{left:0;right:0;bottom:64px;display:flex;justify-content:center}
.pcap .big{font-size:64px}
.ctr{left:0;right:0;text-align:center}
#p1lab{top:500px;font-size:40px}#p1{top:560px;font-size:88px}
#p2{top:470px;font-size:104px}
#p3{top:470px;font-size:104px}
#gh{top:100px;font-size:64px}
#gsub{top:190px;font-size:36px}
#grid{left:0;top:0;width:var(--W);height:var(--H)}
.tile{width:470px;height:295px}
#t0{left:50px;top:300px}#t1{left:560px;top:300px}#t2{left:50px;top:630px}
#t3{left:560px;top:630px}#t4{left:50px;top:960px}#t5{left:560px;top:960px}
#nlab{top:380px;font-size:40px}
#nbase{top:470px;font-size:130px}
#nours{top:470px;font-size:200px}
#nourlab{top:720px;font-size:38px}
#bars{left:80px;width:920px;top:420px}
.brow{height:150px}
.blab{font-size:36px}.bval{font-size:56px}
.btrack{height:30px}
#c1{top:480px;font-size:96px}#c2{top:610px;font-size:96px}
#tg1{top:420px;font-size:140px}#tg2{top:620px;font-size:140px}
#tg3{top:430px;font-size:120px}
#chips{top:760px;flex-wrap:wrap;padding:0 60px}.chip{font-size:32px}
#brand{left:90px;top:760px}
#logo{width:128px;height:128px}
#wm{font-size:128px}
#edesc{left:94px;top:930px;font-size:40px}
#ebar{left:90px;top:1030px;width:900px;height:104px;font-size:34px}
#efoot{left:94px;top:1200px;font-size:28px}
`,
  },
};

const BASE = `
*{box-sizing:border-box}
html,body{margin:0;background:#0B0B0F}
body{font-family:-apple-system,BlinkMacSystemFont,system-ui,sans-serif;-webkit-font-smoothing:antialiased;color:#F5F5F7}
#root{position:relative;width:100%;height:100%;overflow:hidden;background:#0B0B0F}
.clip{position:absolute;inset:0}
section.clip{overflow:hidden}
.abs{position:absolute}
.full{left:0;top:0;width:var(--W);height:var(--H)}
.h{opacity:0}
.disp{font-weight:600;letter-spacing:-.045em;line-height:1.04}
.ln{white-space:nowrap}
.m{display:inline-block;overflow:hidden;vertical-align:top;padding:.04em .06em .18em;margin:-.04em -.06em -.18em}
.w{display:inline-block}
.acc{color:#BF5AF2}
.amb{color:#FFB340}
.red{color:#C4001A}
.mut{color:#A1A1A6}
svg{display:block}
.reveal{position:absolute;left:0;top:0;width:var(--W);height:var(--H)}
.dev{position:absolute;left:0;top:0;width:1920px;height:1248px;transform-origin:0 0}
.dev.pv{width:816px}
.tilt{position:absolute;inset:0}
.scr{position:absolute;inset:0;border-radius:30px;overflow:hidden;background:#000;box-shadow:0 0 0 2px rgba(255,255,255,.10),0 80px 200px -40px rgba(0,0,0,.85)}
.scr video,.scr img{position:absolute;left:0;top:0;width:100%;height:100%;object-fit:cover}
.glass{background:rgba(22,22,26,.8);-webkit-backdrop-filter:blur(26px) saturate(1.5);backdrop-filter:blur(26px) saturate(1.5);border-radius:32px;box-shadow:0 0 0 1px rgba(255,255,255,.09),0 30px 80px -30px rgba(0,0,0,.8)}
/* hook */
#call{width:660px;height:136px;border-radius:68px;background:#1C1C1E;box-shadow:0 0 0 1px rgba(255,255,255,.1),0 40px 100px -30px rgba(0,0,0,.9);display:flex;align-items:center;gap:22px;padding:0 22px}
#cav{position:relative;flex:none;width:92px;height:92px;border-radius:50%;background:#3A3A3C;display:grid;place-items:center;font-size:34px;font-weight:600;color:#F5F5F7}
.pr{position:absolute;inset:0;border-radius:50%;border:3px solid rgba(255,255,255,.5)}
#cmid{flex:1}
#cname{font-size:40px;font-weight:600;letter-spacing:-.02em}
#csub{font-size:26px;color:#A1A1A6;margin-top:2px}
.cbtn{flex:none;width:76px;height:76px;border-radius:50%;display:grid;place-items:center}
.cbtn.red{background:#FF3B30}.cbtn.grn{background:#34C759}
#qen{color:#A1A1A6;font-style:italic;letter-spacing:-.01em}
#otpu{position:absolute;left:4%;right:4%;bottom:.06em;height:.07em;border-radius:.05em;background:#FFB340;transform-origin:0% 50%}
#w-otp{position:relative}
#o{display:inline-block}
/* scam / flood / problem */
#flood{background:#FFF6E4}
#s-prob{color:#1C1C1E}
#p1lab{color:#6B5B3E;font-weight:500;letter-spacing:-.01em}
#rframe{left:0;top:0;width:var(--W);height:var(--H)}
#spill{left:0;right:0;top:56px;display:flex;justify-content:center}
#spill span{display:flex;align-items:center;gap:14px;background:#C4001A;color:#fff;font-size:30px;font-weight:600;border-radius:40px;padding:14px 30px}
#spill i{display:block;width:16px;height:16px;border-radius:50%;background:#fff}
#gcur{left:0;top:0}
#gcur .tag{position:absolute;left:58px;top:46px;white-space:nowrap;background:#C4001A;color:#fff;font-size:26px;font-weight:600;border-radius:20px;padding:8px 16px}
#darkp{background:#0B0B0F}
#p3{color:#F5F5F7}
#ringsvg{left:0;top:0;width:var(--W);height:var(--H);overflow:visible}
#ringfill{background:#BF5AF2}
#mframe{border-radius:34px;background:#000;box-shadow:0 0 0 2px rgba(255,255,255,.12),0 60px 160px -40px rgba(0,0,0,.9)}
/* captions */
.pcap{padding:22px 38px;text-align:center}
.pcap .lab{font-size:28px;color:#A1A1A6;margin-bottom:6px;letter-spacing:-.01em}
#crumbs{display:flex;align-items:center;gap:18px;padding:16px 30px;font-size:30px;font-weight:600;letter-spacing:-.02em;color:#8E8E93}
#crumbs b{font-weight:600}
#crumbs .sep{color:#636366}
.cdot{display:inline-block;width:14px;height:14px;border-radius:50%;border:3px solid #BF5AF2;margin-right:10px;vertical-align:middle}
.side .sub{color:#A1A1A6;font-weight:500;letter-spacing:-.02em;line-height:1.2}
/* grid */
.tile{position:absolute;border-radius:26px;overflow:hidden;background:#1C1C1E;box-shadow:0 0 0 2px rgba(255,255,255,.08),0 40px 90px -40px rgba(0,0,0,.9)}
.tile img{width:100%;height:100%;object-fit:cover;display:block}
#gsub{color:#A1A1A6;font-weight:500;letter-spacing:-.01em}
/* numbers */
#nlab,#nourlab{color:#A1A1A6;font-weight:500;letter-spacing:-.01em}
#nbase{color:#8E8E93}
.slash{color:#636366}
.brow{display:flex;flex-direction:column;justify-content:center;gap:16px}
.bhead{display:flex;justify-content:space-between;align-items:baseline}
.blab{font-weight:600;letter-spacing:-.02em}
.blab span{color:#8E8E93;font-weight:500}
.bval{font-weight:600;letter-spacing:-.04em}
.btrack{position:relative;border-radius:20px;background:#1C1C1E;overflow:hidden}
.bfill{position:absolute;left:0;right:0;top:0;bottom:0;border-radius:20px;background:#636366;transform-origin:0% 50%}
#b0 .bfill{background:#BF5AF2}
#b0 .bval{color:#BF5AF2}
/* tagline */
#tgring{left:0;top:0;width:var(--W);height:var(--H);overflow:visible}
#tcur{left:0;top:0}
#chips{left:0;right:0;display:flex;justify-content:center;gap:18px}
.chip{display:flex;align-items:center;gap:12px;background:#1C1C1E;border-radius:40px;padding:14px 28px 14px 22px;font-weight:600;letter-spacing:-.02em;box-shadow:0 0 0 1px rgba(255,255,255,.1)}
#ripple{position:absolute;left:-26px;top:-26px;width:64px;height:64px;border-radius:50%;background:rgba(191,90,242,.55)}
/* end */
#brand{display:flex;align-items:center;gap:34px}
#logo{position:relative;flex:none}
#logo svg{width:100%;height:100%}
#logo{filter:drop-shadow(0 24px 48px rgba(123,92,250,.45))}
#lring{stroke-linecap:round}
#wm .c{display:inline-block}
#edesc{color:#A1A1A6;font-weight:500;letter-spacing:-.02em}
#ebar{border-radius:999px;background:#1C1C1E;box-shadow:0 0 0 3px #7B5CFA,0 30px 80px -30px rgba(123,92,250,.55);display:flex;align-items:center;gap:22px;padding:0 20px 0 40px;font-weight:500;letter-spacing:-.02em;transform-origin:0% 50%}
#ebar>svg{flex:none;color:#8E8E93}
#ebartxt{white-space:nowrap}
.ch{opacity:0}
#ecaret{flex:none;width:3px;height:1em;background:#9F8CFF;margin-left:-18px}
#ego{margin-left:auto;flex:none;width:76px;height:76px;border-radius:50%;background:#7B5CFA;display:grid;place-items:center}
#efoot{color:#8E8E93;letter-spacing:-.01em}
`;

function page(F) {
  const B = F.B;
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=${F.W}, height=${F.H}" />
<title>Gabay — launch</title>
<script src="assets/gsap.min.js"></script>
<style>${BASE}${F.css}</style>
</head>
<body>
<div id="root" data-composition-id="main" data-start="0" data-width="${F.W}" data-height="${F.H}" data-duration="${END}">

  <!-- devices (untimed wrappers; the videos inside carry the timing) -->
  <div class="reveal h" id="r-scam" style="z-index:10">${dev('d-scam', vid('v-scam', 'scam.mp4', 3.9, 6.9, 0, 1, 2))}</div>
  <div class="abs full h" id="flood" style="z-index:12"></div>

  <!-- 1 · Hook: the call -->
  <section id="s-hook" class="clip" data-start="0" data-duration="4.6" data-track-index="1" style="z-index:30">
    <div id="call" class="abs h">
      <div id="cav"><i class="pr"></i><i class="pr"></i><span>PH</span></div>
      <div id="cmid"><div id="cname">“PhilHealth”</div><div id="csub">Unknown number · calling…</div></div>
      <div class="cbtn red"><svg width="38" height="38" viewBox="0 0 24 24" fill="#fff" aria-hidden="true"><g transform="rotate(135 12 12)">${PHONE}</g></svg></div>
      <div class="cbtn grn"><svg width="36" height="36" viewBox="0 0 24 24" fill="#fff" aria-hidden="true">${PHONE}</svg></div>
    </div>
    <div id="q" class="abs disp">${F.quote.map(l => `<div class="ln">${l.split(' ').map(w => w === '_OTP_'
      ? `<span class="m" id="m-otp"><span class="w amb" id="w-otp"><span id="o">O</span>TP<i id="otpu"></i></span></span>`
      : `<span class="m"><span class="w">${w}</span></span>`).join(' ')}</div>`).join('')}</div>
    <div id="qen" class="abs h">“Ma’am, please read us the OTP we texted you.”</div>
  </section>

  <!-- 2 · Scam caught (caption) -->
  <section id="s-scamcap" class="clip" data-start="8.3" data-duration="2.2" data-track-index="3" style="z-index:20">
    <div class="side abs"><div class="big disp">${lines(['Scam caught.', '*On* *the* *laptop.*'])}</div></div>
  </section>

  <!-- 3 · The problem -->
  <section id="s-prob" class="clip" data-start="10.5" data-duration="5.6" data-track-index="4" style="z-index:31">
    <div id="p1lab" class="abs ctr">${words('The usual help for Lola:')}</div>
    <div id="p1" class="abs ctr disp" data-layout-allow-overlap>${words('“Share your screen.”')}</div>
    <div id="p2" class="abs ctr disp" data-layout-allow-overlap>${lines(['That’s how', '~scammers~ get in.'])}</div>
    <svg id="rframe" class="abs" viewBox="0 0 ${F.W} ${F.H}" aria-hidden="true"><rect id="rrect" x="22" y="22" width="${F.W - 44}" height="${F.H - 44}" rx="34" fill="none" stroke="#D70015" stroke-width="10" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/></svg>
    <div id="spill" class="abs h"><span><i></i>You’re sharing your screen</span></div>
    <div id="gcur" class="abs h">${POINTER}<span class="tag">Remote control</span></div>
    <div id="darkp" class="abs full h"></div>
    <div id="p3" class="abs ctr disp">${lines(['Gabay never sees', 'your screen.'])}</div>
    <svg id="ringsvg" class="abs" aria-hidden="true"><rect id="gring" x="0" y="0" width="10" height="10" rx="26" fill="none" stroke="#BF5AF2" stroke-width="7" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" style="filter:drop-shadow(0 0 18px rgba(191,90,242,.8))"/></svg>
  </section>

  <!-- 4 · Wi‑Fi rescue: the ring grows into the real screen -->
  <div class="abs full h" id="ringfill" style="z-index:34"></div>
  <div class="reveal h" id="r-wifi" style="z-index:35">${dev('d-wifi', vid('v-wifi', 'wifi.mp4', 15.5, 12.5, 0, 0.834, 5))}</div>
  <section id="s-wcap" class="clip" data-start="15.9" data-duration="12.1" data-track-index="6" style="z-index:40">
    <div class="bot abs"><div id="cap-ask" class="glass pcap h"><div class="lab">Asked in Taglish</div><div class="big disp">How do I get my Wi‑Fi back?</div></div></div>
    <div class="topc abs"><div id="crumbs" class="glass h"><b id="cr0"><i class="cdot"></i>Apple menu</b><span class="sep">›</span><b id="cr1"><i class="cdot"></i>System Settings</b><span class="sep">›</span><b id="cr2"><i class="cdot"></i>Wi‑Fi</b></div></div>
    <div class="bot abs"><div id="cap-off" class="glass pcap h"><div class="big disp">${words('Offline. *Still* *guiding.*')}</div></div></div>
  </section>

  <!-- 5 · Range montage -->
  <div class="abs h" id="mframe" style="z-index:44;left:${B.side.x}px;top:${B.side.y}px;width:${B.side.w}px;height:${B.side.h}px"></div>
  <div class="reveal" id="r-mont" style="z-index:45">
    ${dev('d-m1', vid('v-m1', 'yt_search.mp4', 27.65, 2.6, 2.6, 1, 7))}
    ${dev('d-m2', vid('v-m2', 'yt_cc.mp4', 29.65, 2.6, 1.95, 1.25, 8))}
    ${dev('d-m3', vid('v-m3', 'yt_ask.mp4', 31.65, 2.6, 2.4, 0.8, 9))}
    ${dev('d-m4', vid('v-m4', 'rotate.mp4', 33.65, 2.6, 1.3, 1.25, 10), true)}
    ${dev('d-m5', vid('v-m5', 'addtext.mp4', 35.65, 2.75, 2.0, 1.35, 11), true)}
  </div>
  <section id="s-mont" class="clip" data-start="27.9" data-duration="10.3" data-track-index="12" style="z-index:50">
    <div class="side abs" id="ml0"><div class="big disp">${words('YouTube.')}</div><div class="sub">${words('It finds the search box.')}</div></div>
    <div class="side abs" id="ml1"><div class="big disp">${words('Subtitles.')}</div><div class="sub">${words('Turned on, one step at a time.')}</div></div>
    <div class="side abs" id="ml2"><div class="big disp">${words('Not sure?')}</div><div class="sub">${words('It asks. You decide.')}</div></div>
    <div class="side abs" id="ml3"><div class="big disp">${words('Photos.')}</div><div class="sub">${words('Rotate it in Preview.')}</div></div>
    <div class="side abs" id="ml4"><div class="big disp">${words('Add text.')}</div><div class="sub">${words('Tools, Annotate, Text.')}</div></div>
  </section>

  <!-- grid -->
  <section id="s-grid" class="clip" data-start="37.85" data-duration="2.85" data-track-index="13" style="z-index:55">
    <div id="grid" class="abs">
      ${['t_scam', 't_wifi', 't_search', 't_cc', 't_ask', 't_rotate'].map((n, i) => `<div class="tile" id="t${i}"><img src="assets/img/${n}.jpg" alt=""></div>`).join('\n      ')}
    </div>
    <div id="gh" class="abs ctr disp">${words('Apps. Websites. *Settings.*')}</div>
    <div id="gsub" class="abs ctr">${words('One calm next step at a time.')}</div>
  </section>

  <!-- 6 · Numbers (measured: ml/RESULTS.md, README) -->
  <section id="s-num" class="clip" data-start="40.4" data-duration="6.2" data-track-index="14" style="z-index:60">
    <div id="nlab" class="abs ctr">${words('On apps it never trained on')}</div>
    <div id="nbase" class="abs ctr disp"><span class="m"><span class="w">8<span class="slash">/35</span></span></span></div>
    <div id="nours" class="abs ctr disp h"><span class="acc" id="nval">8</span><span class="slash">/35</span></div>
    <div id="nourlab" class="abs ctr h">Base model 8/35 → after our fine-tune 29/35</div>
    <div id="bars" class="abs">
      <div class="brow" id="b0"><div class="bhead"><div class="blab">Gabay <span>· on the laptop</span></div><div class="bval">29</div></div><div class="btrack"><i class="bfill"></i></div></div>
      <div class="brow" id="b1"><div class="bhead"><div class="blab">OpenAI <span>· cloud</span></div><div class="bval">33</div></div><div class="btrack"><i class="bfill"></i></div></div>
      <div class="brow" id="b2"><div class="bhead"><div class="blab">Jev <span>· cloud</span></div><div class="bval">35</div></div><div class="btrack"><i class="bfill"></i></div></div>
    </div>
    <div id="c1" class="abs ctr disp">${words('Close to the cloud.')}</div>
    <div id="c2" class="abs ctr disp">${words('*Without* *the* *cloud.*')}</div>
  </section>

  <!-- 7 · Tagline -->
  <section id="s-tag" class="clip" data-start="46.4" data-duration="5.7" data-track-index="15" style="z-index:65">
    <div id="tg1" class="abs ctr disp">${words('It points.', 'tg1w')}</div>
    <div id="tg2" class="abs ctr disp">${words('She clicks.', 'tg2w')}</div>
    <svg id="tgring" class="abs" aria-hidden="true"><rect id="tring" x="0" y="0" width="10" height="10" rx="28" fill="none" stroke="#BF5AF2" stroke-width="7" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" style="filter:drop-shadow(0 0 16px rgba(191,90,242,.75))"/></svg>
    <div id="tcur" class="abs h"><i id="ripple" class="h"></i>${POINTER}</div>
    <div id="tg3" class="abs ctr disp">${lines(['*Nothing* leaves', 'the laptop.'])}</div>
    <div id="chips" class="abs">${['No screen sharing', 'No cloud', 'Works offline'].map(c => `<span class="chip"><svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#BF5AF2" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>${c}</span>`).join('')}</div>
  </section>

  <!-- 8 · End card -->
  <section id="s-end" class="clip" data-start="51.9" data-duration="${(END - 51.9).toFixed(2)}" data-track-index="16" style="z-index:70">
    ${dev('d-hero', '<img src="assets/img/hero_wifi.jpg" alt="Gabay ringing the Wi‑Fi row in System Settings">')}
    <div id="brand" class="abs"><div id="logo"><svg viewBox="0 0 256 256" aria-hidden="true"><rect width="256" height="256" rx="56" fill="#7B5CFA"/><g fill="#FFFFFF"><circle class="ldot" cx="56" cy="198" r="5" fill-opacity=".4"/><circle class="ldot" cx="72" cy="168" r="6" fill-opacity=".55"/><circle class="ldot" cx="94" cy="144" r="7" fill-opacity=".7"/><circle class="ldot" cx="122" cy="126" r="8" fill-opacity=".85"/></g><circle id="lhalo" cx="172" cy="96" r="44" fill="none" stroke="#FFFFFF" stroke-opacity=".25" stroke-width="6"/><circle id="lring" cx="172" cy="96" r="30" fill="none" stroke="#FFFFFF" stroke-width="12" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" transform="rotate(-90 172 96)"/></svg></div><div id="wm" class="disp">${Array.from('Gabay').map(c => `<span class="c">${c}</span>`).join('')}</div></div>
    <div id="edesc" class="abs">${words('A patient guide for Lola’s Mac.')}</div>
    <div id="ebar" class="abs h"><svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg><span id="ebartxt">${chars(URL_TEXT)}</span><i id="ecaret"></i><span id="ego"><svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg></span></div>
    <div id="efoot" class="abs h">Built in 24 hours · AppBuildersPH 2026 · Local AI</div>
  </section>
${MUSIC}
  ${VOICE}
  ${audio.join('\n  ')}
</div>

<script>
document.fonts.ready.then(function () {
  var W = ${F.W}, H = ${F.H}, B = ${JSON.stringify(B)}, CROUT = ${F.crumbOut};
  var tl = gsap.timeline({ paused: true });
  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };
  function at(sel, vars, t) { return tl.to(sel, vars, t); }
  function ft(sel, from, to, t) { return tl.fromTo(sel, from, to, t); }
  function ftl(sel, from, to, t) { to.immediateRender = false; return tl.fromTo(sel, from, to, t); }
  function set(sel, vars, t) { return tl.set(sel, vars, t); }
  function pos(el) { var x = 0, y = 0, e = el; while (e && e.id !== 'root') { x += e.offsetLeft; y += e.offsetTop; e = e.offsetParent; } return { x: x, y: y, w: el.offsetWidth, h: el.offsetHeight, cx: x + el.offsetWidth / 2, cy: y + el.offsetHeight / 2 }; }
  // camera: place region r=[fx,fy,fw,fh] (fractions of the recording) centered in box
  function fit(box, r, cw, ch) { var s = Math.min(box.w / (r[2] * cw), box.h / (r[3] * ch)); return { x: box.x + box.w / 2 - (r[0] + r[2] / 2) * cw * s, y: box.y + box.h / 2 - (r[1] + r[3] / 2) * ch * s, scale: s }; }
  function D(sel, pv) { return { sel: sel, cw: pv ? 816 : 1920, ch: 1248 }; }
  function clampV(v, d) { var dw = d.cw * v.scale, dh = d.ch * v.scale; if (dw >= W) v.x = Math.min(0, Math.max(W - dw, v.x)); if (dh >= H) v.y = Math.min(0, Math.max(H - dh, v.y)); return v; }
  function cam(d, box, r, t, dur, ease, extra) { var v = fit(box, r, d.cw, d.ch); if (box.clamp) clampV(v, d); var o = { x: v.x, y: v.y, scale: v.scale }; if (extra) for (var k in extra) o[k] = extra[k]; if (!dur) { set(d.sel, o, t); } else { o.duration = dur; o.ease = ease || 'expo.inOut'; at(d.sel, o, t); } return v; }
  function rect(v, r, d) { return { x: v.x + r[0] * d.cw * v.scale, y: v.y + r[1] * d.ch * v.scale, w: r[2] * d.cw * v.scale, h: r[3] * d.ch * v.scale }; }
  function inset(rc, rad) { return 'inset(' + rc.y.toFixed(1) + 'px ' + (W - rc.x - rc.w).toFixed(1) + 'px ' + (H - rc.y - rc.h).toFixed(1) + 'px ' + rc.x.toFixed(1) + 'px round ' + rad.toFixed(1) + 'px)'; }
  function rise(sel, t, o) { o = o || {}; return ft(sel, { yPercent: 118, opacity: 0, rotation: o.rot || 0 }, { yPercent: 0, opacity: 1, rotation: 0, duration: o.d || 0.6, ease: o.ease || 'expo.out', stagger: o.st == null ? 0.07 : o.st }, t); }
  function sink(sel, t, o) { o = o || {}; return at(sel, { yPercent: -118, opacity: 0, duration: o.d || 0.32, ease: 'power3.in', stagger: o.st == null ? 0.03 : o.st }, t); }
  // motion blur that peaks mid-move (camera smear)
  function smear(sel, t, dur, px) { ftl(sel, { filter: 'blur(0px)' }, { filter: 'blur(' + px + 'px)', duration: dur / 2, ease: 'sine.inOut', yoyo: true, repeat: 1 }, t); }
  function whipIn(d, v, t, dir) { ftl(d.sel, { opacity: 0, x: v.x + dir * W * 1.1, y: v.y, scale: v.scale, filter: 'blur(18px)' }, { opacity: 1, x: v.x, filter: 'blur(0px)', duration: 0.42, ease: 'expo.out' }, t); }
  function whipOut(d, t, dir) { at(d.sel, { x: '+=' + (dir * W * 1.1), opacity: 0, filter: 'blur(18px)', duration: 0.34, ease: 'power3.in' }, t); }

  // ================= 1 · Hook (0–4.5) =================
  ft('#call', { opacity: 0, y: 240, rotationX: -70, scale: 0.7, filter: 'blur(18px)', transformPerspective: 1400 }, { opacity: 1, y: 0, rotationX: 0, scale: 1, filter: 'blur(0px)', duration: 0.85, ease: 'expo.out' }, 0.05);
  [0.12, 1.07].forEach(function (b) { for (var i = 0; i < 6; i++) at('#call', { rotation: i % 2 ? -1.8 : 1.8, duration: 0.05, ease: 'none' }, b + i * 0.05); at('#call', { rotation: 0, duration: 0.08 }, b + 0.3); });
  ft('.pr', { scale: 1, opacity: 0.6 }, { scale: 2.1, opacity: 0, duration: 0.95, ease: 'power2.out', stagger: 0.45, repeat: 2 }, 0.3);
  var qw = $$('#q .w');
  qw.forEach(function (w, i) { ft(w, { yPercent: 118, opacity: 0, rotation: 5 }, { yPercent: 0, opacity: 1, rotation: 0, duration: 0.6, ease: 'expo.out' }, 0.8 + i * 0.14); });
  ft('#otpu', { scaleX: 0 }, { scaleX: 1, duration: 0.45, ease: 'expo.out' }, 1.75);
  ft('#qen', { opacity: 0, y: 24 }, { opacity: 1, y: 0, duration: 0.5, ease: 'power3.out' }, 1.95);
  at('#q', { scale: 1.04, duration: 3.0, ease: 'none', transformOrigin: '50% 50%' }, 0.8);
  // clear everything but OTP, then OTP takes the center and we fall through its O into the real screen
  at('#call', { opacity: 0, y: -70, scale: 0.9, filter: 'blur(14px)', duration: 0.35, ease: 'power2.in' }, 3.0);
  at('#qen', { opacity: 0, y: -24, duration: 0.3, ease: 'power2.in' }, 3.0);
  sink(qw.filter(function (w) { return w.id !== 'w-otp'; }), 3.05, { st: 0.022 });
  at('#otpu', { scaleX: 0, duration: 0.2, ease: 'power2.in' }, 3.05);
  var qs = 1.04, F = parseFloat(getComputedStyle($('#q')).fontSize) * qs;
  var pO = pos($('#o')), pW = pos($('#w-otp')), pQ = pos($('#q'));
  // #q is scaled about its own center at this point; map layout coords to screen coords
  function qmap(x, y) { return { x: pQ.cx + (x - pQ.cx) * qs, y: pQ.cy + (y - pQ.cy) * qs }; }
  var oc = qmap(pO.cx, pO.y + pO.h * 0.52), wc = qmap(pW.x, pW.y);
  var ox = (oc.x - wc.x) / qs, oy = (oc.y - wc.y) / qs;
  set('#m-otp', { overflow: 'visible' }, 3.3);
  set('#w-otp', { transformOrigin: ox + 'px ' + oy + 'px' }, 3.3);
  at('#w-otp', { x: (W / 2 - oc.x) / qs, y: (H / 2 - oc.y) / qs, scale: 2.2, duration: 0.55, ease: 'expo.inOut' }, 3.3);
  for (var j = 0; j < 4; j++) at('#w-otp', { rotation: j % 2 ? -1.5 : 1.5, duration: 0.04, ease: 'none' }, 3.72 + j * 0.04);
  at('#w-otp', { rotation: 0, duration: 0.04 }, 3.88);
  var ZS = 30, r0 = 0.2 * F * 2.2;
  at('#w-otp', { scale: 2.2 * ZS, duration: 0.62, ease: 'power2.in' }, 3.9);
  ftl('#w-otp', { filter: 'blur(0px)' }, { filter: 'blur(5px)', duration: 0.22, ease: 'power1.in' }, 4.3);
  set('#r-scam', { opacity: 1 }, 3.9);
  ft('#r-scam', { clipPath: 'circle(' + r0.toFixed(1) + 'px at ' + W / 2 + 'px ' + H / 2 + 'px)' }, { clipPath: 'circle(' + (r0 * ZS).toFixed(1) + 'px at ' + W / 2 + 'px ' + H / 2 + 'px)', duration: 0.62, ease: 'power2.in' }, 3.9);
  set('#r-scam', { clipPath: 'none' }, 4.54);

  // ================= 2 · Scam caught (3.9–10.6) =================
  var DS = D('#d-scam');
  set('#d-scam', { opacity: 1 }, 3.9);
  cam(DS, B.punch, [0.545, 0.76, 0.40, 0.145], 3.9, 0);
  at('#d-scam', { x: '-=50', duration: 1.5, ease: 'none' }, 3.95);
  cam(DS, B.punch, [0.665, 0.53, 0.335, 0.30], 5.4, 0.62, 'power3.inOut');
  smear('#d-scam', 5.4, 0.62, 6);
  cam(DS, B.punch, [0.68, 0.545, 0.305, 0.27], 6.02, 1.98, 'none');
  var vSide = cam(DS, B.side, [0, 0, 1, 1], 8.0, 0.95, 'power3.inOut');
  smear('#d-scam', 8.0, 0.95, 5);
  ftl('#d-scam .tilt', { rotationY: 0 }, { rotationY: -11, duration: 0.95, ease: 'power3.inOut', transformPerspective: 2200 }, 8.0);
  at('#d-scam .tilt', { rotationY: 0, duration: 0.45, ease: 'power2.inOut' }, 9.65);
  rise('#s-scamcap .w', 8.6, { st: 0.06 });
  sink('#s-scamcap .w', 9.95, { st: 0.02 });
  // the Wait card grows into the next scene (cream flood)
  var card = rect(vSide, [0.69, 0.552, 0.302, 0.248], DS);
  ftl('#flood', { opacity: 0 }, { opacity: 1, duration: 0.12, ease: 'none' }, 10.12);
  ft('#flood', { clipPath: inset(card, 16 * vSide.scale) }, { clipPath: 'inset(0px 0px 0px 0px round 0px)', duration: 0.5, ease: 'power3.inOut' }, 10.12);
  set('#r-scam', { opacity: 0 }, 10.6);

  // ================= 3 · The problem (10.5–16.0) =================
  rise('#p1lab .w', 10.6, { st: 0.04, d: 0.5 });
  rise('#p1 .w', 10.72, { st: 0.08 });
  ft('#p1', { scale: 1.08 }, { scale: 1, duration: 1.7, ease: 'power2.out', transformOrigin: '50% 50%' }, 10.6);
  ft('#rrect', { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.6, ease: 'power2.inOut' }, 10.95);
  ft('#spill', { opacity: 0, y: -90 }, { opacity: 1, y: 0, duration: 0.5, ease: 'back.out(1.8)' }, 11.1);
  sink('#p1lab .w, #p1 .w', 12.02, { st: 0.02 });
  rise('#p2 .w', 12.45, { st: 0.07 });
  ft('#p2', { scale: 1.06 }, { scale: 1, duration: 1.6, ease: 'power2.out', transformOrigin: '50% 50%' }, 12.45);
  at('#rrect', { opacity: 0.3, duration: 0.16, repeat: 3, yoyo: true, ease: 'none' }, 12.55);
  ft('#gcur', { opacity: 0, x: W * 0.08, y: H * 1.05 }, { opacity: 1, x: W * 0.62, y: H * 0.74, duration: 0.85, ease: 'power2.inOut' }, 12.6);
  at('#gcur', { x: W * 0.55, y: H * 0.70, duration: 0.3, ease: 'power1.inOut' }, 13.45);
  at('#gcur', { x: W * 0.66, y: H * 0.76, duration: 0.3, ease: 'power1.inOut' }, 13.75);
  sink('#p2 .w', 13.9, { st: 0.02 });
  ft('#darkp', { opacity: 1, yPercent: 100 }, { yPercent: 0, duration: 0.34, ease: 'power3.inOut' }, 14.0);
  set('#flood', { opacity: 0 }, 14.4);
  rise('#p3 .w', 14.38, { st: 0.07 });
  var gw = $$('#p3 .w')[0], pG = pos(gw), pad = 16;
  var gr = { x: pG.x - pad, y: pG.y - pad * 0.6, w: pG.w + pad * 2, h: pG.h + pad * 1.2 };
  $('#gring').setAttribute('x', gr.x); $('#gring').setAttribute('y', gr.y); $('#gring').setAttribute('width', gr.w); $('#gring').setAttribute('height', gr.h);
  ft('#gring', { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.45, ease: 'power2.inOut' }, 15.0);
  sink($$('#p3 .w').slice(1), 15.25, { st: 0.02 });
  // the ring becomes the frame of the real screen and grows to full (drop at 16.0)
  set('#ringfill', { opacity: 1 }, 15.5);
  set('#r-wifi', { opacity: 1 }, 15.5);
  set('#gring', { opacity: 0 }, 15.5);
  var gr6 = { x: gr.x - 7, y: gr.y - 7, w: gr.w + 14, h: gr.h + 14 };
  ft('#ringfill', { clipPath: inset(gr6, 32) }, { clipPath: 'inset(-8px -8px -8px -8px round 0px)', duration: 0.5, ease: 'power3.inOut' }, 15.5);
  ft('#r-wifi', { clipPath: inset(gr, 26) }, { clipPath: 'inset(0px 0px 0px 0px round 0px)', duration: 0.5, ease: 'power3.inOut' }, 15.5);
  set('#r-wifi', { clipPath: 'none' }, 16.02);
  set('#ringfill', { opacity: 0 }, 16.02);

  // ================= 4 · Wi‑Fi rescue (15.5–28.0); trimmed clip time c ↔ video 15.5 + c/0.834 =================
  var DW = D('#d-wifi');
  set('#d-wifi', { opacity: 1 }, 15.5);
  cam(DW, B.punch, [0.545, 0.76, 0.40, 0.145], 15.5, 0);
  at('#d-wifi', { x: '-=60', duration: 2.1, ease: 'none' }, 15.55);
  ft('#cap-ask', { opacity: 0, y: 40, scale: 0.94 }, { opacity: 1, y: 0, scale: 1, duration: 0.5, ease: 'back.out(1.6)' }, 16.1);
  at('#cap-ask', { opacity: 0, y: 30, duration: 0.25, ease: 'power2.in' }, 17.5);
  cam(DW, B.punch, [0.0, 0.0, 0.33, 0.2], 17.6, 0.85, 'power3.inOut');
  smear('#d-wifi', 17.6, 0.85, 9);
  cam(DW, B.punch, [0.0, 0.0, 0.30, 0.18], 18.45, 2.0, 'none');
  ft('#crumbs', { opacity: 0, y: -40 }, { opacity: 1, y: 0, duration: 0.45, ease: 'back.out(1.6)' }, 18.3);
  function crumb(i, t) { at('#cr' + i, { color: '#F5F5F7', duration: 0.2 }, t); ft('#cr' + i + ' .cdot', { scale: 0.4, backgroundColor: 'rgba(191,90,242,0)' }, { scale: 1, backgroundColor: 'rgba(191,90,242,1)', duration: 0.35, ease: 'back.out(3)' }, t); }
  crumb(0, 18.7);
  cam(DW, B.punch, [0.0, 0.0, 0.47, 0.37], 20.7, 0.65, 'power3.inOut');
  cam(DW, B.punch, [0.0, 0.0, 0.45, 0.35], 21.3, 1.2, 'none');
  crumb(1, 21.08);
  cam(DW, B.punch, [0.28, 0.0, 0.74, 0.86], 22.5, 0.85, 'power3.inOut');
  smear('#d-wifi', 22.5, 0.85, 4);
  ftl('#d-wifi .tilt', { rotationX: 0 }, { rotationX: 9, duration: 0.38, ease: 'sine.inOut', yoyo: true, repeat: 1, transformPerspective: 2400 }, 22.55);
  cam(DW, B.punch, [0.30, 0.0, 0.70, 0.82], 23.3, 1.35, 'none');
  cam(DW, B.punch, [0.30, 0.21, 0.37, 0.24], 24.6, 0.62, 'power3.inOut');
  smear('#d-wifi', 24.6, 0.62, 5);
  crumb(2, 25.13);
  cam(DW, B.punch, [0.46, 0.025, 0.37, 0.19], 25.85, 0.62, 'power3.inOut');
  smear('#d-wifi', 25.85, 0.62, 5);
  cam(DW, B.punch, [0.47, 0.035, 0.34, 0.17], 26.45, 1.2, 'none');
  at('#crumbs', { boxShadow: '0 0 0 3px rgba(191,90,242,1), 0 30px 80px -30px rgba(0,0,0,.8)', duration: 0.25, yoyo: true, repeat: 1 }, 25.95);
  ft('#cap-off', { opacity: 0, y: 40, scale: 0.94 }, { opacity: 1, y: 0, scale: 1, duration: 0.45, ease: 'back.out(1.6)' }, 26.2);
  rise('#cap-off .w', 26.25, { st: 0.09 });
  at('#crumbs', { opacity: 0, y: -30, duration: 0.25, ease: 'power2.in' }, CROUT);
  at('#cap-off', { opacity: 0, y: 30, duration: 0.25, ease: 'power2.in' }, 27.6);
  whipOut(DW, 27.58, -1);

  // ================= 5 · Montage (27.65–38.0) =================
  var MB = B.side;
  set('#r-mont', { clipPath: inset(MB, 34) }, 27.6);
  ft('#mframe', { opacity: 0, scale: 1.08 }, { opacity: 1, scale: 1, duration: 0.5, ease: 'expo.out' }, 27.78);
  var M = [
    { d: D('#d-m1'), r: [0.30, 0.06, 0.46, 0.25], t: 27.8 },
    { d: D('#d-m2'), r: [0.14, 0.17, 0.66, 0.70], t: 29.65 },
    { d: D('#d-m3'), r: [0.60, 0.57, 0.40, 0.31], t: 31.65 },
    { d: D('#d-m4', true), r: [0, 0.02, 1, 0.5], t: 33.65 },
    { d: D('#d-m5', true), r: [0, 0.02, 1, 0.5], t: 35.65 },
  ];
  M.forEach(function (m, i) {
    var v = fit(MB, m.r, m.d.cw, m.d.ch);
    whipIn(m.d, v, m.t, 1);
    // a slow push while it plays
    var r2 = [m.r[0] + m.r[2] * 0.03, m.r[1] + m.r[3] * 0.03, m.r[2] * 0.94, m.r[3] * 0.94];
    cam(m.d, MB, r2, m.t + 0.42, 1.55, 'none');
    var next = i < 4 ? M[i + 1].t : 0;
    if (i < 4) whipOut(m.d, next, -1);
    var ml = '#ml' + i;
    rise(ml + ' .big .w', m.t + 0.3, { st: 0.06 });
    rise(ml + ' .sub .w', m.t + 0.45, { st: 0.03, d: 0.5 });
    if (i < 4) sink(ml + ' .w', next - 0.15, { st: 0.012, d: 0.26 });
  });
  cam(M[3].d, MB, [0, 0, 1, 1], 35.0, 0.55, 'expo.inOut'); // pull back: show the rotated photo
  sink('#ml4 .w', 37.7, { st: 0.012, d: 0.26 });
  at('#mframe', { opacity: 0, scale: 0.6, duration: 0.34, ease: 'power3.in' }, 37.78);
  at('#d-m5', { scale: '*=0.5', opacity: 0, x: '+=' + (B.side.w * 0.25), y: '+=' + (B.side.h * 0.25), duration: 0.34, ease: 'power3.in' }, 37.78);

  // grid: pull back into all the jobs we just saw
  ft('#grid', { scale: 1.6, rotation: -2 }, { scale: 1, rotation: 0, duration: 1.1, ease: 'expo.out', transformOrigin: '50% 55%' }, 37.86);
  at('#grid', { scale: 1.03, duration: 1.9, ease: 'none', transformOrigin: '50% 55%' }, 39.0);
  $$('.tile').forEach(function (el, i) {
    var o = [2, 0, 4, 1, 3, 5][i];
    ft(el, { opacity: 0, scale: 0.55, y: 60 }, { opacity: 1, scale: 1, y: 0, duration: 0.6, ease: 'back.out(1.5)' }, 37.88 + o * 0.06);
  });
  rise('#gh .w', 38.2, { st: 0.09 });
  rise('#gsub .w', 38.5, { st: 0.03, d: 0.5 });
  at('#grid', { opacity: 0, scale: 0.9, filter: 'blur(14px)', duration: 0.3, ease: 'power2.in' }, 40.3);
  sink('#gh .w, #gsub .w', 40.25, { st: 0.01 });

  // ================= 6 · Numbers (40.4–46.5) =================
  rise('#nlab .w', 40.5, { st: 0.04, d: 0.5 });
  rise('#nbase .w', 40.62, {});
  at('#nbase', { y: -150, scale: 0.42, opacity: 0.5, duration: 0.5, ease: 'expo.inOut', transformOrigin: '50% 50%' }, 41.2);
  at('#nlab', { opacity: 0, duration: 0.2 }, 41.2);
  ft('#nours', { opacity: 0, scale: 0.6, filter: 'blur(16px)' }, { opacity: 1, scale: 1, filter: 'blur(0px)', duration: 0.55, ease: 'expo.out', transformOrigin: '50% 50%' }, 41.3);
  for (var n = 9; n <= 29; n++) set('#nval', { textContent: n }, 41.3 + (n - 8) / 21 * 0.75);
  ft('#nours', { scale: 1 }, { scale: 1.08, duration: 0.18, yoyo: true, repeat: 1, ease: 'power2.out', immediateRender: false }, 42.05);
  ft('#nourlab', { opacity: 0, y: 20 }, { opacity: 1, y: 0, duration: 0.4, ease: 'power3.out' }, 41.6);
  at(['#nbase', '#nours', '#nourlab'], { opacity: 0, y: '-=60', filter: 'blur(12px)', duration: 0.28, ease: 'power2.in' }, 42.35);
  [29, 33, 35].forEach(function (v, i) {
    var t = 42.72 + i * 0.2, row = '#b' + i;
    ft(row, { opacity: 0, x: -80 }, { opacity: 1, x: 0, duration: 0.5, ease: 'expo.out' }, t);
    ft(row + ' .bfill', { scaleX: 0 }, { scaleX: v / 35, duration: 0.9, ease: 'expo.out' }, t + 0.1);
    for (var k = 0; k <= 10; k++) set(row + ' .bval', { textContent: Math.round(v * k / 10) }, t + 0.1 + k * 0.06);
  });
  ft('#b0', { scale: 1 }, { scale: 1.03, duration: 0.2, yoyo: true, repeat: 1, ease: 'power2.out', immediateRender: false, transformOrigin: '0% 50%' }, 43.9);
  at('#bars', { opacity: 0, y: -50, filter: 'blur(12px)', duration: 0.28, ease: 'power2.in' }, 44.32);
  rise('#c1 .w', 44.7, {});
  rise('#c2 .w', 45.25, {});
  ft('#c2', { scale: 1.1 }, { scale: 1, duration: 1.2, ease: 'expo.out', transformOrigin: '50% 50%' }, 45.25);
  sink('#c1 .w, #c2 .w', 46.25, { st: 0.02 });

  // ================= 7 · Tagline (46.4–52.0) =================
  rise('#tg1 .w', 46.5, { st: 0.1 });
  var tp = pos($('#tg1w-1')), tpad = 18;
  var trr = { x: tp.x - tpad, y: tp.y - tpad * 0.4, w: tp.w + tpad * 2, h: tp.h + tpad * 0.9 };
  ['x', 'y', 'w', 'h'].forEach(function (k) { $('#tring').setAttribute(k === 'w' ? 'width' : k === 'h' ? 'height' : k, trr[k]); });
  ft('#tring', { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.45, ease: 'power2.inOut' }, 46.8);
  rise('#tg2 .w', 47.15, { st: 0.1 });
  var tc = pos($('#tg2w-1'));
  ft('#tcur', { opacity: 0, x: W * 0.95, y: H * 0.98 }, { opacity: 1, x: tc.cx - 6, y: tc.cy - 4, duration: 0.45, ease: 'power3.out' }, 47.2);
  ft('#tcur svg', { scale: 1 }, { scale: 0.8, duration: 0.08, yoyo: true, repeat: 1, ease: 'power2.out', transformOrigin: '20% 15%' }, 47.62);
  ft('#ripple', { opacity: 0.9, scale: 0.3 }, { opacity: 0, scale: 2.4, duration: 0.45, ease: 'power2.out' }, 47.66);
  at('#tg2w-1', { color: '#BF5AF2', duration: 0.15 }, 47.66);
  sink('#tg1 .w, #tg2 .w', 47.8, { st: 0.02 });
  at(['#tring', '#tcur'], { opacity: 0, duration: 0.2 }, 47.8);
  rise('#tg3 .w', 48.1, { st: 0.08, d: 0.7 });
  $$('.chip').forEach(function (c, i) { ft(c, { opacity: 0, y: 34, scale: 0.8 }, { opacity: 1, y: 0, scale: 1, duration: 0.5, ease: 'back.out(2)' }, 49.2 + i * 0.32); });
  at('.chip', { opacity: 0, y: -24, duration: 0.25, ease: 'power2.in', stagger: 0.04 }, 51.5);
  ft('#tg3', { scale: 1.12, filter: 'blur(0px)' }, { scale: 1, duration: 3.6, ease: 'power2.out', transformOrigin: '50% 50%' }, 48.0);
  sink('#tg3 .w', 51.5, { st: 0.03 });

  // ================= 8 · End card (51.9–60) =================
  var DH = D('#d-hero');
  var hv = fit(B.hero, [0, 0, 1, 1], 1920, 1248);
  ft('#d-hero', { opacity: 0, x: hv.x - 150, y: hv.y + 30, scale: hv.scale * 0.94 }, { opacity: 1, x: hv.x, y: hv.y, scale: hv.scale, duration: 1.1, ease: 'expo.out' }, 51.95);
  ft('#d-hero .tilt', { rotationY: 22, rotationX: 4 }, { rotationY: 12, rotationX: 2, duration: 1.1, ease: 'expo.out', transformPerspective: 2600 }, 51.95);
  at('#d-hero .tilt', { rotationY: 5, rotationX: 0, duration: 7.0, ease: 'none' }, 52.92);
  // logo builds the way Gabay works: steps lead to the ring
  ft('#logo', { opacity: 0, scale: 0.5, rotation: -10 }, { opacity: 1, scale: 1, rotation: 0, duration: 0.65, ease: 'back.out(1.7)' }, 52.0);
  $$('.ldot').forEach(function (d, i) { var r = +d.getAttribute('r'); ft(d, { attr: { r: 0 } }, { attr: { r: r }, duration: 0.3, ease: 'back.out(3)' }, 52.25 + i * 0.08); });
  ft('#lring', { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.45, ease: 'power2.inOut' }, 52.55);
  ft('#lhalo', { opacity: 0, attr: { r: 30 } }, { opacity: 1, attr: { r: 44 }, duration: 0.55, ease: 'expo.out' }, 52.95);
  ftl('#lhalo', { attr: { r: 44 } }, { attr: { r: 48 }, duration: 0.9, ease: 'sine.inOut', yoyo: true, repeat: 5 }, 53.5);
  ft('#wm .c', { opacity: 0, x: -50, filter: 'blur(10px)' }, { opacity: 1, x: 0, filter: 'blur(0px)', duration: 0.45, ease: 'expo.out', stagger: 0.05 }, 52.3);
  rise('#edesc .w', 52.6, { st: 0.05, d: 0.5 });
  ft('#ebar', { opacity: 0, scale: 0.9, y: 30 }, { opacity: 1, scale: 1, y: 0, duration: 0.5, ease: 'back.out(1.6)' }, 53.2);
  ft('#ego', { scale: 0 }, { scale: 1, duration: 0.35, ease: 'back.out(2.5)' }, 53.3);
  at('#ebartxt .ch', { opacity: 1, duration: 0.01, stagger: 0.03, ease: 'none' }, 53.45);
  var tw = $('#ebartxt').offsetWidth;
  ft('#ecaret', { x: -tw }, { x: 0, duration: ${(URL_TEXT.length * 0.03).toFixed(2)}, ease: 'steps(${URL_TEXT.length})' }, 53.45);
  ftl('#ecaret', { opacity: 1 }, { opacity: 0.1, duration: 0.3, repeat: 7, yoyo: true, ease: 'none' }, 54.6);
  ft('#ego', { scale: 1 }, { scale: 1.12, duration: 0.2, repeat: 5, yoyo: true, ease: 'sine.inOut', immediateRender: false }, 54.75);
  ft('#efoot', { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.45, ease: 'power3.out' }, 54.9);

  window.__timelines['main'] = tl;
  if (window.__hfForceTimelineRebind) window.__hfForceTimelineRebind();
});
</script>
</body>
</html>
`;
}

for (const name of (process.env.ONLY ? [process.env.ONLY] : Object.keys(FORMATS))) {
  const F = FORMATS[name];
  const dir = path.join(HERE, F.dir);
  fs.mkdirSync(dir, { recursive: true });
  // assets: one shared copy, linked per composition
  const link = path.join(dir, 'assets');
  fs.cpSync(path.join(HERE, 'shared-assets'), link, { recursive: true, force: true });
  fs.writeFileSync(path.join(dir, 'index.html'), page(F));
  fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: `gabay-launch-${name}`, private: true, type: 'module', scripts: { build: 'node ../build.mjs', check: `npx --yes hyperframes@${VER} check`, render: `npx --yes hyperframes@${VER} render` } }, null, 2) + '\n');
}
console.log(`built ${END}s · ${audio.length} sfx · ${VO.length} voice lines`);
