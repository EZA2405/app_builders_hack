"""Snapshot public web pages with headless Chrome for training/eval data.

Uses a FRESH temporary Chrome profile (no logins, cookies or history) and runs
ml/web/extract.js on each page via the Chrome DevTools Protocol.

Usage (needs the `websockets` package, e.g. the local-jev venv):
  python crawl.py sites.txt /tmp/sg/web
sites.txt: one "name url" per line.
"""
import asyncio, json, os, subprocess, sys, tempfile, time, urllib.request

import websockets

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT = 9333
JS = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "extract.js")).read()


async def snapshot(ws_url, url, settle=6.0):
    async with websockets.connect(ws_url, max_size=50_000_000) as ws:
        n = 0
        async def call(method, **params):
            nonlocal n
            n += 1
            mid = n
            await ws.send(json.dumps({"id": mid, "method": method, "params": params}))
            while True:
                msg = json.loads(await ws.recv())
                if msg.get("id") == mid:
                    return msg
        await call("Page.enable")
        await call("Emulation.setDeviceMetricsOverride", width=1440, height=900, deviceScaleFactor=1, mobile=False)
        await call("Page.navigate", url=url)
        await asyncio.sleep(settle)
        res = await call("Runtime.evaluate", expression=JS, returnByValue=True)
        return res.get("result", {}).get("result", {}).get("value")


def main(sites_file, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    profile = tempfile.mkdtemp(prefix="sg-chrome-")
    proc = subprocess.Popen([CHROME, "--headless=new", f"--remote-debugging-port={PORT}", f"--user-data-dir={profile}",
                             "--no-first-run", "--no-default-browser-check", "--window-size=1440,900", "about:blank"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(150):
            try:
                targets = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
                break
            except Exception:
                time.sleep(0.2)
        ws_url = next(t["webSocketDebuggerUrl"] for t in targets if t["type"] == "page")
        for line in open(sites_file):
            if not line.strip() or line.startswith("#"):
                continue
            name, url = line.split(None, 1)
            try:
                snap = asyncio.run(snapshot(ws_url, url.strip()))
                if not snap:
                    raise RuntimeError("no result")
                json.dump(snap, open(os.path.join(out_dir, f"{name}.json"), "w"), indent=1, ensure_ascii=False)
                print(f"{name}: {len(snap['elements'])} elements | {snap['title'][:60]}", flush=True)
            except Exception as e:
                print(f"{name}: FAILED {e}", flush=True)
    finally:
        proc.terminate()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
