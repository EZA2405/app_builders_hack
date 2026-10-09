"""v8 rows for two live-test failures, taught as general concepts on TRAINING apps only.

fontsize  data/goals_fontsize/<app>.jsonl  {"type": font|zoom|picture, "goal", "answer", "decoys", "alts"?}
          Text size vs zoom vs picture size. "make the words in my note bigger" -> Format > Font > Bigger, not
          View > Zoom In; "magnify the view, don't change my letter" -> View > Zoom In, not the font command;
          "make the pictures in my note smaller" -> View > Attachment View > Set All to Small. Each goal's decoys
          come from the other two families, so every option group holds the look-alikes.
toolbar   data/goals_toolbar/<window>.jsonl  {"type": control|menu, ...}
          Option groups that MIX menu commands with an open window's controls, keyed exactly like Planner.key
          (`role "label" · context`), as the first step sees them with step1Controls on. Both directions: a
          checkbox/button that does the job directly wins over menus, and a menu command wins over look-alike
          controls. The main-window dumps (/tmp/sg/train*) are menus-only (no controls), so the only real controls
          are harvest_dialogs.py's Settings/Find windows of training apps (/tmp/sg/dialogs). Save/Print/Export
          panels are left out (at runtime they are dialogs, and dialogs are never mixed with menus), and so are
          pop-up menus (their harvested labels predate ScreenState naming them by the text beside them).

"alts" are other right answers; they are kept out of the option groups so no row has two right answers.
Hosted Jev double-checks one group per goal; goals where Jev confidently (>0.85) picks something other than the
label are dropped. Near-copies of test, validation or use-case goals are skipped (contrast_data.leak).
Sanitized menus and controls (is_personal + redact_names) + synthetic goals only.

Usage: python3 toolbar_data.py [data/v8]  -> <out>/fontsize.jsonl, <out>/toolbar.jsonl and
       <out>/train.jsonl = data/v6/train.jsonl + both (rows already in v6 skipped), shuffled (seed 7).
"""
import glob, json, os, random, sys
from collections import Counter
from bench_localjev import load_dotenv
from build_trainset import HELD_OUT, VAL_APPS, GROUP, load_snapshot, negatives
from contrast_data import protected_goals, leak, jev_check
from make_fixtures import is_personal, redact_names
from obvious_data import DUMPS, row

REPEAT = 3
DIALOGS = "/tmp/sg/dialogs"
# GuideEngine.focus() step 1 with step1Controls: these window roles join the menus (pop-up menus left out, see above).
STEP1_ROLES = {"button", "checkbox", "menu button", "segmented control"}
SKIP_WINDOWS = {"music__1", "music__2", "stickies__0", "stickies__1"}   # Save / Page Setup / Export / Print panels

def menu_cmds(stem):
    snap = load_snapshot(DUMPS, stem)
    if not snap:
        return None, []
    return snap["app"], list(dict.fromkeys(redact_names(c["path"]) for c in snap["commands"] if not is_personal(c)))

def window_controls(window):
    d = json.load(open(f"{DIALOGS}/{window}.json"))
    keys = []
    for c in d["controls"]:
        if c["role"] not in STEP1_ROLES:
            continue
        k = f'{c["role"]} "{c["label"]}" · {c["context"]}' if c["context"] else f'{c["role"]} "{c["label"]}"'
        if not is_personal({"path": k}):
            keys.append(redact_names(k))
    return list(dict.fromkeys(keys))

def fill(opts, anchor, cmds, alts, rng):
    pool = [c for c in cmds if c not in alts]
    opts += [c for c in negatives(anchor, set(opts), pool, rng) if c not in opts][:GROUP - len(opts)]
    rng.shuffle(opts)
    return opts

def menu_group(g, cmds, rng):
    return fill([g["answer"], *g["decoys"]], g["answer"], cmds, set(g.get("alts", [])), rng)

def mixed_group(g, controls, cmds, rng):
    # Some copies carry most of the window's controls (like the tournament chunk that holds them), some only a
    # few (like the final round, where menu winners and control winners meet).
    opts, alts = [g["answer"], *g["decoys"]], set(g.get("alts", []))
    others = [c for c in controls if c not in opts and c not in alts]
    opts += rng.sample(others, min(len(others), rng.choice([2, 4, 8]), GROUP - len(opts)))
    anchor = next((c for c in [g["answer"], *g["decoys"]] if c in cmds), None) or rng.choice(cmds)
    return fill(opts, anchor, cmds, alts, rng)

