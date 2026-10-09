"""v7 contrast rows for failures seen in live testing, taught as general concepts on TRAINING apps only.

Menu rows (data/goals_contrast/<app>.jsonl, {"type", "goal", "answer", "decoys"}):
  file_vs_view  "make this video small enough to send" -> File > Export As > 480p…  (decoy View > Zoom Out)
  view_vs_file  the reverse, so the model doesn't learn "smaller" always means Export
  lookalike     the goal's words appear in a wrong command, the right one is worded differently
Routing rows (data/goals_sysroute/system.jsonl + stay.jsonl), same request as Planner.pickApp:
  system jobs asked while a training app is in front -> "System Settings", with the app in front and
  look-alike apps as decoys; plus in-app goals with system-sounding words that should stay.
  System Settings is only an app NAME here (as in routing_data.py), never its menus or panes.

Every option group holds the goal's decoys. Hosted Jev double-checks one group per goal; goals where Jev
confidently (>0.85) picks something other than the label are dropped. Goals that are near-copies of any
test, validation or use-case goal are dropped before anything else. Sanitized menus + synthetic goals only.

Usage: python3 contrast_data.py [data/v7]   -> <out>/contrast.jsonl, <out>/sysroute.jsonl and
       <out>/train.jsonl = data/v6/train.jsonl + both (new rows already in v6 skipped), shuffled (seed 7).
"""
import concurrent.futures as cf, glob, json, os, random, re, sys
from collections import Counter
from bench_localjev import load_dotenv
from build_trainset import HELD_OUT, VAL_APPS, GROUP, load_snapshot
from make_fixtures import is_personal, redact_names
from obvious_data import DUMPS, row, group, jev_top
from routing_data import EXTRA

MENU_REPEAT, ROUTE_REPEAT, ROUTE_CONTEXTS = 3, 2, 3
STOP = {"the", "a", "an", "to", "of", "and", "in", "on", "for", "as", "my", "i", "it", "is", "this", "that", "me",
        "so", "make", "can", "be", "with", "at", "all", "just", "not", "ang", "ng", "sa", "na", "ko", "mo", "yung", "lang"}

def cwords(s):
    return set(re.findall(r"[a-z]+", s.lower())) - STOP

def protected_goals():
    """Test, validation and use-case goals: never train on them or on near-copies of them."""
    goals = []
    for p in glob.glob("fixtures/*_real.json") + glob.glob("fixtures/val/*.json"):
        goals += json.load(open(p))["goals"]
    for p in glob.glob("fixtures/web_test/*.json"):
        goals += [s["goal"] for s in json.load(open(p))["steps"]]
    sys.path.insert(0, "usecases")
    from scenarios import SCENARIOS
    goals += [g for rows in SCENARIOS.values() for g, _ in rows]
    return [(g, cwords(g)) for g in goals]

def leak(goal, protected):
    w = cwords(goal)
    for g, pw in protected:
        if goal.strip().lower() == g.strip().lower():
            return g
        if len(w & pw) >= 2 and len(w & pw) / len(w | pw) >= 0.5:
            return g
    return None

def route_row(current, goal, opts, answer):
    return {"state": f'A non-technical person is using their Mac. The app in front is {current}. Their goal: "{goal}"',
            "questions": {"next_command": {"type": "choice", "instructions": "Which app should the person use for this goal?",
                                           "criteria": {o: o for o in opts}}},
            "expected": {"next_command": answer}}

def route_opts(current, answer, decoys, all_apps, rng):
    here = f"{current} (the app open now)"
    opts = list(dict.fromkeys([here, answer, *[d for d in decoys if d != current]]))
    opts += rng.sample([a for a in all_apps if a not in opts and a != current], GROUP - len(opts))
    rng.shuffle(opts)
    return opts

def jev_check(rows, key):
    with cf.ThreadPoolExecutor(8) as ex:
        return list(ex.map(lambda r: jev_top(r, key), rows))

