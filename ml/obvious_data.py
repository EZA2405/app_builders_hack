"""'Pick the obvious route' rows: every option group contains the goal's decoys (commands that could
technically do it the long way), so the model learns the beginner-expected command wins.
Hosted Jev double-checks each label; goals where Jev confidently (>0.85) prefers a decoy are dropped.
Sanitized menus + synthetic goals only.   Usage: python3 obvious_data.py out.jsonl
"""
import concurrent.futures as cf, glob, json, os, random, sys, urllib.request
from bench_localjev import load_dotenv
from build_trainset import HELD_OUT, VAL_APPS, GROUP, state_for, instructions_for, load_snapshot, negatives
from make_fixtures import is_personal, redact_names

DUMPS = ["/tmp/sg/train", "/tmp/sg/train2"]

def row(app, goal, opts, answer):
    return {"state": state_for(app, goal),
            "questions": {"next_command": {"type": "choice", "instructions": instructions_for(app), "criteria": {c: c for c in opts}}},
            "expected": {"next_command": answer}}

def group(ans, decoys, cmds, rng):
    opts = [ans, *decoys]
    opts += [c for c in negatives(ans, set(opts), cmds, rng) if c not in opts][:GROUP - len(opts)]
    rng.shuffle(opts)
    return opts

def jev_top(r, key):
    body = {"model": "jev-latest", "state": r["state"], "questions": r["questions"]}
    req = urllib.request.Request("https://api.typesafe.ai/v1/systemone", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    try:
        p = json.load(urllib.request.urlopen(req, timeout=90)).get("answers", {}).get("next_command", {}).get("probabilities") or {}
        top = max(p, key=p.get) if p else None
        return top, (p.get(top, 0) if top else 0)
    except Exception:
        return None, 0

def main(out):
    load_dotenv(); key = os.environ["JEV_API_KEY"]
    rng = random.Random(41)
    items = []
    for p in sorted(glob.glob("data/goals_obvious/*.jsonl")):
        n = os.path.basename(p)[:-6]
        if n in HELD_OUT or n in VAL_APPS: continue
        snap = load_snapshot(DUMPS, n)
        if not snap: continue
        cmds = list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))
        cs = set(cmds)
        for l in open(p):
            if not l.strip(): continue
            g = json.loads(l)
            decoys = [d for d in g.get("decoys", []) if d in cs and d != g["answer"]]
            if g["answer"] in cs and decoys:
                items.append((snap["app"], cmds, g["goal"], g["answer"], decoys))
    checks = [row(a, g, group(ans, d, c, rng), ans) for a, c, g, ans, d in items]
    with cf.ThreadPoolExecutor(8) as ex:
        verdicts = list(ex.map(lambda r: jev_top(r, key), checks))
    kept = dropped = agree = 0
    with open(out, "w") as f:
        for (app, cmds, goal, ans, decoys), (top, p) in zip(items, verdicts):
            agree += top == ans
            if top in decoys and p > 0.85:
                dropped += 1; continue
            kept += 1
            for _ in range(3):
                f.write(json.dumps(row(app, goal, group(ans, decoys, cmds, rng), ans), ensure_ascii=False) + "\n")
    print(f"{len(items)} obvious-route goals; Jev agreed on {agree}; dropped {dropped}; kept {kept} x3 -> {out}")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/v6/obvious.jsonl")
