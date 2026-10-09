"""Goal -> command accuracy benchmark against a local-jev server (POST /v1/systemone).

Usage: python3 bench_localjev.py [--url http://127.0.0.1:8765] [--model NAME] [--fixture fixtures/preview_menus.json]
Hosted Jev (comparison only, cloud): TYPESAFE_API_KEY=... python3 bench_localjev.py --url https://api.typesafe.ai
Stdlib only. Same 10 goals as bench_full_list.swift / bench_shortlist.swift for comparison.
"""
import argparse, json, os, statistics, time, urllib.error, urllib.request

# goal -> set of acceptable commands
GOALS = {
    "make this photo smaller so I can email it": {"Tools > Adjust Size…"},
    "turn the picture the right way up, it's sideways": {"Tools > Rotate Left", "Tools > Rotate Right", "Toolbar > Rotate"},
    "save a copy as a JPEG": {"File > Export As…", "File > Export…"},
    "black out my address on this picture": {"Tools > Redact"},
    "print this": {"File > Print…"},
    "cut out just my face from the picture": {"Tools > Crop", "Tools > Rectangular Selection"},
    "make a copy of this file": {"File > Duplicate"},
    "I want to draw a circle on the photo": {"Tools > Annotate > Oval", "Tools > Annotate", "Toolbar > Markup", "View > Show Markup Toolbar"},
    "where was this photo taken?": {"Tools > Show Location Info"},
    "make the picture bigger on my screen": {"View > Zoom In", "View > Enter Full Screen", "Toolbar > zoom in"},
}

def load_dotenv(path=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")):
    """Read KEY=VALUE lines from ml/.env (gitignored) into os.environ without overriding."""
    if os.path.exists(path):
        for line in open(path):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def ask(url, model, app, commands, goal, key=None):
    body = {
        "state": f"A non-technical person is using the Mac app {app}. Their goal: \"{goal}\"",
        "questions": {
            "next_command": {
                "type": "choice",
                "instructions": f"Which {app} menu command accomplishes the person's goal?",
                "criteria": {c: c for c in commands},
            }
        },
    }
    if model:
        body["model"] = model
    req = urllib.request.Request(url + "/v1/systemone", data=json.dumps(body).encode(), headers={"Content-Type": "application/json", **({"Authorization": f"Bearer {key}"} if key else {})})
    t = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            res = json.load(r)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code}: {e.read()[:300]!r}")
    dt = time.perf_counter() - t
    return res, dt

def answer(res):
    ans = res.get("answers", res).get("next_command", res) if isinstance(res, dict) else res
    return ans if isinstance(ans, dict) else {}

def choose(url, model, app, commands, goal, key, limit=200, keep=3):
    """Pick one command. Lists over the API's 255-choice cap run as a tournament:
    chunks of `limit`, keep the top `keep` per chunk by probability, then a final round."""
    if len(commands) <= limit:
        res, dt = ask(url, model, app, commands, goal, key)
        a = answer(res)
        return a.get("choice"), a.get("confidence"), dt, res
    finalists, total = [], 0.0
    for i in range(0, len(commands), limit):
        res, dt = ask(url, model, app, commands[i:i + limit], goal, key)
        total += dt
        probs = answer(res).get("probabilities") or {}
        finalists += sorted(probs, key=probs.get, reverse=True)[:keep]
    # Recurse until the finalists fit in one call (small groups, e.g. Laya's 16, need several rounds).
    choice, conf, dt, res = choose(url, model, app, finalists, goal, key, limit, keep)
    return choice, conf, total + dt, res

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--url", default="http://127.0.0.1:8765")
    p.add_argument("--model")
    p.add_argument("--fixture", default="fixtures/preview_real.json")
    p.add_argument("--group", type=int, default=200, help="max options per call (Laya: 16)")
    a = p.parse_args()
    load_dotenv()
    fx = json.load(open(a.fixture))
    hits, times = 0, []
    goals = {g: set(ok) for g, ok in fx["goals"].items()} if "goals" in fx else GOALS
    for goal, ok in goals.items():
        key = os.environ.get("TYPESAFE_API_KEY") or os.environ.get("JEV_API_KEY") or os.environ.get("LOCAL_JEV_API_KEY")
        choice, conf, dt, res = choose(a.url, a.model, fx["app"], fx["commands"], goal, key, limit=a.group)
        good = choice in ok
        hits += good
        times.append(dt)
        print(f"{'OK ' if good else 'BAD'} {dt:5.2f}s conf={conf} | {goal} -> {choice}")
        if choice is None:
            print("   raw response:", json.dumps(res)[:500])
    print(f"\n{fx['app']}: accuracy {hits}/{len(goals)}  median latency {statistics.median(times):.2f}s")

if __name__ == "__main__":
    main()
