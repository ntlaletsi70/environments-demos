#!/usr/bin/env bash
# Demo 2: Manual Build trigger with revision override
# Records split-pane: k9s (top) + scripted demo (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
BUILD_NAME=demo-app-build
NEW_REVISION=v1.1.0-rc.1

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

echo "============================================================"
echo " Demo 2: Manual Build trigger with revision override"
echo
echo " What you'll see:"
echo "  1. Existing Build at revision main (v1.0.0)"
echo "  2. Manual trigger updates Build revision to v1.1.0-rc.1"
echo "  3. BuildRun created, pods scale up"
echo "  4. Build completes, Package updated"
echo "============================================================="
sleep 3

step "current Build status"
kubectl get build -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
echo
kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || echo "No BuildRuns yet"

step "triggering Build with new revision (equivalent to MCP trigger_build tool)"
kubectl patch build demo-app-build -n "$NS" --type=merge -p "{\"spec\":{\"contract\":{\"source\":{\"revision\":\"v1.1.0-rc.1\"}}}}"
sleep 2

step "Build triggered - watching BuildRun and pods"
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  echo "t+$((i*5))s: buildruns=$(kubectl get buildrun -n \"$NS\" -l \"environments.blanketops.dev/name=$ENV_NAME\" --no-headers 2>/dev/null | wc -l) buildpods=$(kubectl get pods -n \"$NS\" -l \"environments.blanketops.dev/name=$ENV_NAME,app.kubernetes.io/component=build\" --no-headers 2>/dev/null | wc -l)"
  kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
  sleep 5
done

step "Build completed - checking Package update"
kubectl get package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "demo done - Build triggered, completed, Package updated"
sleep 4

screen -X quit