"""Minimal Chrome DevTools Protocol (CDP) client for recording demos."""
import json
import subprocess
import time
import websocket
import uuid


class Chrome:
    def __init__(self, port=9222):
        self.port = port
        self.ws = None
        self.msg_id = 0
        self._connect()

    def _connect(self):
        # Get websocket debugger URL
        resp = subprocess.run(
            ["curl", "-s", f"http://localhost:{self.port}/json/version"],
            capture_output=True, text=True, check=True
        )
        data = json.loads(resp.stdout)
        self.ws_url = data["webSocketDebuggerUrl"]

        self.ws = websocket.create_connection(self.ws_url)
        # Enable required domains
        self._send("Runtime.enable", {})
        self._send("Page.enable", {})
        self._send("Target.setAutoAttach", {"autoAttach": True, "waitForDebuggerOnStart": False, "flatten": True})

    def _send(self, method, params=None):
        self.msg_id += 1
        msg = {"id": self.msg_id, "method": method, "params": params or {}}
        self.ws.send(json.dumps(msg))
        return self.msg_id

    def _recv(self, target_id=None):
        while True:
            raw = self.ws.recv()
            msg = json.loads(raw)
            if target_id and msg.get("targetId") != target_id:
                continue
            if "id" in msg and msg["id"] == self.msg_id:
                return msg.get("result", {})
            if "method" in msg:
                return msg

    def new_tab(self, url):
        """Open a new tab and navigate to URL."""
        # Create target
        resp = self._send("Target.createTarget", {"url": url})
        target_id = resp.get("targetId")

        # Attach to target
        self._send("Target.attachToTarget", {"targetId": target_id, "flatten": True})

        # Wait for navigation
        time.sleep(1)
        return Tab(self, target_id)

    def close(self):
        if self.ws:
            self.ws.close()


class Tab:
    def __init__(self, chrome, target_id):
        self.chrome = chrome
        self.target_id = target_id

    def eval(self, expression):
        """Evaluate JavaScript in the tab."""
        self.chrome._send("Runtime.evaluate", {
            "expression": expression,
            "targetId": self.target_id,
            "returnByValue": True,
            "awaitPromise": True,
        })
        return self.chrome._recv(self.target_id)

    def screenshot(self, path):
        """Capture screenshot and save to path."""
        resp = self.chrome._send("Page.captureScreenshot", {
            "format": "png",
            "targetId": self.target_id,
        })
        import base64
        img_data = base64.b64decode(resp.get("data", ""))
        with open(path, "wb") as f:
            f.write(img_data)