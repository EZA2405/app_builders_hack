"""Website journeys -> held-out web fixtures and Laya training rows.

Element id string (what the model chooses between): role "name" · context  (or role "name").
The model state carries the steps already taken (see build_trainset.state_for).

Usage:
  python3 web_data.py fixtures  [pages_dir]            # fixtures/web_test/<site>.json from data/goals_web_test
  python3 web_data.py rows      [pages_dir] [out.jsonl] # Laya rows from data/goals_web (training sites)
"""
import glob, json, os, random, sys
from build_trainset import GROUP, state_for, words

def element_id(e):
    base = f'{e["role"]} "{e["name"]}"'
    return f'{base} · {e["context"]}' if e.get("context") else base

def page_elements(pages_dir, stem):
    d = json.load(open(os.path.join(pages_dir, f"{stem}.json")))
    ids = list(dict.fromkeys(element_id(e) for e in d["elements"] if e.get("name")))
    return d, ids

def site_label(snap):
    # Shown to the model as the "app": the browser plus the site's title.
    return f'web browser, on the website "{snap["title"][:60]}"'

def fixtures(pages_dir):
    os.makedirs("fixtures/web_test", exist_ok=True)
    for path in sorted(glob.glob("data/goals_web_test/*.jsonl")):
        site = os.path.basename(path)[:-6]
        steps = []
        for line in open(path):
            if not line.strip():
                continue
            g = json.loads(line)
            snap, ids = page_elements(pages_dir, g["page"])
            ok = [a for a in [g["answer"], *g.get("alts", [])] if a in ids]
            if g["answer"] not in ids:
                print(f"!! {site}: answer not on page {g['page']}: {g['answer']}")
                continue
            steps.append({"goal": g["goal"], "done": g.get("done", []), "app": site_label(snap),
                          "commands": ids, "ok": ok, "page": g["page"]})
        json.dump({"app": site, "source": "held-out web journeys (never trained on)", "steps": steps},
                  open(f"fixtures/web_test/{site}.json", "w"), indent=1, ensure_ascii=False)
        print(f"web_test {site}: {len(steps)} steps")

def rows(pages_dir, out):
    rng = random.Random(13)
    n = 0
    with open(out, "w") as f:
        for path in sorted(glob.glob("data/goals_web/*.jsonl")):
            site = os.path.basename(path)[:-6]
            # Held-out sites (and other pages on the same domains) never enter training.
            if site.startswith("test_") or site in {"youtube_home", "wikipedia_home", "sss", "philhealth", "shopee"}:
                raise SystemExit(f"refusing to train on held-out site {site}")
            for line in open(path):
                if not line.strip():
                    continue
                g = json.loads(line)
                snap, ids = page_elements(pages_dir, g["page"])
                if g["answer"] not in ids:
                    continue
                ok = {a for a in [g["answer"], *g.get("alts", [])] if a in ids}
                others = [c for c in ids if c not in ok]
                gw = words(g["goal"])
                near = sorted(others, key=lambda c: -len(gw & words(c)))[:10]
                groups = [rng.sample(others, min(GROUP - 1, len(others))),                    # random
                          (near + rng.sample(others, min(GROUP - 1, len(others))))[:GROUP - 1]]  # look-alikes
                i = ids.index(g["answer"]) // GROUP * GROUP                                    # in-page order chunk
                groups.append([c for c in ids[i:i + GROUP] if c not in ok])
                for neg in groups:
                    opts = [g["answer"], *list(dict.fromkeys(neg))[:GROUP - 1]]
                    rng.shuffle(opts)
                    f.write(json.dumps({
                        "state": state_for(site_label(snap), g["goal"], g.get("done")),
                        "questions": {"next_command": {"type": "choice",
                                                       "instructions": f"Which element on this page should the person use next?",
                                                       "criteria": {c: c for c in opts}}},
                        "expected": {"next_command": g["answer"]}}, ensure_ascii=False) + "\n")
                    n += 1
    print(f"web training rows: {n} -> {out}")

if __name__ == "__main__":
    cmd = sys.argv[1]
    pages = sys.argv[2] if len(sys.argv) > 2 else "fixtures/web_pages"
    fixtures(pages) if cmd == "fixtures" else rows(pages, sys.argv[3] if len(sys.argv) > 3 else "data/v3/web.jsonl")
