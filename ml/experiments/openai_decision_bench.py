"""Goal -> command benchmark against OpenAI's Decisions API (POST /v1/decisions, gpt-6-luna). Cloud comparison only.

Same task and wording as bench_localjev.py (hosted Jev): one `choice` question over the app's real
command list. The API takes 2-255 choices, so longer lists run the same 200-wide tournament as the Jev run.
Cost is computed from the returned usage.input_tokens at the Decisions list price (input only, $0.10 / 1M).

Privacy: send ONLY sanitized fixtures (built by make_fixtures.py: is_personal + redact_names) or public pages.
--vision captures its own screenshot of a public URL in a fresh, logged-out headless Chrome profile; it never
sends a screenshot of this Mac. Terms: OpenAI's Services Agreement 3.3(e) forbids using Output to develop models
that compete with OpenAI, so these answers are for benchmarking only. Never feed them into Laya training data.

Usage (from ml/, needs OPENAI_API_KEY in ml/.env; stdlib only):
  python3 experiments/openai_decision_bench.py --fixture fixtures/val/activitymonitor.json
  python3 experiments/openai_decision_bench.py --fixture fixtures/preview_real.json   # held-out: run once, report it
  python3 experiments/openai_decision_bench.py --vision /tmp/sg/web/wikiportal.json --goal "..." --expect '<element>' --expect-region <cell>
    (the page JSON comes from: python web/crawl.py <sites.txt> /tmp/sg/web, which also uses a fresh profile)
"""
import argparse, base64, json, os, re, statistics, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request

ML = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ML)
from bench_localjev import load_dotenv          # noqa: E402
from make_fixtures import redact_names          # noqa: E402

URL = "https://api.openai.com/v1/decisions"
USD_PER_INPUT_TOKEN = 0.10 / 1e6                 # Decisions pricing: input tokens only, no output/cache charges
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# Last line of defence: fixtures are already sanitized, but refuse to send anything that still looks personal.
PERSONAL = re.compile(r"@|/Users/|[’']s (iPhone|iPad|Mac|MacBook|Apple Watch|AirPods)\b| — |\.(pdf|png|jpe?g|heic|docx?|xlsx?|pages|key|mov|mp4|txt|zip)\b", re.I)
SPENT = {"tokens": 0, "calls": 0}


def scrub(text):
    """Error bodies can echo a masked API key; never let any part of it reach the terminal."""
    return re.sub(r"sk-[A-Za-z0-9_\-*.]+", "sk-[redacted]", text)


def post(body, key, budget):
    est = len(json.dumps(body)) // 3                     # rough pre-flight token estimate for the spend guard
    if (SPENT["tokens"] + est) * USD_PER_INPUT_TOKEN > budget:
        raise SystemExit(f"stopping: next call would pass the ${budget:.2f} budget")
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    t = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            res = json.load(r)
    except urllib.error.HTTPError as e:                  # stop on errors: no retries that could burn budget
        raise SystemExit(f"HTTP {e.code}: {scrub(e.read()[:400].decode('utf-8', 'replace'))}")
    dt = time.perf_counter() - t
    SPENT["tokens"] += (res.get("usage") or {}).get("input_tokens", 0)
    SPENT["calls"] += 1
    return res, dt


def state_for(app, goal, done=None):
    state = f"A non-technical person is using the Mac app {app}. Their goal: \"{goal}\""   # = bench_localjev.ask
    if done:
        state += " Already done: " + "; ".join(done) + "."
    return state


def parse(res, name):
    a = next((x for x in res.get("answers", []) if x.get("name") == name), {})
    if a.get("type") != "choice":                        # refusal or missing answer
        return None, None, {}
    probs = {p["value"]: p["probability"] for p in a.get("probabilities", [])}
    return a.get("choice"), a.get("confidence"), probs


def ask(model, app, commands, goal, key, budget, done=None):
    body = {"model": model, "input": state_for(app, goal, done), "questions": [{
        "type": "choice", "name": "next_command",
        "instructions": f"Which {app} menu command accomplishes the person's goal?",
        "choices": [{"value": c} for c in commands]}]}
    res, dt = post(body, key, budget)
    return (*parse(res, "next_command"), dt, res)


def choose(model, app, commands, goal, key, budget, limit=200, keep=3, done=None):
    """Same tournament as bench_localjev.choose: chunks of `limit`, top `keep` per chunk, then a final round."""
    if len(commands) <= limit:
        choice, conf, probs, dt, res = ask(model, app, commands, goal, key, budget, done)
        return choice, conf, probs, dt, 1, res
    finalists, total, calls = [], 0.0, 0
    for i in range(0, len(commands), limit):
        chunk = commands[i:i + limit]
        if len(chunk) < 2:                               # the API needs at least 2 choices
            finalists += chunk
            continue
        _, _, probs, dt, _ = ask(model, app, chunk, goal, key, budget, done)
        total += dt
        calls += 1
        finalists += sorted(probs, key=probs.get, reverse=True)[:keep]
    choice, conf, probs, dt, n, res = choose(model, app, finalists, goal, key, budget, limit, keep, done)
    return choice, conf, probs, total + dt, calls + n, res


