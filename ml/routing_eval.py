"""'Which app?' check on HELD-OUT and VAL apps' goals (never in routing training): does the model send the goal
to the right app (or stay when it's already open)? Same request as Planner.pickApp.
Usage: python3 routing_eval.py [--url ...] [--model guide]
"""
import argparse, glob, json, random, urllib.request

APPS = {"preview_real": "Preview", "finder_real": "Finder", "systemsettings_real": "System Settings", "safari_real": "Safari",
        "val/activitymonitor": "Activity Monitor", "val/diskutility": "Disk Utility", "val/numbers": "Numbers", "val/terminal": "Terminal"}
DOCK = ["Finder", "Safari", "System Settings", "Preview", "Mail", "Messages", "Photos", "Music", "Notes", "Calendar",
        "TextEdit", "Activity Monitor", "Disk Utility", "Numbers", "Terminal", "Google Chrome", "Zoom", "Maps"]

def main():
    p = argparse.ArgumentParser(); p.add_argument("--url", default="http://127.0.0.1:8766"); p.add_argument("--model", default="guide")
    a = p.parse_args(); rng = random.Random(61); hits = n = 0
    for stem, app in APPS.items():
        for goal in json.load(open(f"fixtures/{stem}.json"))["goals"]:
            current = app if rng.random() < 0.5 else rng.choice([d for d in DOCK if d != app])
            here = f"{current} (the app open now)"
            opts = [here] + rng.sample([d for d in DOCK if d not in (current, app)], 13) + ([app] if app != current else [])
            rng.shuffle(opts)
            body = {"model": a.model, "state": f'A non-technical person is using their Mac. The app in front is {current}. Their goal: "{goal}"',
                    "questions": {"next_command": {"type": "choice", "instructions": "Which app should the person use for this goal?", "criteria": {o: o for o in opts}}}}
            req = urllib.request.Request(a.url + "/v1/systemone", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
            choice = json.load(urllib.request.urlopen(req, timeout=60)).get("answers", {}).get("next_command", {}).get("choice")
            hits += choice == (here if app == current else app); n += 1
    print(f"{a.model} routing (held-out + val apps): {hits}/{n}")

if __name__ == "__main__":
    main()
