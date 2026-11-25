#!/usr/bin/env bash
# Master script to record all demos in sequence
# Usage: ./record-all.sh

set -euo pipefail

DEMOS=(
    "1-env-create"
    "2-build-trigger"
    "3-canary-deploy"
    "4-supply-chain"
    "5-secret-rotation"
    "6-env-cascade-delete"
)

for demo in "${DEMOS[@]}"; do
    echo "============================================================"
    echo " Recording $demo"
    echo "============================================================"
    cd "/home/blanketops/BlanketOps/sources/environments-demos/$demo"

    # Record with asciinema
    asciinema rec -c "screen -c screenrc" "demo.cast"

    # Convert to GIF
    python3 /home/blanketops/BlanketOps/sources/environments-demos/scripts/cast2gif.py "demo.cast" "demo.gif"

    echo "Done: $demo/demo.gif"
    echo
done

echo "All demos recorded!"
ls -la */demo.gif