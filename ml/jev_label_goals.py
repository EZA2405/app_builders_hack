"""Jev as the labeler: teacher wrote goals only (data/goals_jev/<app>.jsonl); hosted Jev picks the command over
the app's full sanitized menu (200-wide tournament like bench_localjev). Confident labels (>= 0.6) become
training rows in the same 4-group format as build_trainset.py, with Jev's choice as the answer.

Usage: python3 jev_label_goals.py out.jsonl
"""
import concurrent.futures as cf, glob, json, os, random, sys
from bench_localjev import choose, load_dotenv
from build_trainset import HELD_OUT, VAL_APPS, negatives, tournament_rows, state_for, instructions_for, load_snapshot
from make_fixtures import is_personal, redact_names

DUMPS = ["/tmp/sg/train", "/tmp/sg/train2"]

def main(out):
    load_dotenv()
    key = os.environ["JEV_API_KEY"]
    rng = random.Random(37)
    jobs = []
    for p in sorted(glob.glob("data/goals_jev/*.jsonl")):
        n = os.path.basename(p)[:-6]
        if n in HELD_OUT or n in VAL_APPS:
            continue
        snap = load_snapshot(DUMPS, n)
        if not snap:
            continue
        cmds = list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))
        for l in open(p):
            if l.strip():
                jobs.append((snap["app"], cmds, json.loads(l)["goal"]))

    def label(job):
        app, cmds, goal = job
        try:
            choice, conf, _, _ = choose("https://api.typesafe.ai", "jev-latest", app, cmds, goal, key, limit=200)
            return app, cmds, goal, choice, conf or 0.0
        except BaseException:
            return app, cmds, goal, None, 0.0

    kept = total = 0
    with cf.ThreadPoolExecutor(8) as ex, open(out, "w") as f:
        for app, cmds, goal, choice, conf in ex.map(label, jobs):
            total += 1
            if not choice or conf < 0.6 or choice not in cmds:
                continue
            kept += 1
            groups = [[choice, *negatives(choice, {choice}, cmds, rng)] for _ in range(2)]
            groups += tournament_rows(goal, choice, {choice}, cmds, rng)
            for opts in groups:
                rng.shuffle(opts)
                f.write(json.dumps({"state": state_for(app, goal),
                                    "questions": {"next_command": {"type": "choice", "instructions": instructions_for(app),
                                                                   "criteria": {c: c for c in opts}}},
                                    "expected": {"next_command": choice}}, ensure_ascii=False) + "\n")
    print(f"Jev labeled {total} goals; kept {kept} with confidence >= 0.6 -> {out}")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/v6/jev_goals.jsonl")