def main(out_dir):
    load_dotenv(); key = os.environ["JEV_API_KEY"]
    rng = random.Random(77)
    protected = protected_goals()
    leaks = []

    # ---- menu contrast rows
    items, bad = [], []
    for p in sorted(glob.glob("data/goals_contrast/*.jsonl")):
        n = os.path.basename(p)[:-6]
        if n in HELD_OUT or n in VAL_APPS:
            raise SystemExit(f"refusing to train on held-out/validation app {n}")
        snap = load_snapshot(DUMPS, n)
        if not snap:
            print(f"{n}: no dump, skipped"); continue
        cmds = list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))
        cs = set(cmds)
        for l in open(p):
            if not l.strip(): continue
            g = json.loads(l)
            if (hit := leak(g["goal"], protected)):
                leaks.append((g["goal"], hit)); continue
            missing = [c for c in [g["answer"], *g["decoys"]] if c not in cs]
            if g["answer"] in cs and not missing:
                items.append((n, snap["app"], cmds, g))
            else:
                bad.append((n, g["goal"], missing))
    verdicts = jev_check([row(a, g["goal"], group(g["answer"], g["decoys"], c, rng), g["answer"]) for _, a, c, g in items], key)
    stats = Counter()
    with open(f"{out_dir}/contrast.jsonl", "w") as f:
        for (n, app, cmds, g), (top, p) in zip(items, verdicts):
            t = g["type"]
            stats[t, "goals"] += 1
            stats[t, "agree"] += top == g["answer"]
            stats[t, "no_answer"] += top is None
            if top and top != g["answer"] and p > 0.85:
                stats[t, "dropped"] += 1
                print(f"  drop [{app}] {g['goal']!r}: Jev {top!r} {p:.2f} (label {g['answer']!r})"); continue
            for _ in range(MENU_REPEAT):
                f.write(json.dumps(row(app, g["goal"], group(g["answer"], g["decoys"], cmds, rng), g["answer"]), ensure_ascii=False) + "\n")
                stats[t, "rows"] += 1

    # ---- routing contrast rows
    names = {}
    for p in glob.glob("/tmp/sg/train*/*.json"):
        n = os.path.basename(p)[:-5]
        if n in HELD_OUT or n in VAL_APPS: continue
        snap = load_snapshot(DUMPS, n)
        if snap: names[n] = snap["app"]
    all_apps = sorted(set(names.values()) | set(EXTRA) | {"Voice Memos", "Spotify"})
    route_items = []   # (kind, current, goal, answer, decoys)
    for l in open("data/goals_sysroute/system.jsonl"):
        if not l.strip(): continue
        g = json.loads(l)
        if (hit := leak(g["goal"], protected)):
            leaks.append((g["goal"], hit)); continue
        near = [names[a] for a in g["near"] if a in names]
        currents = rng.sample(near, min(2, len(near)))
        currents += rng.sample([a for a in names.values() if a not in currents], ROUTE_CONTEXTS - len(currents))
        for cur in currents:
            route_items.append(("system:" + g["topic"], cur, g["goal"], "System Settings", g["decoys"]))
    for l in open("data/goals_sysroute/stay.jsonl"):
        if not l.strip(): continue
        g = json.loads(l)
        if g["app"] in HELD_OUT or g["app"] in VAL_APPS or g["app"] not in names:
            raise SystemExit(f"bad stay app {g['app']}")
        if (hit := leak(g["goal"], protected)):
            leaks.append((g["goal"], hit)); continue
        cur = names[g["app"]]
        for _ in range(2):
            route_items.append(("stay", cur, g["goal"], f"{cur} (the app open now)", g["decoys"]))
    checks = [route_row(c, g, route_opts(c, a, d, all_apps, rng), a) for _, c, g, a, d in route_items]
    verdicts = jev_check(checks, key)
    with open(f"{out_dir}/sysroute.jsonl", "w") as f:
        for (kind, cur, goal, ans, decoys), (top, p) in zip(route_items, verdicts):
            t = "route_" + kind.split(":")[0]
            stats[t, "goals"] += 1
            stats[t, "agree"] += top == ans
            stats[t, "no_answer"] += top is None
            if top and top != ans and p > 0.85:
                stats[t, "dropped"] += 1
                print(f"  drop [route, {cur}] {goal!r}: Jev {top!r} {p:.2f} (label {ans!r})"); continue
            for _ in range(ROUTE_REPEAT):
                f.write(json.dumps(route_row(cur, goal, route_opts(cur, ans, decoys, all_apps, rng), ans), ensure_ascii=False) + "\n")
                stats[t, "rows"] += 1

    for g, hit in leaks:
        print(f"  near-copy of a protected goal, skipped: {g!r} ~ {hit!r}")
    for n, g, missing in bad:
        print(f"  not real commands in {n}: {g!r} {missing}")
    for t in sorted({t for t, _ in stats}):
        print(f"{t:14s} goals/contexts {stats[t, 'goals']:4d}  Jev agreed {stats[t, 'agree']:4d}  "
              f"no answer {stats[t, 'no_answer']:3d}  dropped {stats[t, 'dropped']:3d}  rows {stats[t, 'rows']:5d}")
    print(f"leaks skipped {len(leaks)}, invalid {len(bad)}")

def assemble(out_dir, base="data/v6/train.jsonl"):
    # v6 keeps its own deliberate repeats (upweighting); new rows are only dropped if v6 already has them.
    rows = [l.strip() for l in open(base) if l.strip()]
    v6, added = set(rows), 0
    for p in [f"{out_dir}/contrast.jsonl", f"{out_dir}/sysroute.jsonl"]:
        for l in open(p):
            if l.strip() and l.strip() not in v6:
                rows.append(l.strip()); added += 1
    random.Random(7).shuffle(rows)
    with open(f"{out_dir}/train.jsonl", "w") as f:
        f.write("\n".join(rows) + "\n")
    print(f"{out_dir}/train.jsonl: {len(rows)} rows ({base} + {added} new contrast/sysroute rows)")

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "data/v7"
    os.makedirs(out, exist_ok=True)
    main(out)
    assemble(out)
