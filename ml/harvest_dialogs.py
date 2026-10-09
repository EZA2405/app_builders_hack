"""Open safe dialogs in TRAINING apps, read their controls, cancel. DEV data collection only.

For each training app: launch it, open a blank document if the app has File > New, then press menu items
ending in '…' whose names are on a safe list (never delete/erase/restore/quit/install…), wait, dump the
screen state (ScreenGuide --press does both), and press Cancel/Close/Done. Output is SANITIZED before it is
written: only dialog/sheet controls, roles + generic labels; sidebar rows and anything path- or name-like
are dropped, so nothing personal reaches the cloud teacher.

Usage: python3 harvest_dialogs.py /tmp/sg/dialogs   (needs ScreenGuide.app built + Accessibility)
"""
import json, os, re, subprocess, sys, time
from build_trainset import HELD_OUT, VAL_APPS

APP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "app", "build", "ScreenGuide.app")
SAFE = re.compile(r"^(Export|Print|Page Setup|Save As|Find|Show Fonts|Show Colors|Fonts|Colors|Settings|Preferences|"
                  r"Insert|Format|Adjust|Paragraph|Spacing|Spelling|Customize|Page|Document|Character|Go to|Jump|Choose|"
                  r"Open Location|Add|New .*Window|Import)", re.I)
UNSAFE = re.compile(r"delete|erase|restore|quit|install|update|remove|empty|reset|clear|revert|partition|format disk|"
                    r"unmount|eject|sign|log out|import|open|choose|location|restart|shut|share|send|email|mail|publish|upload|purchase|buy|subscribe", re.I)
APPS = {  # dump stem -> localized app name (training apps that have document dialogs)
    "textedit": "TextEdit", "stickies": "Stickies", 
    "fontbook": "Font Book", "quicktimeplayer": "QuickTime Player",
    "scripteditor": "Script Editor", "grapher": "Grapher", "music": "Music", "maps": "Maps", "books": "Books",
}
PERSONAL = re.compile(r"/|~|@|alexi|canamo|desktop|downloads|documents|icloud|recents|airdrop|\.(pdf|png|jpe?g|txt|rtf|docx?)\b", re.I)

def press(app, what, out):
    try:
        subprocess.run(["open", "-W", "-n", APP, "--args", "--press", app, what, out], timeout=25, capture_output=True)
    except subprocess.TimeoutExpired:
        subprocess.run(["pkill", "-f", "ScreenGuide.app/Contents/MacOS/ScreenGuide --press"])
        return None
    try:
        return json.load(open(out))
    except Exception:
        return None

def clean(state, before_keys):
    """Controls that appeared with the dialog (not in the window before), with safe labels only."""
    out = []
    for c in state["candidates"]:
        if c["source"] != "window" or c["role"] in ("row", "menu button"):
            continue
        key = f'{c["role"]} "{c["label"]}" · {c["context"]}'
        if key in before_keys or PERSONAL.search(c["label"]) or PERSONAL.search(c["context"]) or len(c["label"]) > 40:
            continue
        out.append({"role": c["role"], "label": c["label"], "context": re.sub(r".* dialog$", "dialog", c["context"])})
    return out

def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for stem, name in APPS.items():
        if stem in HELD_OUT or stem in VAL_APPS:
            continue
        dump = next((json.load(open(f"/tmp/sg/{d}/{stem}.json")) for d in ("train", "train2")
                     if os.path.exists(f"/tmp/sg/{d}/{stem}.json")), None)
        if not dump or "commands" not in dump:
            continue
        was_running = subprocess.run(["pgrep", "-xq", name]).returncode == 0
        if was_running:
            print(f"{name}: already open with your work — skipped", flush=True)
            continue
        subprocess.run(["open", "-a", name]); time.sleep(4)
        paths = [c["path"] for c in dump["commands"]]
        # Blank documents only in plain document apps (elsewhere "New" makes real events, boards or recordings).
        if stem in ("textedit", "scripteditor", "grapher") and ("File > New" in paths or any(p.startswith("File > New ") for p in paths)):
            press(name, next(p for p in paths if p == "File > New" or p.startswith("File > New ")), "/tmp/sg/_new.json"); time.sleep(1.5)
        items = [p for p in paths if p.endswith("…") and SAFE.search(p.split(" > ")[-1]) and not UNSAFE.search(p)][:8]
        base = press(name, "button:__none__", "/tmp/sg/_base.json")
        base_titles = (base or {}).get("state", {}).get("windowTitles", [])
        seen_sets = set()
        before = {f'{c["role"]} "{c["label"]}" · {c["context"]}' for c in (base or {}).get("state", {}).get("candidates", [])}
        got = 0
        for path in items:
            r = press(name, path, "/tmp/sg/_dlg.json")
            if not r or not r.get("pressed"):
                continue
            controls = clean(r["state"], before)
            sig = tuple(sorted(c["role"] + c["label"] for c in controls))
            if len(controls) >= 3 and sig not in seen_sets:
                seen_sets.add(sig)
                json.dump({"app": name, "stem": stem, "opened_by": path, "controls": controls},
                          open(os.path.join(out_dir, f"{stem}__{got}.json"), "w"), indent=1, ensure_ascii=False)
                got += 1
            # Escape closes sheets/panels without choosing anything; then make sure nothing extra stays open.
            for b in ("key:escape", "button:Cancel", "button:Close", "button:close button"):
                res = press(name, b, "/tmp/sg/_close.json")
                if res and set(res["state"]["windowTitles"]) <= set(base_titles):
                    break
            time.sleep(0.6)
        print(f"{name}: {got} dialogs from {len(items)} safe items", flush=True)
        # Only apps this script launched (blank documents it created): discard those and quit.
        subprocess.run(["osascript", "-e", f'tell application "{name}" to quit saving no'], capture_output=True)

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/sg/dialogs")
