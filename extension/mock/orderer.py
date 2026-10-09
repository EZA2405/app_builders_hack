"""Dev-only stand-in for the local model: asks Claude Code or Codex for the next step.

This sends a sanitized element list to a hosted model, so it is for testing the
extension while the Mac app is unfinished. It is never the product's decision path.
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


async def ask(model_cmd, text, session=None):
    """Returns (decision dict or None, seconds)."""
    start = time.monotonic()
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
    print("ok")
