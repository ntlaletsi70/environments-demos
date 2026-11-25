#!/usr/bin/env python3
"""
Records a demo of the Environments UI via Chrome DevTools Protocol (CDP).
Drives the UI to:
  1. Create Environment via form
  2. Watch reconciliation in Resources panel
  3. Trigger Build
  4. Watch BuildRun progress
  5. Promote Canary deployment

Screenshots assembled into demo.gif by gif.py.
"""

import json
import subprocess
import time
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from cdp import Chrome


def resource_count(kind, namespace="blanketops-environments", env_name="demo-app"):
    """Count resources of a kind with the environment label."""
    out = subprocess.run(
        ["kubectl", "get", kind, "-n", namespace,
         "-l", f"environments.blanketops.dev/name={env_name}", "--no-headers"],
        capture_output=True, text=True,
    ).stdout.strip()
    return 0 if not out else len(out.splitlines())


FRAMES_DIR = "frames"
UI_URL = "http://localhost:5173"  # Vite dev server
ENV_NAME = "demo-app"
NAMESPACE = "blanketops-environments"
APP_NAME = "demo-app"
ENV_TYPE = "STAGING"
VERSION = "v1.0.0"
BRANCH = "main"
GIT_OWNER = "blanketops"
GIT_REPO = "demo-app"
TARGET_CLUSTER = "kind-workload"
VAULT_ADDR = "http://vault.vault.svc.cluster.local:8200"
VAULT_PATH = "secret/data/blanketops/environments"
VAULT_ROLE = "blanketops-environments"


def shot(tab, n, name):
    path = f"{FRAMES_DIR}/{n:03d}-{name}.png"
    try:
        tab.screenshot(path)
        print(f"captured {path}")
        return n + 1
    except Exception as e:
        print(f"skipped {path}: {e}")
        return n


def main():
    subprocess.run(["mkdir", "-p", FRAMES_DIR], check=True)

    chrome = Chrome()
    try:
        tab = chrome.new_tab(UI_URL)
        time.sleep(2)  # wait for UI to load

        n = 0
        n = shot(tab, n, "00-idle-dashboard")

        # 1. Navigate to Environments page and create new
        print("-- navigating to Environments page --")
        tab.eval("window.location.hash = '#/environments'")
        time.sleep(1)
        n = shot(tab, n, "01-environments-page")

        print("-- clicking New Environment button --")
        tab.eval("""
            const btn = document.querySelector('button:has-text("New Environment")');
            if (btn) btn.click();
        """)
        time.sleep(1)
        n = shot(tab, n, "02-new-environment-form")

        print("-- filling Environment form --")
        tab.eval(f"""
            document.getElementById('name').value = '{ENV_NAME}';
            document.getElementById('namespace').value = '{NAMESPACE}';
            document.getElementById('applicationName').value = '{APP_NAME}';
            document.getElementById('environmentType').value = '{ENV_TYPE}';
            document.getElementById('version').value = '{VERSION}';
            document.getElementById('branch').value = '{BRANCH}';
            document.getElementById('gitOwner').value = '{GIT_OWNER}';
            document.getElementById('gitRepository').value = '{GIT_REPO}';
            document.getElementById('targetCluster').value = '{TARGET_CLUSTER}';
            document.getElementById('secretStoreProvider').value = 'vault';
            document.getElementById('vaultAddress').value = '{VAULT_ADDR}';
            document.getElementById('vaultPath').value = '{VAULT_PATH}';
            document.getElementById('vaultRole').value = '{VAULT_ROLE}';
        """)
        time.sleep(1)
        n = shot(tab, n, "03-form-filled")

        print("-- submitting form --")
        tab.eval("document.getElementById('env-form').requestSubmit()")
        time.sleep(2)
        n = shot(tab, n, "04-submitted")

        # 2. Watch reconciliation in Resources panel
        print("-- waiting for reconciliation --")
        for i in range(30):
            time.sleep(5)
            n = shot(tab, n, f"05-reconcile-progress-{i:02d}")
            # Check if Build, Package, ServiceUnit appear
            if resource_count("build") > 0 and resource_count("package") > 0:
                print("Resources created!")
                break

        # 3. Trigger a Build
        print("-- triggering Build --")
        tab.eval("window.location.hash = '#/builds'")
        time.sleep(1)
        n = shot(tab, n, "06-builds-page")

        tab.eval("""
            const btn = document.querySelector('button:has-text("Trigger Build")');
            if (btn) btn.click();
        """)
        time.sleep(1)
        n = shot(tab, n, "07-trigger-build-modal")

        tab.eval("""
            document.getElementById('buildName').value = 'demo-app-build';
            document.getElementById('revision').value = 'v1.1.0-rc.1';
            document.getElementById('triggeredBy').value = 'demo-user';
            document.getElementById('trigger-build-form').requestSubmit();
        """)
        time.sleep(2)
        n = shot(tab, n, "08-build-triggered")

        # 4. Watch BuildRun
        print("-- watching BuildRun --")
        for i in range(20):
            time.sleep(5)
            n = shot(tab, n, f"09-buildrun-progress-{i:02d}")

        # 5. Promote Canary
        print("-- promoting Canary --")
        tab.eval("window.location.hash = '#/deployments'")
        time.sleep(1)
        n = shot(tab, n, "10-deployments-page")

        tab.eval("""
            const btn = document.querySelector('button:has-text("Promote")');
            if (btn) btn.click();
        """)
        time.sleep(1)
        n = shot(tab, n, "11-promote-modal")

        tab.eval("""
            document.getElementById('canaryWeight').value = '100';
            document.getElementById('promote-form').requestSubmit();
        """)
        time.sleep(2)
        n = shot(tab, n, "12-promoted")

        print(f"done, {n} frames in {FRAMES_DIR}/")

    finally:
        chrome.close()


if __name__ == "__main__":
    main()