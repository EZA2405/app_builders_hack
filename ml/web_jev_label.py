"""Web journeys at scale: teacher writes goals only per page ({"goal", "page", "done"}); hosted Jev picks the
element over the page's elements (public pages crawled with a fresh profile). Confident (>= 0.6) labels become
rows in web_data.py's format.   Usage: python3 web_jev_label.py [pages_dir] [out.jsonl]
"""
import concurrent.futures as cf, glob, json, os, random, sys
from bench_localjev import choose, load_dotenv
from build_trainset import GROUP, state_for, words
from web_data import page_elements, site_label

HELD = {"youtube_home", "wikipedia_home", "sss", "philhealth", "shopee"}

def main(pages="/tmp/sg/web", out="data/v6/web_jev.jsonl"):
    load_dotenv(); key = os.environ["JEV_API_KEY"]; rng = random.Random(43)
    jobs = []
    for p in sorted(glob.glob("data/goals_web_jev/*.jsonl")):
        site = os.path.basename(p)[:-6]
        if site.startswith("test_") or site in HELD:
            continue
        for l in open(p):
            if not l.strip(): continue
            g = json.loads(l)
            try:
                snap, ids = page_elements(pages, g["page"])
            except Exception:
                continue
            jobs.append((site_label(snap), ids, g))
    def label(j):
        app, ids, g = j
        try:
            c, conf, _, _ = choose("https://api.typesafe.ai", "jev-latest", app, ids, g["goal"], key, limit=200, done=g.get("done"))
            return j, c, conf or 0.0
        except BaseException:
            return j, None, 0.0
    kept = 0
    with cf.ThreadPoolExecutor(8) as ex, open(out, "w") as f:
        for (app, ids, g), c, conf in ex.map(label, jobs):
            if not c or conf < 0.6 or c not in ids: continue
            kept += 1
            others = [x for x in ids if x != c]
            gw = words(g["goal"]); near = sorted(others, key=lambda x: -len(gw & words(x)))[:10]
            i = ids.index(c) // GROUP * GROUP
            for neg in (rng.sample(others, min(GROUP - 1, len(others))), (near + rng.sample(others, min(GROUP - 1, len(others))))[:GROUP - 1],
                        [x for x in ids[i:i + GROUP] if x != c]):
                opts = [c, *list(dict.fromkeys(neg))[:GROUP - 1]]; rng.shuffle(opts)
                f.write(json.dumps({"state": state_for(app, g["goal"], g.get("done")),
                                    "questions": {"next_command": {"type": "choice", "instructions": "Which element on this page should the person use next?",
                                                                   "criteria": {o: o for o in opts}}},
                                    "expected": {"next_command": c}}, ensure_ascii=False) + "\n")
    print(f"Jev labeled {len(jobs)} web goals; kept {kept} (conf >= 0.6) -> {out}")

if __name__ == "__main__":
    main(*sys.argv[1:3])
