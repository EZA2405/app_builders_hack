#!/usr/bin/env python3
"""Interactive, loopback-only stand-in for the ScreenGuide Mac app."""
import argparse
import asyncio
import base64
import hashlib
import json
import os
import sys
from http import HTTPStatus
from pathlib import Path

from websockets.legacy.server import serve


def extension_id():
    manifest = json.loads((Path(__file__).parents[1] / "manifest.json").read_text())
    digest = hashlib.sha256(base64.b64decode(manifest["key"])).hexdigest()[:32]
    return "".join(chr(ord("a") + int(char, 16)) for char in digest)


class MockApp:
    def __init__(self):
        self.socket = None
        self.elements = []
        self.serial = 0

    async def send(self, kind, **fields):
        if self.socket is None:
            print("No extension connected.", flush=True)
            return
        self.serial += 1
        await self.socket.send(json.dumps({"type": kind, "id": str(self.serial), **fields}))

    async def command(self, line):
        parts = line.strip().split()
        if not parts:
            return
        if parts[0] == "snap":
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
                    elif kind == "snapshot":
                        self.elements = message["elements"]
                        print(f"\n{message['title']} ({message['ms']:.1f}ms)", flush=True)
                        print("ref | role | name | context | in_viewport", flush=True)
                        for element in self.elements:
                            print(" | ".join(str(element.get(key, "")) for key in
                                             ("ref", "role", "name", "context", "in_viewport")), flush=True)
                    elif kind != "ping":
                        print(json.dumps(message, ensure_ascii=False), flush=True)
                except (ValueError, KeyError, TypeError):
                    print("Ignored malformed message.", flush=True)
        finally:
            if self.socket is socket:
                self.socket = None
            print("Extension disconnected.", flush=True)


async def main(origin):
    app = MockApp()
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

    async with serve(app.handler, "127.0.0.1", 47823, origins=[origin], process_request=check_path):
        print(f"Listening on ws://127.0.0.1:47823/ext for {origin}", flush=True)
        print("Commands: snap, hl <ref>, clear, notsure <ref> <ref> <ref>, or a keyword", flush=True)
        while True:
            try:
                await app.command(await commands.get())
            except Exception as error:
                print(f"Command failed: {error}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extension-id", help="Override the ID derived from manifest.json")
    args = parser.parse_args()
    try:
        asyncio.run(main(f"chrome-extension://{args.extension_id or extension_id()}"))
    except KeyboardInterrupt:
        pass
