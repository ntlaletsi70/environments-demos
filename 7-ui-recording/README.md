# Demo 7: UI Recording via CDP

Records the Environments UI (Vite dev server) via Chrome DevTools Protocol.

## Prerequisites

- Chrome running with `--remote-debugging-port=9222`
- Environments UI running at `http://localhost:5173` (`npm run dev`)
- Python packages: `websocket-client`, `Pillow`

```bash
pip install websocket-client Pillow
```

## Recording

```bash
cd 7-ui-recording/scripts

# Start Chrome with remote debugging
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-demo &

# Run recording
python3 record.py

# Assemble GIF
python3 gif.py

# demo.gif created in frames/
```

## What it Records

1. **Idle dashboard** - landing page
2. **New Environment form** - filled and submitted
3. **Reconciliation progress** - Build, Package, ServiceUnit appearing
4. **Build trigger** - manual trigger with revision override
5. **BuildRun progress** - watching pod logs
6. **Canary promotion** - 10% → 100% traffic split

## Output

- `frames/XXX-name.png` - individual screenshots
- `demo.gif` - assembled animation