def bench(a, key):
    fx = json.load(open(a.fixture))
    if "steps" in fx:
        cases = [(s["goal"], set(s["ok"]), s["app"], s["commands"], s.get("done")) for s in fx["steps"]]
    else:
        cases = [(g, set(ok), fx["app"], fx["commands"], None) for g, ok in fx["goals"].items()]
    cases = cases[:a.limit] if a.limit else cases
    for _, _, app, commands, done in cases:
        bad = [c for c in commands + (done or []) if PERSONAL.search(c) or redact_names(c) != c]
        if bad:
            raise SystemExit(f"refusing to send {len(bad)} unsanitized entries (e.g. {bad[0][:60]!r}); rebuild the fixture")
    hits, times, calls = 0, [], 0
    for goal, ok, app, commands, done in cases:
        choice, conf, probs, dt, n, res = choose(a.model, app, commands, goal, key, a.max_usd, a.group, done=done)
        good = choice in ok
        hits += good
        times.append(dt)
        calls += n
        top = probs.get(choice)
        print(f"{'OK ' if good else 'BAD'} {dt:5.2f}s conf={conf} p={top} | {goal} -> {choice}", flush=True)
        if choice is None:
            print("   raw response:", json.dumps(res)[:500])
    print(f"\n{fx['app']}: accuracy {hits}/{len(cases)}  median latency {statistics.median(times):.2f}s per decision "
          f"({calls} calls)  input tokens {SPENT['tokens']}  cost ${SPENT['tokens'] * USD_PER_INPUT_TOKEN:.4f}")


def screenshot(url, w=1440, h=900):
    """Public page only, rendered off-screen in a brand-new Chrome profile (no logins, cookies or history)."""
    host = urllib.parse.urlparse(url).hostname or ""
    if not url.startswith("https://") or host in ("localhost", "127.0.0.1", "::1") or host.endswith((".local", ".localhost", ".test")):
        raise SystemExit(f"--vision only sends public https pages, not {url!r}")
    profile, out = tempfile.mkdtemp(prefix="sg-chrome-"), os.path.join(tempfile.mkdtemp(prefix="sg-shot-"), "page.png")
    proc = subprocess.Popen([CHROME, "--headless=new", f"--user-data-dir={profile}", "--no-first-run", "--no-default-browser-check",
                             "--hide-scrollbars", f"--window-size={w},{h}", "--virtual-time-budget=8000", f"--screenshot={out}", url],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:   # headless Chrome writes the PNG but doesn't always exit, so wait for the file instead of the process
        for _ in range(120):
            if os.path.exists(out) and os.path.getsize(out) > 0:
                time.sleep(1)
                return out
            time.sleep(0.5)
        raise SystemExit("screenshot timed out")
    finally:
        proc.terminate()


GRID = [(r, c) for r in ("top", "middle", "bottom") for c in ("left", "center", "right")]


def vision(a, key):
    page = json.load(open(a.vision))
    png = screenshot(page["url"])
    print(f"screenshot of {page['url']} (fresh headless profile): {png}")
    els = [e for e in page["elements"] if e.get("in_viewport") and e.get("name")]
    labels = list(dict.fromkeys(f'{e["role"]} "{e["name"]}"' for e in els))[:255]
    w, h = 1440, 900
    cells = [{"value": f"{r} {c}", "description": f"x {w * j // 3}-{w * (j + 1) // 3} px, y {h * i // 3}-{h * (i + 1) // 3} px"}
             for i, r in enumerate(("top", "middle", "bottom")) for j, c in enumerate(("left", "center", "right"))]
    img = "data:image/png;base64," + base64.b64encode(open(png, "rb").read()).decode()
    body = {"model": a.model, "input": [{"role": "user", "content": [
        {"type": "input_text", "text": state_for("Google Chrome", a.goal) + f" The screenshot ({w}x{h} px) is the web page they are looking at."},
        {"type": "input_image", "image_url": img}]}],
        "questions": [
            {"type": "choice", "name": "element", "instructions": "Which control on this page should they click next?",
             "choices": [{"value": v} for v in labels]},
            {"type": "choice", "name": "region", "instructions": "In which part of the screenshot is the control they should click next?",
             "choices": cells}]}
    res, dt = post(body, key, a.max_usd)
    for q, exp in (("element", a.expect), ("region", a.expect_region)):
        choice, conf, probs = parse(res, q)
        top3 = sorted(probs.items(), key=lambda kv: -kv[1])[:3]
        mark = "" if exp is None else ("OK  " if choice == exp else "BAD ")
        print(f"{mark}{q}: {choice!r} conf={conf} top3={top3}")
    print(f"{dt:.2f}s, {len(labels)} element choices, input tokens {SPENT['tokens']}, cost ${SPENT['tokens'] * USD_PER_INPUT_TOKEN:.5f}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--fixture")
    p.add_argument("--model", default="gpt-6-luna")
    p.add_argument("--group", type=int, default=200, help="max options per call (API cap is 255; Jev run used 200)")
    p.add_argument("--limit", type=int, help="only the first N goals (smoke test)")
    p.add_argument("--max-usd", type=float, default=0.50, help="stop before spending more than this")
    p.add_argument("--vision", help="page JSON from web/crawl.py (public URL); screenshot is taken fresh here")
    p.add_argument("--goal")
    p.add_argument("--expect", help="expected element label, written before running")
    p.add_argument("--expect-region", help="expected grid cell, e.g. 'middle center'")
    a = p.parse_args()
    load_dotenv()
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        raise SystemExit("set OPENAI_API_KEY in ml/.env")
    vision(a, key) if a.vision else bench(a, key)


if __name__ == "__main__":
    main()
