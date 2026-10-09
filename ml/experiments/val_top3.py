"""Collect Laya's final-round top-3 for each validation goal (for the Apple-model second-opinion experiment)."""
import glob, json, sys
sys.path.insert(0, ".")
from bench_localjev import choose, answer
out = []
for f in sorted(glob.glob("fixtures/val/*.json")):
    fx = json.load(open(f))
    for goal, ok in fx["goals"].items():
        choice, conf, _, res = choose("http://127.0.0.1:8766", "guide-v4e5", fx["app"], fx["commands"], goal, None, limit=16)
        probs = (answer(res).get("probabilities") or {})
        top3 = sorted(probs, key=probs.get, reverse=True)[:3]
        out.append({"app": fx["app"], "goal": goal, "ok": ok, "top3": top3, "probs": [probs[t] for t in top3]})
json.dump(out, open("/tmp/sg/val_top3.json", "w"), ensure_ascii=False)
top1 = sum(o["top3"][0] in o["ok"] for o in out); any3 = sum(any(t in o["ok"] for t in o["top3"]) for o in out)
print(f"Laya top-1 {top1}/{len(out)} | right answer somewhere in top-3: {any3}/{len(out)}")
