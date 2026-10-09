#!/usr/bin/env python3
"""Interactive, loopback-only stand-in for the ScreenGuide Mac app."""
import argparse
import asyncio
import base64
import hashlib
import json
import os
import sys
import time
from http import HTTPStatus
from pathlib import Path
from urllib.parse import urlsplit

from websockets.exceptions import ConnectionClosed
from websockets.legacy.server import serve


def extension_id():
    manifest = json.loads((Path(__file__).parents[1] / "manifest.json").read_text())
    digest = hashlib.sha256(base64.b64decode(manifest["key"])).hexdigest()[:32]
    return "".join(chr(ord("a") + int(char, 16)) for char in digest)


class MockApp:
    def __init__(self, orderer=None):
        self.socket = None
        self.elements = []
        self.serial = 0
        # Guided mode (--orderer): goal, steps done, current target, pending re-decision.
        self.orderer = orderer
        self.goal = None
        self.done = []
        self.current = None
        self.note = ""
        self.want_decision = False
        self.empty_retries = 0
        self.timer = None
        self.turn = 0
        self.host = None
        self.last_target_click = 0.0
        self.session = None  # Claude session for the current goal
        self.spare = None    # warmed-up session for the next goal

    def warm(self):
        if self.orderer and self.orderer.startswith("claude") and not self.spare:
            import orderer
            self.spare = orderer.ClaudeSession(self.orderer.split(":", 1)[1] if ":" in self.orderer else "haiku")

    async def send(self, kind, **fields):
        if self.socket is None:
            print("No extension connected.", flush=True)
            return
        self.serial += 1
        await self.socket.send(json.dumps({"type": kind, "id": str(self.serial), **fields}))

    async def command(self, line):
        line = line.strip()
        parts = line.split()
        if not parts:
            return
        if parts[0] == "goal" and len(parts) > 1:
            await self.start(line[5:].strip())
        elif parts[0] == "snap":
            await self.send("snapshot_request")
        elif parts[0] == "clear":
            await self.send("clear")
        else:
            refs = parts[1:] if parts[0] in ("hl", "notsure") else []
            if not refs:
                found = next((e for e in self.elements if line.lower() in e["name"].lower()), None)
                if not found:
                    print("No matching element. Try snap, hl <ref>, clear, or notsure <refs>.", flush=True)
                    return
                refs = [found["ref"]]
            element = next((e for e in self.elements if e["ref"] == refs[0]), {})
            fields = {"ref": refs[0], "instruction": f"Click **{element.get('name', refs[0])}**"}
            if parts[0] == "notsure":
                fields["candidates"] = refs
            await self.send("highlight", **fields)

    async def start(self, goal):
        if not self.orderer:
            print("Start with --orderer claude (or codex) to guide a goal.", flush=True)
            return
        self.goal, self.done, self.current, self.note = goal, [], None, ""
        self.host, self.last_target_click = None, 0.0
        if self.session:
            self.session.close()
        self.warm()
        self.session, self.spare = self.spare, None
        self.warm()  # Fresh context per goal; the next one boots in the background.
        await self.send("status", text="Working out the first step…")
        print(f"Goal: {goal}", flush=True)
        self.schedule(0)

    def schedule(self, delay, note=""):
        """Re-snapshot after the page settles, then ask the orderer; a newer request replaces an older one."""
        if self.timer:
            self.timer.cancel()
        self.note = note or self.note
        self.turn += 1  # Any decision still in flight is now stale.

        async def later():
            await asyncio.sleep(delay)
            self.want_decision = True
            await self.send("snapshot_request")
        self.timer = asyncio.create_task(later())

    async def decide(self, snapshot):
        import orderer
        turn = self.turn
        if not snapshot["elements"] and self.empty_retries < 5:
            # Mid-navigation the new page's content script may not be ready yet.
            self.empty_retries += 1
            self.schedule(1)
            return
        self.empty_retries = 0
        page = orderer.sanitize(snapshot)
        note, self.note = self.note, ""
        decision, seconds = await orderer.ask(self.orderer, orderer.prompt(self.goal, self.done, page, note), self.session,
                                              (self.goal, self.done, page))
        if not self.goal or turn != self.turn:
            return
        print(f"Orderer ({seconds:.1f}s): {json.dumps(decision, ensure_ascii=False)}", flush=True)
        known = {e["ref"]: e for e in page["elements"]}
        if not decision:
            print("Orderer gave no usable answer; type goal again or press I'm stuck.", flush=True)
            return
        if decision.get("done") or len(self.done) >= 8:  # GuideEngine caps a goal at 8 steps
            await self.finish(str(decision.get("message") or "All done."))
            return
        refs = [r for r in decision.get("candidates") or [decision.get("ref")] if r in known]
        if not refs:
            print("Orderer picked a ref that isn't on the page; asking again.", flush=True)
            self.schedule(0, "Your last answer used a ref that is not in the list.")
            return
        self.current = {"refs": refs, "role": known[refs[0]]["role"], "final": decision.get("final"),
                        "instruction": str(decision.get("instruction") or f"Click **{known[refs[0]]['name']}**.")}
        self.current["done_text"] = decision.get("done_text") or self.current["instruction"].replace("**", "")
        fields = {"ref": refs[0], "instruction": self.current["instruction"], "step": len(self.done) + 1}
        if decision.get("hint"):
            fields["hint"] = str(decision["hint"])
        if len(refs) > 1:
            fields["candidates"] = refs
        if note.startswith("The user is stuck"):
            fields["style"] = "spotlight"
        await self.send("highlight", **fields)

    async def finish(self, text):
        print(f"Done: {text}", flush=True)
        self.goal = self.current = None
        await self.send("clear")
        await self.send("status", text=text, seconds=8)

    async def guide(self, message):
        """Advance the goal from extension events. Returns without effect when no goal is active."""
        kind = message["type"]
        if kind == "goal" and isinstance(message.get("text"), str) and message["text"].strip():
            await self.start(message["text"].strip()[:300])
        elif not self.goal:
            return
        elif kind == "snapshot" and self.want_decision:
            self.want_decision = False
            self.host = urlsplit(message.get("url") or "").hostname
            asyncio.create_task(self.decide(message))
        elif kind == "user_action" and message.get("on_target") and self.current and (
                message.get("kind") in ("submit", "change") or
                # A text box is finished by typing and Enter (submit/change/navigation), not by clicking into it.
                (message.get("kind") == "click" and self.current["role"] not in ("textbox", "searchbox", "combobox"))):
            self.done.append(self.current["done_text"])
            if self.current.get("final"):  # OK / Save / Send…: the last step of a task
                await self.finish("All done. You did it.")
                return
            self.current = None
            self.last_target_click = time.monotonic()
            await self.send("clear")
            await self.send("status", text="Working out the next step…")
            self.schedule(0.6)
        elif kind == "page_changed" and message.get("reason") in ("navigation", "spa_route"):
            host = urlsplit(message.get("url") or "").hostname
            if self.host and host != self.host and time.monotonic() - self.last_target_click > 10:
                # The user went to another site on their own; the old goal no longer applies.
                print(f"Left {self.host} for {host}; goal ended.", flush=True)
                self.goal = None
                await self.send("clear")
                return
            if self.current:  # e.g. Enter in a search box navigated before any change event
                self.done.append(self.current["done_text"])
                self.current = None
                self.last_target_click = time.monotonic()
                await self.send("status", text="Working out the next step…")
            self.schedule(0.8)
        elif kind == "highlight_error":
            self.schedule(0.5, f"Your last choice could not be shown ({message.get('reason')}); pick another.")
        elif kind == "card_button":
            button = message.get("button")
            if button == "stop":
                self.goal = None
                await self.send("status", text="")
                print("Stopped.", flush=True)
            elif button == "stuck":
                self.schedule(0, "The user is stuck on the last step. Pick again; the hint should say exactly where it is on screen.")
            elif button == "read_aloud" and self.current:
                # Local macOS speech; nothing leaves the Mac.
                await asyncio.create_subprocess_exec("say", self.current["instruction"].replace("**", ""))

    async def handler(self, socket, path):
        self.socket = socket
        self.elements = []
        print("Extension connected.", flush=True)
        try:
            async for raw in socket:
                try:
                    message = json.loads(raw)
                    kind = message["type"]
                    if kind == "hello":
                        await self.send("snapshot_request")
                        if self.orderer:
                            print("Type a goal in the ScreenGuide toolbar button, or here: goal <what to do>", flush=True)
                    elif kind == "snapshot":
                        self.elements = message["elements"]
                        if self.goal and self.want_decision:
                            print(f"Snapshot: {message['title']} ({len(self.elements)} elements, {message['ms']:.1f}ms)", flush=True)
                        else:
                            print(f"\n{message['title']} ({message['ms']:.1f}ms)", flush=True)
                            print("ref | role | name | context | in_viewport", flush=True)
                            for element in self.elements:
                                print(" | ".join(str(element.get(key, "")) for key in
                                                 ("ref", "role", "name", "context", "in_viewport")), flush=True)
                    elif kind != "ping":
                        print(json.dumps(message, ensure_ascii=False), flush=True)
                    await self.guide(message)
                except (ValueError, KeyError, TypeError):
                    print("Ignored malformed message.", flush=True)
        except ConnectionClosed:
            pass
        finally:
            if self.socket is socket:
                self.socket = None
            print("Extension disconnected.", flush=True)


