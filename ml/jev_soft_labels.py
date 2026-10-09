"""Distill hosted Jev's probability spread into Laya training rows (soft labels).

For each row in a Laya train file, ask hosted Jev the same 16-option question and write a
`gold` target = (1 - JEV_WEIGHT) * one-hot(teacher answer) + JEV_WEIGHT * Jev probabilities.
The teacher label still dominates; Jev adds "which wrong options are nearly right".

Rows only contain sanitized menu commands (built via make_fixtures.is_personal/redact_names)
and synthetic goals, so nothing personal leaves the machine.

Usage: python3 jev_soft_labels.py data/v2/train.jsonl data/v2/train_soft.jsonl   (needs JEV_API_KEY in ml/.env)
"""
import concurrent.futures as cf, json, os, sys, urllib.request, urllib.error
from bench_localjev import load_dotenv

JEV_WEIGHT = 0.3
URL = "https://api.typesafe.ai/v1/systemone"

def jev_probs(row, key):
    body = {"model": "jev-latest", "state": row["state"], "questions": row["questions"]}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    for _ in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                res = json.load(r)
            ans = res.get("answers", res).get("next_command", {})
            return ans.get("probabilities")
        except (urllib.error.URLError, TimeoutError):
            continue
    return None

def main(src, dst):
    load_dotenv()
    key = os.environ.get("JEV_API_KEY") or os.environ.get("TYPESAFE_API_KEY")
    rows = [json.loads(l) for l in open(src) if l.strip()]
    with cf.ThreadPoolExecutor(8) as ex:
        probs = list(ex.map(lambda r: jev_probs(r, key), rows))
    agree = soft = 0
    with open(dst, "w") as f:
        for row, p in zip(rows, probs):
            ans = row["expected"]["next_command"]
            opts = list(row["questions"]["next_command"]["criteria"])
            if p and set(p) >= set(opts):
                gold = {o: (1 - JEV_WEIGHT) * (o == ans) + JEV_WEIGHT * p[o] for o in opts}
                row = {**{k: v for k, v in row.items() if k != "expected"}, "gold": {"next_command": {"probabilities": gold}}}
                soft += 1
                agree += max(p, key=p.get) == ans
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(f"{soft}/{len(rows)} rows got soft labels; Jev's top pick matched the teacher on {agree}/{soft}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
