"""Dev stand-in for the Mac app's planner: picks the next web step for the extension.

- jev / laya: the same typed-choice request, element format and 16-wide tournament as
  app/Sources/ScreenGuide/Planner.swift and ml/web_data.py, so a fine-tuned Laya drops in.
  `laya` stays on this Mac (laya-serve, 127.0.0.1:8766); `jev` is hosted TypeSafe Jev.
- claude / codex: free-text planners for comparison.
Anything sent to a hosted model is sanitized first. Hosted modes are for testing only.
"""
import asyncio
import json
import re
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlsplit

sys.path.insert(0, str(Path(__file__).parents[2] / "ml"))
from make_fixtures import is_personal, redact_names  # noqa: E402  (AGENTS.md rule 1: all cloud-bound data goes through these)

EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
# Phones, card and account numbers; ponytail: digit runs only, names of people still pass if not caught by is_personal.
NUMBER = re.compile(r"\+?\d[\d\s().-]{6,}\d")


def clean(text):
    return NUMBER.sub("#", EMAIL.sub("[email]", redact_names(text or "")))


def sanitize(snapshot):
    """Keep only what the model needs; field values, positions and query strings never leave the Mac."""
    url = urlsplit(snapshot.get("url") or "")
    elements = [{"ref": e["ref"], "role": e.get("role"), "name": clean(e.get("name")), "context": clean(e.get("context")),
                 "in_viewport": e.get("in_viewport"), "enabled": e.get("enabled", True)}
                for e in snapshot.get("elements", []) if not is_personal({"path": e.get("name") or ""})]
    # Snapshots arrive on-screen first; 150 rows keep the prompt small, which is most of the latency.
    return {"title": clean(snapshot.get("title")), "url": clean(url.netloc + url.path), "elements": elements[:150]}


JEV_URL = "https://api.typesafe.ai/v1/systemone"
LAYA_URL = "http://127.0.0.1:8766/v1/systemone"
GROUP, KEEP = 16, 3          # Planner.swift tournament
NOT_SURE = 0.3               # Planner.swift: below this, show the runner-up too
FINAL = {"OK", "Done", "Save", "Export", "Print", "Apply", "Send", "Continue", "Close"}  # GuideEngine.isFinal
TEXT_ROLES = ("textbox", "searchbox", "combobox")


def jev_key():
    """TypeSafe key from the environment, ml/.env (repo convention) or ~/.config/jev/jev.env. Never printed."""
    import os
    for name in ("JEV_API_KEY", "TYPESAFE_API_KEY"):
        if os.environ.get(name):
            return os.environ[name]
    for path in (Path(__file__).parents[2] / "ml/.env", Path.home() / ".config/jev/jev.env"):
        if path.exists():
            for line in path.read_text().splitlines():
                name, _, value = line.partition("=")
                if name.strip() in ("JEV_API_KEY", "TYPESAFE_API_KEY") and value.strip():
                    return value.strip().strip("'\"")
    raise SystemExit("No Jev key: set JEV_API_KEY or put it in ml/.env")


def element_key(e):
    # ml/web_data.element_id: what the model was trained to choose between.
    return f'{e["role"]} "{e["name"]}" · {e["context"]}' if e.get("context") else f'{e["role"]} "{e["name"]}"'


def state_text(page, goal, done):
    # ml/build_trainset.state_for with ml/web_data.site_label as the "app".
    s = f'A non-technical person is using the Mac app web browser, on the website "{page["title"][:60]}". Their goal: "{goal}"'
    return s + (" Already done: " + "; ".join(done) + "." if done else "")


def phrase(e):
    """Deterministic wording, like GuideEngine.phrase(): typed-choice models pick, they don't write."""
    name = e["name"] if len(e["name"]) <= 40 else e["name"][:39] + "…"
    hint = f"It's in {e['context']}." if e.get("context") else ""
    if e["role"] in TEXT_ROLES:
        return f"Click the **{name}** box, type what you want, then press **Enter**.", hint
    if e["role"] in ("checkbox", "switch"):
        return f"Click **{name}** to turn it on or off.", hint
    return f"Click **{name}**.", hint


