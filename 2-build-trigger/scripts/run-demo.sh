#!/usr/bin/env bash
# Demo 2: Manual Build trigger with revision override
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

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

build_pods() {
  kubectl get pods -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME,app.kubernetes.io/component=build" --no-headers 2>/dev/null | wc -l || true
}

build_runs() {
  kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" --no-headers 2>/dev/null | wc -l || true
}

echo "============================================================"
echo " Demo 2: Manual Build trigger with revision override"
echo
echo " What you'll see:"
echo "  1. Existing Build at revision main (v1.0.0)"
echo "  2. MCP trigger_build with new revision v1.1.0-rc.1"
echo "  3. BuildRun created, pods scale up"
echo "  4. Build completes, Package updated"
echo "============================================================"
sleep 3

step "current Build status"
kubectl get build -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
echo
kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || echo "No BuildRuns yet"

step "triggering Build with new revision via MCP (trigger_build tool)"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&1 | tail -20
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "trigger_build",
    "arguments": {
      "namespace": "$NS",
      "buildName": "$BUILD_NAME",
      "revision": "$NEW_REVISION",
      "triggeredBy": "demo-user"
    }
  }
}
EOF
sleep 3

step "Build triggered - watching BuildRun and pods"
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  echo "t+$((i*5))s: buildruns=$(build_runs) buildpods=$(build_pods)"
  kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
  sleep 5
done

step "Build completed - checking Package update"
kubectl get package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "demo done - Build triggered, completed, Package updated"
sleep 4

screen -X quit