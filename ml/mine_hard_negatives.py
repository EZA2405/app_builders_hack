"""Hard-negative mining: run a model's real tournament over training goals and turn its
misses / low-confidence wins into training rows made of exactly the options it confused.

Also builds full-tournament validation fixtures (fixtures/val/*.json) for model selection.

Usage:
  python3 mine_hard_negatives.py val-fixtures /tmp/sg/train            # write fixtures/val/<app>.json
  python3 mine_hard_negatives.py mine --url http://127.0.0.1:8766 --model guide-v1 /tmp/sg/train /tmp/sg/train2
Output of `mine`: data/mined.jsonl (Laya rows) + a summary of v1's training-set accuracy.
"""
import argparse, concurrent.futures as cf, glob, json, os, random
from make_fixtures import is_personal, redact_names
from build_trainset import HELD_OUT, VAL_APPS, GROUP, state_for, instructions_for, load_snapshot
from bench_localjev import ask, answer

def commands_of(snap):
    return list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))

def goals_of(name, skip, sources=("goals", "goals_traps")):
    out = []
    for path in [f"data/{src}/{name}.jsonl" for src in sources]:
        if os.path.exists(path):
            for line in open(path):
                if line.strip():
                    g = json.loads(line)
                    if g["goal"] not in skip:
                        out.append(g)
    return out

def val_fixtures(dumps):
    skip = set(json.load(open("data/disagreements.json")))
    os.makedirs("fixtures/val", exist_ok=True)
    for name in sorted(VAL_APPS):
        snap = load_snapshot(dumps, name)
        cmds = commands_of(snap); cs = set(cmds)
        goals = {g["goal"]: [a for a in [g["answer"], *g.get("alts", [])] if a in cs]
                 for g in goals_of(name, skip) if g["answer"] in cs}
        json.dump({"app": snap["app"], "source": "full-tournament validation (val apps, teacher goals)",
                   "commands": cmds, "goals": goals}, open(f"fixtures/val/{name}.json", "w"), indent=1, ensure_ascii=False)
        print(f"val {name}: {len(goals)} goals over {len(cmds)} commands")

def tournament(url, model, app, commands, goal, limit=16, keep=3):
    """Same algorithm as bench_localjev.choose, but returns every round's options and probabilities."""
    rounds, cands = [], commands
    while True:
        chunks = [cands[i:i + limit] for i in range(0, len(cands), limit)]
        nxt = []
        for ch in chunks:
            res, _ = ask(url, model, app, ch, goal)
            probs = answer(res).get("probabilities") or {}
            rounds.append((ch, probs))
            nxt += sorted(probs, key=probs.get, reverse=True)[:keep] if len(chunks) > 1 else []
        if len(chunks) == 1:
            a = answer(res)
            return a.get("choice"), a.get("confidence") or 0.0, rounds
        cands = nxt

def mine(url, model, dumps, sources=("goals", "goals_traps"), only_apps=None, out="data/mined.jsonl", threads=3):
    skip = set(json.load(open("data/disagreements.json")))
    rng = random.Random(11)
    jobs = []
    names = sorted({os.path.basename(p)[:-6] for src in sources for p in glob.glob(f"data/{src}/*.jsonl")})
    for name in names:
        if name in HELD_OUT or name in VAL_APPS or (only_apps is not None and name not in only_apps):
            continue
        snap = load_snapshot(dumps, name)
        if not snap:
            continue
        cmds = commands_of(snap); cs = set(cmds)
        for g in goals_of(name, skip, sources):
            if g["answer"] in cs:
                jobs.append((name, snap["app"], cmds, g, {a for a in [g["answer"], *g.get("alts", [])] if a in cs}))

    def run(job):
        name, app, cmds, g, ok = job
        choice, conf, rounds = tournament(url, model, app, cmds, g["goal"])
        return name, app, cmds, g, ok, choice, conf, rounds

    rows, hits, n = [], 0, 0
    with cf.ThreadPoolExecutor(threads) as ex:
        for name, app, cmds, g, ok, choice, conf, rounds in ex.map(run, jobs):
            n += 1
            good = choice in ok
            hits += good
            if good and conf >= 0.6:
                continue
            # Options the model actually weighed: top of every round, plus the answer.
            seen = []
            for ch, probs in rounds:
                seen += sorted(probs, key=probs.get, reverse=True)[:4]
            confusers = [c for c in dict.fromkeys(seen) if c not in ok]
            for _ in range(2):
                opts = [g["answer"], *rng.sample(confusers, min(GROUP - 1, len(confusers)))]
                rng.shuffle(opts)
                rows.append({"state": state_for(app, g["goal"]),
                             "questions": {"next_command": {"type": "choice", "instructions": instructions_for(app),
                                                            "criteria": {c: c for c in opts}}},
                             "expected": {"next_command": g["answer"]}})
    with open(out, "w") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"{model} on training goals (full tournament): {hits}/{n} correct; mined {len(rows)} rows -> {out}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("cmd", choices=["val-fixtures", "mine"])
    p.add_argument("dumps", nargs="+")
    p.add_argument("--url", default="http://127.0.0.1:8766")
    p.add_argument("--model", default="guide-v1")
    p.add_argument("--sources", default="goals,goals_traps")
    p.add_argument("--only-apps-in", help="dump dir: only mine apps that have a dump there")
    p.add_argument("--out", default="data/mined.jsonl")
    p.add_argument("--threads", type=int, default=3)
    a = p.parse_args()
    only = {os.path.basename(x)[:-5] for x in glob.glob(os.path.join(a.only_apps_in, "*.json"))} if a.only_apps_in else None
    if a.cmd == "val-fixtures":
        val_fixtures(a.dumps)
    else:
        mine(a.url, a.model, a.dumps, tuple(a.sources.split(",")), only, a.out, a.threads)
