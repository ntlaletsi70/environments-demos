# BlanketOps Environments Demos

[![Demo 1](https://img.shields.io/badge/Demo_1-Env_Create-blue?style=flat-square)](1-env-create/)
[![Demo 2](https://img.shields.io/badge/Demo_2-Build_Trigger-green?style=flat-square)](2-build-trigger/)
[![Demo 3](https://img.shields.io/badge/Demo_3-Canary_Deploy-orange?style=flat-square)](3-canary-deploy/)
[![Demo 4](https://img.shields.io/badge/Demo_4-Supply_Chain-purple?style=flat-square)](4-supply-chain/)
[![Demo 5](https://img.shields.io/badge/Demo_5-Secret_Rotation-red?style=flat-square)](5-secret-rotation/)
[![Demo 6](https://img.shields.io/badge/Demo_6-Cascade_Delete-gray?style=flat-square)](6-env-cascade-delete/)
[![Demo 7](https://img.shields.io/badge/Demo_7-UI_Recording-pink?style=flat-square)](7-ui-recording/)

Scripted, reproducible demonstrations of the BlanketOps Environments platform.
Each demo records a split-pane terminal session (GNU screen) with:
- **Top pane**: `k9s` live cluster view (or `stern` for logs)
- **Bottom pane**: Scripted demo using the MCP server (`blanketops-mcp`)

Recordings output as asciinema `.cast` files → converted to `.gif` for READMEs.

---

## Demo Catalog

| # | Demo | Focus | Status | Recording |
|---|------|-------|--------|-----------|
| 1 | [`1-env-create`](1-env-create/) | Create Environment + child resources (Build, Package, ServiceUnit) via MCP | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 2 | [`2-build-trigger`](2-build-trigger/) | Manual build trigger, revision override, watch BuildRun | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 3 | [`3-canary-deploy`](3-canary-deploy/) | Canary deployment via Deployment CR, traffic split 10% → 100% | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 4 | [`4-supply-chain`](4-supply-chain/) | SupplyChain pipeline execution + GitHubWebhook | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 5 | [`5-secret-rotation`](5-secret-rotation/) | Secret rotation via ExternalSecrets + Vault | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 6 | [`6-env-cascade-delete`](6-env-cascade-delete/) | Delete Environment with `cascade=true` → all children cleaned up | 📝 Scripted | [🎬 Record](#recording-a-demo) |
| 7 | [`7-ui-recording`](7-ui-recording/) | CDP-based UI recording for Environments web UI | 📝 Scripted | [🎬 Record](#recording-a-demo) |

**Status legend:** 📝 Scripted = demo script ready, awaiting cluster to record | 🎬 Recorded = GIF available in demo dir

---

## Demo Previews (GIFs will appear here after recording)

### Demo 1: Environment Create
```bash
cd 1-env-create && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 1 GIF](1-env-create/demo.gif)

### Demo 2: Build Trigger
```bash
cd 2-build-trigger && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 2 GIF](2-build-trigger/demo.gif)

### Demo 3: Canary Deploy
```bash
cd 3-canary-deploy && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 3 GIF](3-canary-deploy/demo.gif)

### Demo 4: Supply Chain
```bash
cd 4-supply-chain && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 4 GIF](4-supply-chain/demo.gif)

### Demo 5: Secret Rotation
```bash
cd 5-secret-rotation && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 5 GIF](5-secret-rotation/demo.gif)

### Demo 6: Cascade Delete
```bash
cd 6-env-cascade-delete && asciinema rec -c "screen -c screenrc" demo.cast
python3 ../scripts/cast2gif.py demo.cast demo.gif
```
![Demo 6 GIF](6-env-cascade-delete/demo.gif)

### Demo 7: UI Recording (CDP)
```bash
cd 7-ui-recording/scripts
python3 record.py
python3 gif.py
```
![Demo 7 GIF](7-ui-recording/frames/demo.gif)

---

## Prerequisites

- Kind cluster with Environments CRDs + operator installed
- `blanketops-mcp` binary on PATH (from [environments-mcp](https://github.com/blanketops/environments-mcp))
- `k9s`, `asciinema`, `stern`, `kubectl`
- Ollama running with `blanketops-llama` model (for AI triage demo)
- For UI demo: Chrome with `--remote-debugging-port=9222`, `websocket-client`, `Pillow`

---

## Recording a Demo

### Terminal Demos (1-6): Split-pane with k9s

```bash
# From repo root
cd 1-env-create

# Start recording (runs screen with k9s top + demo script bottom)
asciinema rec -c "screen -c screenrc" demo.cast

# Convert to GIF
python3 ../scripts/cast2gif.py demo.cast demo.gif

# View
open demo.gif
```

### UI Demo (7): Chrome CDP Recording

```bash
# Start Chrome with remote debugging
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-demo &

# Start Environments UI
cd /path/to/environments-ui && npm run dev

# Record
cd 7-ui-recording/scripts
python3 record.py

# Assemble GIF
python3 gif.py
```

### Record All Demos at Once

```bash
./scripts/record-all.sh
```

---

## Demo Script Conventions

Each `scripts/run-demo.sh`:
- Uses `blanketops-mcp` via stdio (MCP client calls) or direct `kubectl`
- `step()` function for narrated pauses with visual separators
- `pods()` / `resources()` helpers for live resource counts
- Exits with `screen -X quit` to stop the whole recording session
- Outputs clean, narrated terminal output suitable for GIF conversion

Each `screenrc`:
- Splits screen horizontally (top: k9s, bottom: demo script)
- Top pane runs `k9s -n blanketops-environments` in a loop
- Bottom pane runs the demo script

---

## Directory Structure

```
environments-demos/
├── README.md
├── scripts/
│   ├── cast2gif.py          # asciinema .cast → .gif converter
│   └── record-all.sh        # Records all demos in sequence
├── 1-env-create/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast            # Generated after recording
│   └── demo.gif             # Generated after conversion
├── 2-build-trigger/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast
│   └── demo.gif
├── 3-canary-deploy/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast
│   └── demo.gif
├── 4-supply-chain/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast
│   └── demo.gif
├── 5-secret-rotation/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast
│   └── demo.gif
├── 6-env-cascade-delete/
│   ├── screenrc
│   ├── scripts/run-demo.sh
│   ├── demo.cast
│   └── demo.gif
└── 7-ui-recording/
    ├── README.md
    └── scripts/
        ├── record.py        # Chrome CDP driver
        ├── cdp.py           # CDP client
        └── gif.py           # PNG frames → GIF
```

---

## MCP Tools Used

All demos use the [`blanketops-mcp`](https://github.com/blanketops/environments-mcp) server tools:

| Category | Tools |
|----------|-------|
| **Environment** | `apply_environment`, `get_environment`, `list_blanketops_environments`, `patch_environment`, `delete_environment` |
| **Build** | `apply_build`, `get_build`, `list_blanketops_builds`, `trigger_build` |
| **Package** | `apply_package`, `get_package`, `list_blanketops_packages` |
| **ServiceUnit** | `apply_serviceunit`, `get_serviceunit`, `list_blanketops_serviceunits` |
| **Deployment** | `apply_deployment`, `get_deployment`, `list_blanketops_deployments`, `trigger_deployment`, `patch_deployment` |
| **Sources** | `apply_gitrepository`, `get_gitrepository`, `list_blanketops_gitrepositories` |
| **Events** | `apply_githubevent`, `get_githubevent`, `list_blanketops_githubevents`, `trigger_githubevent` |
| **Networking** | `apply_route`, `get_route`, `list_blanketops_routes`, `apply_domain`, `get_domain`, `list_blanketops_domains` |
| **Supply Chain** | `apply_supplychain`, `get_supplychain`, `list_blanketops_supplychains`, `trigger_supplychain`, `apply_githubwebhook`, `apply_supplychainpolicy` |
| **AI Diagnostic** | `analyze_environment_health` (Ollama) |

---

## Related Repos

- [environments-mcp](https://github.com/blanketops/environments-mcp) — MCP server (this demo's backend)
- [environments-ui](https://github.com/blanketops/environments-ui) — Web UI (Demo 7 target)
- [environments-controller](https://github.com/blanketops/environments-controller) — K8s operator
- [knative-ctl](https://github.com/ntlaletsi70/knative-ctl) — Inspiration for demo structure

---

## License

Apache-2.0 — same as BlanketOps Environments platform.