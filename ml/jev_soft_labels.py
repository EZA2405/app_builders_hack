"""Distill hosted Jev's probability spread into Laya training rows (soft labels).

For each row in a Laya train file, ask hosted Jev the same 16-option question and write a
`gold` target = (1 - JEV_WEIGHT) * one-hot(teacher answer) + JEV_WEIGHT * Jev probabilities.
The teacher label still dominates; Jev adds "which wrong options are nearly right".
Rows where Jev confidently picks a different answer (>0.85) are dropped as ambiguous.

Rows only contain sanitized menu commands (built via make_fixtures.is_personal/redact_names),
public web page elements and synthetic goals, so nothing personal leaves the machine.

Resumable: every Jev answer is appended to <dst>.cache as it arrives; reruns skip cached rows.

Usage: python3 jev_soft_labels.py data/v3/train_hard.jsonl data/v3/train.jsonl   (needs JEV_API_KEY in ml/.env)
"""
import concurrent.futures as cf, hashlib, json, os, sys, threading, time, urllib.request
from bench_localjev import load_dotenv

JEV_WEIGHT = 0.3
URL = "https://api.typesafe.ai/v1/systemone"

def row_key(row):
    return hashlib.sha1(json.dumps([row["state"], row["questions"]], sort_keys=True).encode()).hexdigest()

def jev_probs(row, key):
    body = {"model": "jev-latest", "state": row["state"], "questions": row["questions"]}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                res = json.load(r)
            return res.get("answers", res).get("next_command", {}).get("probabilities")
        except Exception:  # SSL resets, timeouts, 5xx: back off and retry, never kill the run
            time.sleep(1.5 * (attempt + 1))
    return None

def main(src, dst):
    load_dotenv()
    key = os.environ.get("JEV_API_KEY") or os.environ.get("TYPESAFE_API_KEY")
    rows = [json.loads(l) for l in open(src) if l.strip()]
    cache_path = dst + ".cache"
    cache = {}
    if os.path.exists(cache_path):
        for l in open(cache_path):
            try:
                k, p = json.loads(l)
                cache[k] = p
            except ValueError:
                pass
    todo = [r for r in rows if "expected" in r and "next_command" in r["expected"] and row_key(r) not in cache]
    print(f"{len(rows)} rows, {len(cache)} cached, {len(todo)} to query", flush=True)
    lock = threading.Lock()
    with open(cache_path, "a") as cf_out, cf.ThreadPoolExecutor(8) as ex:
        def work(r):
            p = jev_probs(r, key)
            if p is not None:
                with lock:
                    cf_out.write(json.dumps([row_key(r), p]) + "\n"); cf_out.flush()
                    cache[row_key(r)] = p
        for i, _ in enumerate(ex.map(work, todo), 1):
            if i % 1000 == 0:
                print(f"  {i}/{len(todo)}", flush=True)
    agree = soft = dropped = 0
    with open(dst, "w") as f:
        for row in rows:
            if "expected" not in row or "next_command" not in row["expected"]:
                f.write(json.dumps(row, ensure_ascii=False) + "\n")   # already soft-labelled (e.g. risk rows)
                continue
            p = cache.get(row_key(row))
            ans = row["expected"]["next_command"]
            opts = list(row["questions"]["next_command"]["criteria"])
            if p and set(p) >= set(opts):
                top = max(p, key=p.get)
                if top != ans and p[top] > 0.85:
                    dropped += 1
                    continue
                gold = {o: (1 - JEV_WEIGHT) * (o == ans) + JEV_WEIGHT * p[o] for o in opts}
                row = {**{k: v for k, v in row.items() if k != "expected"}, "gold": {"next_command": {"probabilities": gold}}}
                soft += 1
                agree += top == ans
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(f"{soft}/{len(rows)} rows got soft labels; Jev's top pick matched the teacher on {agree}/{soft} "
          f"({agree / max(soft, 1):.1%}); dropped {dropped} rows where Jev confidently disagreed (>0.85)")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
