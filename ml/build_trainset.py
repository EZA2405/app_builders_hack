"""Build Laya fine-tuning data from teacher-written goals + real app menus.

Inputs:
  <dumps>/<app>.json          ScreenGuide --dump snapshots of TRAINING apps (never the held-out test apps)
  data/goals/<app>.jsonl      teacher goals: {"goal": str, "answer": "Menu > Item", "alts": [..]}
Output:
  data/train.jsonl, data/val.jsonl   Laya rows: {state, questions: {next_command: choice over 16}, expected}

Each goal becomes several rows with different 16-option groups (the answer plus hard
negatives: same-menu siblings, word-overlap neighbours, random), mirroring the 16-wide
tournament used at inference.

Usage: python3 build_trainset.py /tmp/sg/train
"""
import glob, json, os, random, re, sys
from make_fixtures import is_personal, redact_names

HELD_OUT = {"preview", "finder", "systemsettings", "safari"}
GROUP = 16
VARIANTS = 3

def state_for(app, goal):
    # Must match bench_localjev.ask() exactly.
    return f"A non-technical person is using the Mac app {app}. Their goal: \"{goal}\""

def instructions_for(app):
    return f"Which {app} menu command accomplishes the person's goal?"

def words(s):
    return set(re.findall(r"[a-z]+", s.lower())) - {"the", "a", "to", "of", "and", "in", "on", "for", "as"}

def negatives(answer, ok, commands, rng):
    top = answer.split(" > ")[0]
    pool = [c for c in commands if c not in ok]
    siblings = [c for c in pool if c.startswith(top + " >")]
    aw = words(answer)
    overlap = sorted(pool, key=lambda c: -len(aw & words(c)))[:20]
    picks = rng.sample(siblings, min(5, len(siblings))) + rng.sample(overlap, min(5, len(overlap)))
    rest = [c for c in pool if c not in picks]
    picks += rng.sample(rest, min(GROUP - 1 - len(picks), len(rest)))
    return list(dict.fromkeys(picks))[:GROUP - 1]

def main(dumps):
    rng = random.Random(7)
    # Consistency filter: drop goals where hosted Jev disagreed with the teacher label (ambiguous goals).
    skip = set(json.load(open("data/disagreements.json"))) if os.path.exists("data/disagreements.json") else set()
    rows, stats = [], {}
    for path in sorted(glob.glob("data/goals/*.jsonl")):
        name = os.path.basename(path)[:-6]
        if name in HELD_OUT:
            raise SystemExit(f"refusing to train on held-out app {name}")
        snap = json.load(open(os.path.join(dumps, f"{name}.json")))
        app = snap["app"]
        commands = list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))
        cmdset = set(commands)
        kept = bad = 0
        for line in open(path):
            if not line.strip():
                continue
            g = json.loads(line)
            if g["goal"] in skip:
                continue
            ok = [a for a in [g["answer"], *g.get("alts", [])] if a in cmdset]
            if g["answer"] not in cmdset:
                bad += 1
                continue
            for _ in range(VARIANTS):
                opts = [g["answer"], *negatives(g["answer"], set(ok), commands, rng)]
                rng.shuffle(opts)
                rows.append({
                    "app": name,
                    "state": state_for(app, g["goal"]),
                    "questions": {"next_command": {"type": "choice", "instructions": instructions_for(app),
                                                   "criteria": {c: c for c in opts}}},
                    "expected": {"next_command": g["answer"]},
                })
            kept += 1
        stats[name] = (kept, bad)
    # Validation split by APP, so val also measures cross-app generalization.
    apps = sorted(stats)
    val_apps = set(apps[::6])
    os.makedirs("data", exist_ok=True)
    with open("data/train.jsonl", "w") as tr, open("data/val.jsonl", "w") as va:
        for r in rows:
            (va if r.pop("app") in val_apps else tr).write(json.dumps(r, ensure_ascii=False) + "\n")
    for k, (kept, bad) in stats.items():
        print(f"{k:16s} goals {kept:4d}  rejected (answer not a real command) {bad}")
    print("val apps:", sorted(val_apps), "| rows:", len(rows))

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/sg/train")
