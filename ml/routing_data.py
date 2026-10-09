"""'Which app should this happen in?' rows, matching Planner.pickApp in the Mac app exactly.

Labels are free: every teacher goal belongs to a known app. Half the rows have the right app already in front
(answer = "<app> (the app open now)"), half have some other app in front. Options are a Dock-like set of app
names, including the held-out apps' names as distractors (their goals are never used).

Usage: python3 routing_data.py out.jsonl
"""
import glob, json, os, random, sys
from build_trainset import HELD_OUT, VAL_APPS, GROUP, load_snapshot

DUMPS = ["/tmp/sg/train", "/tmp/sg/train2"]
EXTRA = ["Finder", "System Settings", "Safari", "Preview", "Google Chrome", "Mail", "Messages", "FaceTime",
         "App Store", "Photo Booth", "Zoom", "Viber", "Microsoft Word"]

def main(out):
    rng = random.Random(31)
    names = {}
    for p in glob.glob("data/goals/*.jsonl"):
        n = os.path.basename(p)[:-6]
        if n in HELD_OUT or n in VAL_APPS:
            continue
        snap = load_snapshot(DUMPS, n)
        if snap:
            names[n] = snap["app"]
    all_apps = sorted(set(names.values()) | set(EXTRA))
    rows = 0
    with open(out, "w") as f:
        for n, app in sorted(names.items()):
            goals = []
            for src in ("goals", "goals_para"):
                path = f"data/{src}/{n}.jsonl"
                if os.path.exists(path):
                    goals += [json.loads(l)["goal"] for l in open(path) if l.strip()]
            for goal in rng.sample(goals, min(40, len(goals))):
                current = app if rng.random() < 0.5 else rng.choice([a for a in all_apps if a != app])
                here = f"{current} (the app open now)"
                others = rng.sample([a for a in all_apps if a not in (current, app)], GROUP - 2)
                opts = [here] + ([app] if app != current else []) + others
                opts = opts[:GROUP]
                rng.shuffle(opts)
                answer = here if app == current else app
                f.write(json.dumps({
                    "state": f'A non-technical person is using their Mac. The app in front is {current}. Their goal: "{goal}"',
                    "questions": {"next_command": {"type": "choice", "instructions": "Which app should the person use for this goal?",
                                                   "criteria": {o: o for o in opts}}},
                    "expected": {"next_command": answer}}, ensure_ascii=False) + "\n")
                rows += 1
    print(f"routing rows: {rows} over {len(names)} apps -> {out}")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/v6/routing.jsonl")