async def choose(url, model, key, state, options):
    import urllib.request
    body = {"model": model, "state": state, "questions": {"next_command": {
        "type": "choice", "instructions": "Which element on this page should the person use next?",
        "criteria": {o: o for o in options}}}}
    headers = {"Content-Type": "application/json", **({"Authorization": f"Bearer {key}"} if key else {})}

    def post():
        request = urllib.request.Request(url, data=json.dumps(body).encode(), headers=headers)
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    answer = (await asyncio.to_thread(post)).get("answers", {}).get("next_command", {})
    probs = answer.get("probabilities") or {}
    return answer.get("choice") or max(probs, key=probs.get), answer.get("confidence", 0.0), probs


async def typed_decide(mode, goal, done, page):
    """Tournament over the page like Planner.choose; returns the same decision shape as the free-text planners."""
    url, model, key = (LAYA_URL, "guide", None) if mode == "laya" else (JEV_URL, "jev-latest", jev_key())
    by_key = {}
    for e in page["elements"]:
        if e["enabled"] and e["name"]:
            by_key.setdefault(element_key(e), e)
    keys = list(by_key)
    if not keys:
        return None
    state = state_text(page, goal, done)
    while len(keys) > GROUP:
        rounds = await asyncio.gather(*(choose(url, model, key, state, keys[i:i + GROUP]) for i in range(0, len(keys), GROUP)))
        keys = [k for _, _, probs in rounds for k in sorted(probs, key=probs.get, reverse=True)[:KEEP]]
    best, confidence, probs = await choose(url, model, key, state, keys)
    ranked = sorted(probs, key=probs.get, reverse=True)
    e = by_key.get(best) or by_key[ranked[0]]
    done_text = f"clicked {element_key(e)}"
    # Picking something already clicked means nothing new is left: the goal is reached.
    if done_text in done:
        return {"done": True, "message": "All done.", "confidence": confidence}
    text, hint = phrase(e)
    decision = {"ref": e["ref"], "instruction": text, "hint": hint, "done_text": done_text,
                "final": e["name"] in FINAL, "confidence": round(confidence, 2)}
    if confidence < NOT_SURE and len(ranked) > 1:
        decision.update(candidates=[e["ref"], by_key[ranked[1]]["ref"]], instruction="I think it's one of these two.",
                        hint="Just click the one you think is right.")
    return decision


def prompt(goal, done, page, note=""):
    rows = "\n".join(f"{e['ref']} | {e['role']} | {e['name']} | {e['context'] or ''} | {'yes' if e['in_viewport'] else 'no'}"
                     + ("" if e["enabled"] else " | disabled") for e in page["elements"])
    steps = "\n".join(f"{i}. {s}" for i, s in enumerate(done, 1)) or "(none yet)"
    return f"""You guide an older, non-technical person through a task in Chrome, one click at a time.
You point; they click. Pick the single next element they should click (or type into).

Goal: {goal}
Steps already done:
{steps}
Page: {page['title']} ({page['url']})
{('Note: ' + note) if note else ''}
Interactive elements (ref | role | name | context | on screen):
{rows}

Reply with JSON only, exactly one of:
{{"ref": "e12", "instruction": "Click **Search**.", "hint": "It's the box at the top of the page."}}
{{"candidates": ["e3", "e7"], "instruction": "Click one of these two.", "hint": "..."}}  (only if truly unsure between 2-3)
{{"done": true, "message": "All done."}}  (when the goal is already reached on this page)

Rules: use only refs from the list. Instruction at most 12 words, calm and plain, with the key word in **bold**.
For typing, point at the box and say it all in one step: "Click the **Search** box, type **cats**, then press **Enter**."
Never repeat a step that is already done. Prefer elements that are on screen. No jargon."""


