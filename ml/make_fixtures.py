"""Turn ScreenGuide --dump snapshots into benchmark fixtures (commands + goals).

Only menu commands and toolbar controls go into fixtures: no file names or page
content, so fixtures are safe to send to a hosted comparison model.

Usage: python3 make_fixtures.py /tmp/sg   (expects finder.json, systemsettings.json, safari.json, preview.json)
"""
import json, os, re, sys

# goal -> acceptable answers. Written before looking at model output.
GOALS = {
    "preview": {
        "make this photo smaller so I can email it": ["Tools > Adjust Size…"],
        "turn the picture the right way up, it's sideways": ["Tools > Rotate Left", "Tools > Rotate Right", "Toolbar > Rotate"],
        "save a copy as a JPEG": ["File > Export As…"],
        "black out my address on this picture": ["Tools > Redact"],
        "print this": ["File > Print…"],
        "cut out just my face from the picture": ["Tools > Crop", "Tools > Rectangular Selection"],
        "make a copy of this file": ["File > Duplicate"],
        "I want to draw a circle on the photo": ["Tools > Annotate > Oval", "View > Show Markup Toolbar"],
        "where was this photo taken?": ["Tools > Show Location Info"],
        "make the picture bigger on my screen": ["View > Zoom In", "View > Enter Full Screen", "Toolbar > zoom in"],
    },
    "finder": {
        "make a new folder": ["File > New Folder"],
        "put this file in the trash": ["File > Move to Trash"],
        "I can't find a document I downloaded, search for it": ["File > Find", "Toolbar > Search"],
        "show my files as a list with dates": ["View > as List"],
        "empty the trash": ["Finder > Empty Trash"],
        "shrink this file into a zip to send it": ["File > Compress"],
        "change the name of this file": ["File > Rename"],
        "show me my applications": ["Go > Applications"],
    },
    "systemsettings": {
        "make the text bigger on my screen": ["View > Displays", "View > Accessibility"],
        "connect to wifi": ["View > Wi‑Fi"],
        "turn on bluetooth for my headphones": ["View > Bluetooth"],
        "make the screen brighter": ["View > Displays"],
        "change my desktop picture": ["View > Wallpaper"],
        "the sound is too quiet": ["View > Sound"],
        "add a printer": ["View > Printers & Scanners"],
        "update my mac": ["View > Software Update", "Toolbar > Software Update", "Software Update"],
    },
    "safari": {
        "make the words on this page bigger": ["View > Zoom In"],
        "go back to the page I was on": ["History > Back", "Toolbar > Go back"],
        "save this page to read later": ["Bookmarks > Add to Reading List", "Toolbar > Add page to Reading List"],
        "open a new tab": ["File > New Tab", "Toolbar > New Tab"],
        "bookmark this page": ["Bookmarks > Add Bookmark…"],
        "print this page": ["File > Print…"],
        "find a word on this page": ["Edit > Find > Find…"],
        "clear my browsing history": ["History > Clear History…"],
        "reopen the window I just closed": ["History > Reopen Last Closed Window"],
    },
}

PERSONAL_SUBMENUS = ("recent", "recently", "favorites", "bookmarks bar", "reading list")
STATIC_HISTORY = {"Back", "Forward", "Home", "Show All History", "Search Results SnapBack", "Clear History…",
                  "Reopen Last Closed Window", "Reopen All Windows from Last Session"}
STATIC_WINDOW_PREFIXES = ("Close", "Minimize", "Zoom", "Fill", "Center", "Move & Resize", "Full Screen Tile", "Remove Window",
                          "Bring All to Front", "Arrange in Front", "Merge All Windows", "Move Tab", "Show ", "Hide ", "Pin Tab",
                          "Enter Full Screen", "Move Window", "Tile", "Window")

PERSONAL_PATTERNS = re.compile(r"@|[’']s (iPhone|iPad|Mac|MacBook|Apple Watch|AirPods)|^Account > (?!Sign|View|Manage|Settings|Redeem|Purchased|Wish|Family|Authori)")

def is_personal(c):
    """Menu entries that are user data (recent files, page titles, window names, accounts, devices), not app commands."""
    parts = c["path"].split(" > ")
    if PERSONAL_PATTERNS.search(c["path"]) or " — " in parts[-1]:
        return True
    if any(any(k in p.lower() for k in PERSONAL_SUBMENUS) for p in parts[1:-1]):
        return parts[-1] != "Clear Menu"
    if parts[0] == "History" and len(parts) >= 3:
        return True  # dated history submenus = visited page titles
    if parts[0] == "History" and len(parts) == 2:
        return parts[-1] not in STATIC_HISTORY and not c.get("shortcut")
    if parts[0] == "Bookmarks" and len(parts) >= 2:
        return not (c.get("shortcut") or parts[-1].endswith("…") or parts[-1].split()[0] in {"Show", "Hide", "Add", "Edit", "Import", "Export", "Bookmarks"})
    if parts[0] == "Window" and len(parts) == 2:
        return not parts[-1].startswith(STATIC_WINDOW_PREFIXES)
    return False

def redact_names(path):
    """Finder/others embed the selected item's name: 'File > Rename “contract.pdf”…' -> 'File > Rename “item”…'."""
    return re.sub(r"“[^”]*”", "“item”", path)

def startswith_any(cmd, prefixes):
    # Finder appends "…" or "“name”" to some items (e.g. 'File > Rename “x.pdf”…'), so match by prefix.
    return any(cmd == p or cmd.startswith(p) for p in prefixes)

def main(src):
    for name, goals in GOALS.items():
        d = json.load(open(os.path.join(src, f"{name}.json")))
        dropped = [c["path"] for c in d["commands"] if is_personal(c)]
        cmds = [redact_names(c["path"]) for c in d["commands"] if not is_personal(c)]
        toolbar = ["Toolbar > " + c["label"] for c in d["controls"] if c["path"].lower().startswith("toolbar")]
        # System Settings panes are visible buttons, not in a toolbar; include its window buttons (no user data).
        extra = [c["label"] for c in d["controls"] if name == "systemsettings" and c["role"] == "AXButton"
                 and "arrow" not in c["label"] and "page button" not in c["label"]]
        commands = list(dict.fromkeys(cmds + toolbar + extra))
        expanded = {}
        for g, ok in goals.items():
            hits = [c for c in commands if startswith_any(c, ok)]
            expanded[g] = hits
            if not hits:
                print(f"!! {name}: no command matches {ok} for goal {g!r}")
        out = {"app": d["app"], "source": f"real accessibility dump of {d['app']} via ScreenGuide --dump (menus + toolbar only)",
               "commands": commands, "goals": expanded}
        json.dump(out, open(f"fixtures/{name}_real.json", "w"), indent=1, ensure_ascii=False)
        print(f"{name}: {len(commands)} commands, {len(goals)} goals, {len(dropped)} personal entries removed")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/sg")
