#!/usr/bin/env bash
# Demo 3: Canary Deployment via Deployment CR + traffic split
# Records split-pane: k9s (top) + scripted demo (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
DEPLOYMENT_NAME=demo-app-deploy

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
echo "  2. Manual apply_deployment with canary strategy, 10% weight"
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

step "creating Canary Deployment (equivalent to MCP apply_deployment tool)"
kubectl apply -f - <<EOY
apiVersion: environments.blanketops.dev/v1alpha1
kind: Deployment
metadata:
  name: demo-app-deploy
  namespace: blanketops-environments
  labels:
    environments.blanketops.dev/name: demo-app
spec:
  contract:
    strategy: Canary
    replicas: "5"
    serviceUnits:
      - demo-app-api
      - demo-app-worker
    canaryWeight: "10"
    environmentRef:
      name: demo-app
EOY
sleep 3

step "Deployment created - watching ServiceUnits and pods"
for i in 1 2 3 4 5 6 7 8; do
  echo "t+$((i*5))s:"
  kubectl get serviceunit -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
  echo "pods: $(kubectl get pods -n \"$NS\" -l \"environments.blanketops.dev/name=$ENV_NAME\" --no-headers 2>/dev/null | wc -l)"
  sleep 5
done

step "checking traffic split via Route"
kubectl get route -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || echo "Routes pending..."

step "promoting canary to 100% (equivalent to MCP patch_deployment tool)"
kubectl patch deployment demo-app-deploy -n blanketops-environments --type=merge -p '{"spec":{"contract":{"canaryWeight":"100"}}}'
sleep 3

step "Canary promoted - verifying 100% traffic"
kubectl get route -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "demo done - Canary deployed and promoted"
sleep 4

screen -X quit