class ClaudeSession:
    """One long-running `claude -p` per goal: skips the CLI's ~3s start-up on every step and remembers earlier steps."""

    def __init__(self, model):
        self.model = model
        self.proc = None
        self.lock = asyncio.Lock()  # Turns share one stdout; a stale step must finish before the next is read.
        self.ready = asyncio.get_running_loop().create_task(self._start())

    async def _start(self):
        # No tools, no user settings or hooks: a plain text completion.
        self.proc = await asyncio.create_subprocess_exec(
            "claude", "-p", "--model", self.model, "--setting-sources", "", "--tools", "",
            "--input-format", "stream-json", "--output-format", "stream-json", "--verbose",
            stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL, limit=2**24)
        await self._turn("Reply with OK. Guidance requests follow.")  # Warm up so the first real step is fast.

    async def _turn(self, text):
        self.proc.stdin.write((json.dumps({"type": "user", "message": {"role": "user", "content": text}}) + "\n").encode())
        await self.proc.stdin.drain()
        while line := await self.proc.stdout.readline():
            event = json.loads(line)
            if event.get("type") == "result":
                return event.get("result") or ""
        raise RuntimeError("claude session ended")

    async def ask(self, text):
        await self.ready
        async with self.lock:
            return await self._turn(text)

    def close(self):
        self.ready.cancel()
        if self.proc and self.proc.returncode is None:
            self.proc.kill()


async def ask(model_cmd, text, session=None, typed=None):
    """Returns (decision dict or None, seconds). `typed` = (goal, done, page) for jev/laya."""
    start = time.monotonic()
    if model_cmd in ("jev", "laya"):
        return await typed_decide(model_cmd, *typed), time.monotonic() - start
    if session:
        return parse(await session.ask(text)), time.monotonic() - start
    if model_cmd == "codex":
        out = tempfile.NamedTemporaryFile(suffix=".txt", delete=False).name
        cmd = ["codex", "exec", "--skip-git-repo-check", "--ephemeral", "--ignore-user-config", "-s", "read-only", "-o", out, "-"]
    else:
        out = None
        # No tools, no user settings or hooks: a plain text completion.
        cmd = ["claude", "-p", "--model", model_cmd.split(":", 1)[1] if ":" in model_cmd else "haiku",
               "--setting-sources", "", "--tools", ""]
    proc = await asyncio.create_subprocess_exec(*cmd, stdin=asyncio.subprocess.PIPE,
                                                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL)
    stdout, _ = await proc.communicate(text.encode())
    reply = Path(out).read_text() if out else stdout.decode()
    return parse(reply), time.monotonic() - start


def parse(reply):
    match = re.search(r"\{.*\}", reply, re.S)
    try:
        return json.loads(match.group(0)) if match else None
    except ValueError:
        return None


if __name__ == "__main__":
    page = sanitize({"url": "https://mail.example.com/inbox?q=secret", "title": "Inbox - rosa@example.com", "elements": [
        {"ref": "e1", "role": "button", "name": "Compose", "context": "Mail", "in_viewport": True, "value": "x"},
        {"ref": "e2", "role": "link", "name": "rosa@example.com", "in_viewport": True},
        {"ref": "e3", "role": "link", "name": "Call +63 917 555 0142", "in_viewport": False},
    ]})
    assert page["url"] == "mail.example.com/inbox" and "rosa" not in json.dumps(page), page
    assert [e["ref"] for e in page["elements"]] == ["e1", "e3"] and page["elements"][1]["name"] == "Call #", page
    assert "value" not in page["elements"][0]
    assert parse('Sure:\n{"ref": "e1", "instruction": "Click **Compose**."}') == {"ref": "e1", "instruction": "Click **Compose**."}
    e = {"ref": "e9", "role": "searchbox", "name": "Search Wikipedia", "context": "Header", "in_viewport": True, "enabled": True}
    assert element_key(e) == 'searchbox "Search Wikipedia" · Header'
    assert phrase(e)[0] == "Click the **Search Wikipedia** box, type what you want, then press **Enter**."
    assert state_text({"title": "Wikipedia"}, "look up Manila", ["clicked x"]) == \
        'A non-technical person is using the Mac app web browser, on the website "Wikipedia". Their goal: "look up Manila" Already done: clicked x.'
    print("ok")
