"""Build Laya fine-tuning data from teacher-written goals + real app menus.

Inputs:
  <dumps>/<app>.json          ScreenGuide --dump snapshots of TRAINING apps (never the held-out test apps)
  data/goals/<app>.jsonl      teacher goals: {"goal": str, "answer": "Menu > Item", "alts": [..]}
Output:
  data/train.jsonl, data/val.jsonl   Laya rows: {state, questions: {next_command: choice over 16}, expected}

Each goal becomes several rows with different 16-option groups (the answer plus hard
negatives: same-menu siblings, word-overlap neighbours, random), mirroring the 16-wide
tournament used at inference.

Usage: python3 build_trainset.py [--v1] [--out data/v2] DUMP_DIR [DUMP_DIR ...]
  --v1  original 3 random hard-negative groups per goal (data/train.jsonl was built this way)
  default: 2 random groups + in-order menu chunk + 'final round' group per goal
"""
import glob, json, os, random, re, sys
from make_fixtures import is_personal, redact_names

HELD_OUT = {"preview", "finder", "systemsettings", "safari"}
VAL_APPS = {"activitymonitor", "diskutility", "numbers", "terminal"}
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

def tournament_rows(goal, answer, ok, commands, rng):
    """Option groups shaped like inference: the in-order menu chunk holding the answer, and a
    'final round' of the strongest distractors (word overlap with the goal and the answer)."""
    others = [c for c in commands if c not in ok]
    groups = []
    i = commands.index(answer) // GROUP * GROUP
    groups.append([c for c in commands[i:i + GROUP] if c == answer or c not in ok])
    gw, aw, top = words(goal), words(answer), answer.split(" > ")[0]
    by_goal = sorted(others, key=lambda c: -len(gw & words(c)))[:8]
    by_ans = [c for c in sorted(others, key=lambda c: -len(aw & words(c))) if c not in by_goal][:4]
    sib = [c for c in others if c.startswith(top + " >") and c not in by_goal + by_ans]
    final = by_goal + by_ans + rng.sample(sib, min(3, len(sib)))
    rest = [c for c in others if c not in final]
    final += rng.sample(rest, max(0, GROUP - 1 - len(final)))
    groups.append([answer, *final[:GROUP - 1]])
    return groups

def load_snapshot(dumps, name):
    for d in dumps:
        p = os.path.join(d, f"{name}.json")
        if os.path.exists(p):
            d = json.load(open(p))
            if "error" not in d and d.get("commands"):
                return d
    return None

def main(dumps, out_dir="data", tournament=True):
    rng = random.Random(7)
    # Consistency filter: drop goals where hosted Jev disagreed with the teacher label (ambiguous goals).
    skip = set(json.load(open("data/disagreements.json"))) if os.path.exists("data/disagreements.json") else set()
    rows, stats = [], {}
    for path in sorted(glob.glob("data/goals/*.jsonl")) + sorted(glob.glob("data/goals_traps/*.jsonl")) + sorted(glob.glob("data/goals_para/*.jsonl")):
        name = os.path.basename(path)[:-6]
        if name in HELD_OUT:
            raise SystemExit(f"refusing to train on held-out app {name}")
        snap = load_snapshot(dumps, name)
        if snap is None:
            print(f"{name:16s} no menu dump found, skipped")
            continue
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
            groups = [[g["answer"], *negatives(g["answer"], set(ok), commands, rng)] for _ in range(VARIANTS)]
            if tournament:
                groups = groups[:2] + tournament_rows(g["goal"], g["answer"], set(ok), commands, rng)
            for opts in groups:
                rng.shuffle(opts)
                rows.append({
                    "app": name,
                    "state": state_for(app, g["goal"]),
                    "questions": {"next_command": {"type": "choice", "instructions": instructions_for(app),
                                                   "criteria": {c: c for c in opts}}},
                    "expected": {"next_command": g["answer"]},
                })
            kept += 1
        prev = stats.get(name, (0, 0))
        stats[name] = (prev[0] + kept, prev[1] + bad)
    # Validation split by APP (fixed across versions so val numbers stay comparable).
    val_apps = VAL_APPS
    os.makedirs(out_dir, exist_ok=True)
    with open(f"{out_dir}/train.jsonl", "w") as tr, open(f"{out_dir}/val.jsonl", "w") as va:
        for r in rows:
            (va if r.pop("app") in val_apps else tr).write(json.dumps(r, ensure_ascii=False) + "\n")
    for k, (kept, bad) in stats.items():
        print(f"{k:16s} goals {kept:4d}  rejected (answer not a real command) {bad}")
    print("val apps:", sorted(val_apps), "| rows:", len(rows))

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("dumps", nargs="*", default=["/tmp/sg/train"])
    p.add_argument("--out", default="data/v2")
    p.add_argument("--v1", action="store_true")
    a = p.parse_args()
    main(a.dumps, a.out, tournament=not a.v1)
