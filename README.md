# BlanketOps Environments Demos

Scripted, reproducible demonstrations of the BlanketOps Environments platform.
Each demo records a split-pane terminal session (GNU screen) with:
- **Top pane**: `k9s` live cluster view (or `stern` for logs)
- **Bottom pane**: Scripted demo using the MCP server (`blanketops-mcp`)

Recordings output as asciinema `.cast` files → converted to `.gif` for READMEs.

## Demo Catalog

| # | Demo | Focus |
|---|------|-------|
| 1 | `1-env-create` | Create Environment + child resources (Build, Package, ServiceUnit) via MCP |
| 2 | `2-build-trigger` | Manual build trigger, revision override, watch BuildRun |
| 3 | `3-canary-deploy` | Canary deployment via Deployment CR, traffic split |
| 4 | `4-supply-chain` | SupplyChain pipeline execution + GitHubWebhook |
| 5 | `5-secret-rotation` | Secret rotation via ExternalSecrets + Vault |
| 6 | `6-env-cascade-delete` | Delete Environment with cascade=true → all children cleaned up |

## Prerequisites

- Kind cluster with Environments CRDs + operator installed
- `blanketops-mcp` binary on PATH
- `k9s`, `asciinema`, `stern`, `kubectl`
- Ollama running with `blanketops-llama` model

## Recording a Demo

```bash
# From repo root
cd 1-env-create

# Start recording (runs screen with k9s + demo script)
asciinema rec -c "screen -c screenrc" demo.cast

# Convert to GIF (requires asciinema2gif or similar)
asciinema2gif demo.cast demo.gif
```

## Demo Script Conventions

Each `scripts/run-demo.sh`:
- Uses `blanketops-mcp` via stdio (MCP client calls) or direct kubectl
- `step()` function for narrated pauses
- `pods()` helper for live resource counts
- Exits with `screen -X quit` to stop the whole session

## Directory Structure

```
environments-demos/
├── README.md
├── 1-env-create/
│   ├── scripts/
│   │   └── run-demo.sh
│   ├── screenrc
│   ├── demo.cast
│   └── demo.gif
├── 2-build-trigger/
│   ├── scripts/
│   │   └── run-demo.sh
│   ├── screenrc
│   ├── demo.cast
│   └── demo.gif
└── ...
```