def load(kind, protected, leaks, bad):
    items = []   # (kind, stem, app, cmds, controls, goal)
    for p in sorted(glob.glob(f"data/goals_{kind}/*.jsonl")):
        name = os.path.basename(p)[:-6]
        stem = name.split("__")[0]
        if stem in HELD_OUT or stem in VAL_APPS:
            raise SystemExit(f"refusing to train on held-out/validation app {stem}")
        if name in SKIP_WINDOWS:
            raise SystemExit(f"{name} is a dialog panel; it is never mixed with menus at runtime")
        app, cmds = menu_cmds(stem)
        if not cmds:
            print(f"{name}: no dump, skipped"); continue
        controls = window_controls(name) if kind == "toolbar" else []
        ok = set(cmds) | set(controls)
        for l in open(p):
            if not l.strip(): continue
            g = json.loads(l)
            if (hit := leak(g["goal"], protected)):
                leaks.append((g["goal"], hit)); continue
            missing = [c for c in [g["answer"], *g["decoys"]] if c not in ok]
            if missing:
                bad.append((name, g["goal"], missing)); continue
            items.append((kind, name, app, cmds, controls, g))
    return items

def build(g, cmds, controls, rng):
    return mixed_group(g, controls, cmds, rng) if controls else menu_group(g, cmds, rng)

def main(out_dir):
    load_dotenv(); key = os.environ["JEV_API_KEY"]
    rng = random.Random(88)
    protected, leaks, bad = protected_goals(), [], []
    items = load("fontsize", protected, leaks, bad) + load("toolbar", protected, leaks, bad)
    verdicts = jev_check([row(app, g["goal"], build(g, cmds, ctl, rng), g["answer"]) for _, _, app, cmds, ctl, g in items], key)
    stats = Counter()
    files = {k: open(f"{out_dir}/{k}.jsonl", "w") for k in ("fontsize", "toolbar")}
    for (kind, name, app, cmds, ctl, g), (top, p) in zip(items, verdicts):
        t = f"{kind}:{g['type']}"
        stats[t, "goals"] += 1
        stats[t, "agree"] += top == g["answer"]
        stats[t, "no_answer"] += top is None
        if top and top != g["answer"] and p > 0.85:
            stats[t, "dropped"] += 1
            print(f"  drop [{app}] {g['goal']!r}: Jev {top!r} {p:.2f} (label {g['answer']!r})"); continue
        if top and top != g["answer"]:
            print(f"  kept, Jev unsure [{app}] {g['goal']!r}: Jev {top!r} {p:.2f} (label {g['answer']!r})")
        for _ in range(REPEAT):
            files[kind].write(json.dumps(row(app, g["goal"], build(g, cmds, ctl, rng), g["answer"]), ensure_ascii=False) + "\n")
            stats[t, "rows"] += 1
    for f in files.values():
        f.close()
    for g, hit in leaks:
        print(f"  near-copy of a protected goal, skipped: {g!r} ~ {hit!r}")
    for n, g, missing in bad:
        print(f"  not real commands/controls in {n}: {g!r} {missing}")
    for t in sorted({t for t, _ in stats}):
        print(f"{t:18s} goals {stats[t, 'goals']:4d}  Jev agreed {stats[t, 'agree']:4d}  "
              f"no answer {stats[t, 'no_answer']:3d}  dropped {stats[t, 'dropped']:3d}  rows {stats[t, 'rows']:5d}")
    print(f"leaks skipped {len(leaks)}, invalid {len(bad)}")

def assemble(out_dir, base="data/v6/train.jsonl"):
    # v6 keeps its own deliberate repeats (upweighting); new rows are only dropped if v6 already has them.
    rows = [l.strip() for l in open(base) if l.strip()]
    v6, added = set(rows), 0
    for k in ("fontsize", "toolbar"):
        for l in open(f"{out_dir}/{k}.jsonl"):
            if l.strip() and l.strip() not in v6:
                rows.append(l.strip()); added += 1
    random.Random(7).shuffle(rows)
    with open(f"{out_dir}/train.jsonl", "w") as f:
        f.write("\n".join(rows) + "\n")
    print(f"{out_dir}/train.jsonl: {len(rows)} rows ({base} + {added} new fontsize/toolbar rows)")

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "data/v8"
    os.makedirs(out, exist_ok=True)
    main(out)
    assemble(out)
