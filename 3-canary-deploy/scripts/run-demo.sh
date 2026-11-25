#!/usr/bin/env bash
# Demo 3: Canary Deployment via Deployment CR + traffic split
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
DEPLOYMENT_NAME=demo-app-deploy
SERVICE_UNITS="demo-app-api,demo-app-worker"

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

deploy_pods() {
  kubectl get pods -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" --no-headers 2>/dev/null | wc -l || true
}

echo "============================================================"
echo " Demo 3: Canary Deployment (Deployment CR + traffic split)"
echo
echo " What you'll see:"
echo "  1. Deployment at 100% stable (v1.0.0)"
echo "  2. MCP apply_deployment with canary strategy, 10% weight"
echo "  3. ServiceUnits created for canary + stable"
echo "  4. Traffic split visible in Route/Domain"
echo "============================================================"
sleep 3

step "current Deployment status"
kubectl get deployment -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
echo
kubectl get serviceunit -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
echo
kubectl get route -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || echo "No routes yet"

step "creating Canary Deployment via MCP (apply_deployment tool)"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&1 | tail -20
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "apply_deployment",
    "arguments": {
      "namespace": "$NS",
      "name": "$DEPLOYMENT_NAME",
      "environment": "$ENV_NAME",
      "strategy": "Canary",
      "replicas": "5",
      "serviceUnits": "[\"demo-app-api\", \"demo-app-worker\"]",
      "canaryWeight": "10"
    }
  }
}
EOF
sleep 3

step "Deployment created - watching ServiceUnits and pods"
for i in 1 2 3 4 5 6 7 8; do
  echo "t+$((i*5))s:"
  kubectl get serviceunit -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
  echo "pods: $(deploy_pods)"
  sleep 5
done

step "checking traffic split via Route"
kubectl get route -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || echo "Routes pending..."

step "promoting canary to 100% (patch_deployment)"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&in | tail -10
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "patch_deployment",
    "arguments": {
      "namespace": "$NS",
      "name": "$DEPLOYMENT_NAME",
      "canaryWeight": "100"
    }
  }
}
EOF
sleep 3

step "Canary promoted - verifying 100% traffic"
kubectl get route -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "demo done - Canary deployed and promoted"
sleep 4

screen -X quit