async def main(origin, orderer):
    app = MockApp(orderer)
    commands = asyncio.Queue()
    loop = asyncio.get_running_loop()

    pending = ""

    def read_command():
        nonlocal pending
        chunk = os.read(sys.stdin.fileno(), 4096).decode()
        if not chunk:
            loop.remove_reader(sys.stdin)
            return
        pending += chunk
        while "\n" in pending:
            line, pending = pending.split("\n", 1)
            commands.put_nowait(line)

    loop.add_reader(sys.stdin, read_command)

    async def check_path(path, headers):
        if path != "/ext":
            return HTTPStatus.NOT_FOUND, [], b"Use /ext\n"

    app.warm()
    async with serve(app.handler, "127.0.0.1", 47823, origins=[origin], process_request=check_path):
        print(f"Listening on ws://127.0.0.1:47823/ext for {origin}", flush=True)
        print("Commands: snap, hl <ref>, clear, notsure <ref> <ref> <ref>, goal <text>, or a keyword", flush=True)
        if orderer:
            print(f"Orderer: {orderer}. " + ("Runs on this Mac." if orderer == "laya" else
                  "Sanitized element names go to a hosted model (dev testing only)."), flush=True)
        while True:
            try:
                await app.command(await commands.get())
            except Exception as error:
                print(f"Command failed: {error}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extension-id", help="Override the ID derived from manifest.json")
    parser.add_argument("--orderer", help="Pick each step with: jev (hosted TypeSafe Jev, same format as the Mac app's planner), "
                        "laya (local laya-serve on :8766, model 'guide'), claude (Haiku), claude:sonnet, or codex. "
                        "Hosted ones get a sanitized element list and are for testing only.")
    args = parser.parse_args()
    try:
        asyncio.run(main(f"chrome-extension://{args.extension_id or extension_id()}", args.orderer))
    except KeyboardInterrupt:
        pass
