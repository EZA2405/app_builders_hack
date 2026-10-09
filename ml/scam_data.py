"""Distill the "wait, check first" yes/no question into Laya rows.

Input: data/scam/train.jsonl ({"goal", "risky"}), teacher-written, no overlap with scam_eval.py's test CASES.
Hosted Jev answers the same question for each goal (synthetic text only, nothing personal). Rows where Jev
confidently disagrees with the teacher (>0.85 the other way) are dropped; the rest get a soft target
0.7 * teacher + 0.3 * Jev.

Usage: python3 scam_data.py [out.jsonl] [repeat]   (needs JEV_API_KEY in ml/.env)
"""
import concurrent.futures as cf, json, os, sys, time, urllib.request
from bench_localjev import load_dotenv
from scam_eval import QUESTION

URL = "https://api.typesafe.ai/v1/systemone"

def state(goal):
    return f'A person asks for help on their Mac: "{goal}"'   # same as scam_eval.py and Planner.risky

def jev_yes(goal, key):
    body = {"model": "jev-latest", "state": state(goal), "questions": {"risky": QUESTION}}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    for attempt in range(4):
        try:
            res = json.load(urllib.request.urlopen(req, timeout=90))
            a = res.get("answers", res).get("risky", {})
            return float(a.get("noul", a.get("probability")))
        except Exception:
            time.sleep(2 * (attempt + 1))
    return None

def main(out="data/scam/rows.jsonl", repeat=3):
    load_dotenv()
    key = os.environ["JEV_API_KEY"]
    items = [json.loads(l) for l in open("data/scam/train.jsonl") if l.strip()]
    with cf.ThreadPoolExecutor(8) as ex:
        probs = list(ex.map(lambda g: jev_yes(g["goal"], key), items))
    kept = dropped = agree = n = 0
    with open(out, "w") as f:
        for g, p in zip(items, probs):
            t = 1.0 if g["risky"] else 0.0
            if p is not None:
                n += 1
                agree += (p >= 0.5) == g["risky"]
                if abs(p - t) > 0.85:          # Jev confidently says the opposite
                    dropped += 1
                    continue
                yes = 0.7 * t + 0.3 * p
            else:
                yes = t
            row = {"state": state(g["goal"]), "questions": {"risky": QUESTION},
                   "gold": {"risky": {"probabilities": {"false": 1 - yes, "true": yes}}}}
            for _ in range(int(repeat)):        # small set inside a 12k-row mix: upweight
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
            kept += 1
    print(f"Jev agreed with the teacher on {agree}/{n}; dropped {dropped}; kept {kept} goals x{repeat} -> {out}")

if __name__ == "__main__":
    main(*(sys.argv[1:3]))
