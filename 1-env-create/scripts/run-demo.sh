#!/usr/bin/env bash
# Demo 1: Create Environment + child resources via MCP
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
ENV_TYPE=STAGING
APP_NAME=demo-app
VERSION=v1.0.0
BRANCH=main
GIT_OWNER=blanketops
GIT_REPO=demo-app
TARGET_CLUSTER=kind-workload
SECRET_PROVIDER=vault
VAULT_ADDR=http://vault.vault.svc.cluster.local:8200
VAULT_PATH=secret/data/blanketops/environments
VAULT_ROLE=blanketops-environments

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

pods() {
  kubectl get pods -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" --no-headers 2>/dev/null | wc -l || true
}

resources() {
  echo "--- Resources in $NS (label: environments.blanketops.dev/name=$ENV_NAME) ---"
  kubectl get all -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
  echo
  kubectl get build,package,serviceunit,deployment,gitrepository,githubevent,route,domain,supplychain,githubwebhook,supplychainpolicy -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
}

echo "============================================================"
echo " Demo 1: Create Environment + child resources via MCP"
echo
echo " What you'll see:"
echo "  1. Empty namespace - no resources yet"
echo "  2. MCP apply_environment creates Environment CR"
echo "  3. Controller reconciles: Build + Package + ServiceUnit appear"
echo "  4. GitRepository created for source"
echo "  4. All resources labeled with environments.blanketops.dev/name"
echo "============================================================"
sleep 3

step "verifying empty namespace"
resources
sleep 1

step "creating Environment via MCP (apply_environment tool)"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&1 | tail -20
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "apply_environment",
    "arguments": {
      "namespace": "$NS",
      "name": "$ENV_NAME",
      "applicationName": "$APP_NAME",
      "environmentType": "$ENV_TYPE",
      "version": "$VERSION",
      "branch": "$BRANCH",
      "gitOwner": "$GIT_OWNER",
      "gitRepository": "$GIT_REPO",
      "targetCluster": "$TARGET_CLUSTER",
      "secretStoreProvider": "$SECRET_PROVIDER",
      "vaultAddress": "$VAULT_ADDR",
      "vaultPath": "$VAULT_PATH",
      "vaultRole": "$VAULT_ROLE"
    }
  }
}
EOF
sleep 3

step "Environment created - watching reconciliation"
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "t+$((i*5))s:"
  resources
  sleep 5
done

step "checking Build status"
kubectl get build -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "checking Package status"
kubectl get package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "checking ServiceUnit status"
kubectl get serviceunit -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "checking GitRepository"
kubectl get gitrepository -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "demo done - Environment fully reconciled"
resources
sleep 4

screen -X quit