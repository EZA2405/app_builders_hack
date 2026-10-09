"""Run with the mock's virtualenv: python -m unittest discover -s extension/tests."""
import asyncio
import json
import sys
import unittest
from pathlib import Path
from websockets.legacy.client import connect
from websockets.exceptions import InvalidStatusCode


class MockTest(unittest.IsolatedAsyncioTestCase):
    async def test_protocol_and_origin(self):
        script = Path(__file__).parents[1] / "mock/mock_app.py"
        proc = await asyncio.create_subprocess_exec(
            sys.executable, str(script), "--extension-id", "testid",
            stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE)
        try:
            await asyncio.wait_for(proc.stdout.readline(), 5)
            with self.assertRaises(InvalidStatusCode):
                async with connect("ws://127.0.0.1:47823/ext", origin="https://example.com"):
                    pass
            with self.assertRaises(InvalidStatusCode):
                async with connect("ws://127.0.0.1:47823/wrong", origin="chrome-extension://testid"):
                    pass
            async with connect("ws://127.0.0.1:47823/ext", origin="chrome-extension://testid") as socket:
                await socket.send(json.dumps({"type": "hello"}))
                self.assertEqual(json.loads(await socket.recv())["type"], "snapshot_request")
                await socket.send(json.dumps({"type": "snapshot", "title": "Test", "ms": 1,
                                              "elements": [{"ref": "e1", "name": "Captions"}]}))
                # Wait for the snapshot table before issuing the keyword.
                while b"e1 |" not in await proc.stdout.readline():
                    pass
                for command, expected in [("captions", "highlight"), ("snap", "snapshot_request"),
                                          ("hl e1", "highlight"), ("notsure e1 e2 e3", "highlight"),
                                          ("clear", "clear")]:
                    proc.stdin.write((command + "\n").encode())
                    await proc.stdin.drain()
                    message = json.loads(await asyncio.wait_for(socket.recv(), 2))
                    self.assertEqual(message["type"], expected)
                    if command.startswith("notsure"):
                        self.assertEqual(message["candidates"], ["e1", "e2", "e3"])
        finally:
            proc.terminate()
            await proc.wait()
