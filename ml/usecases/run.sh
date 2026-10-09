#!/bin/zsh
# Regression check for Gabay's first-step decisions on this Mac's live apps (no overlay, no clicks).
# Usage: ml/usecases/run.sh   (apps must be running; prints per-app scores and misses)
cd "$(dirname "$0")/../.."
python3 - <<'PY'
import json, subprocess, sys
sys.path.insert(0, "ml/usecases")
from scenarios import SCENARIOS
tot = ok = 0
for name, items in SCENARIOS.items():
    app = name.split(" (")[0]
    goals = [g for g, _ in items]
    json.dump(goals, open("/tmp/uc_in.json", "w"))
    subprocess.run(["open", "-W", "-n", "app/build/ScreenGuide.app", "--args", "--plan", app, "/tmp/uc_in.json", "/tmp/uc_out.json"])
    res = json.load(open("/tmp/uc_out.json"))
    good = 0
    for (g, exp), r in zip(items, res):
        if exp in ("RISK", "OK"): hit = (float(r["risk"]) >= 0.6 or r["scamRule"] == "warn") == (exp == "RISK")
        else: hit = any(e in r["pick"] for e in exp)
        good += hit
        if not hit: print(f"   ✗ [{name}] {g!r} -> {r['pick']} ({r['conf']})")
    print(f"{name}: {good}/{len(items)}"); tot += len(items); ok += good
print(f"TOTAL {ok}/{tot}")
PY
