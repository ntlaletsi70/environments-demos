#!/usr/bin/env bash
# Demo 4: SupplyChain pipeline execution + GitHubWebhook
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
SUPPLYCHAIN_NAME=demo-app-sc
WEBHOOK_NAME=demo-app-ghw
REPO_URL=https://github.com/blanketops/demo-app
BRANCH=main
WEBHOOK_SECRET=webhook-secret-demo
EVENTS="push,pull_request,release"

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

echo "============================================================"
echo " Demo 4: SupplyChain pipeline + GitHubWebhook"
echo
echo " What you'll see:"
echo "  1. Create SupplyChain with repo + branch"
echo "  2. Create GitHubWebhook for push/pull_request/release"
echo "  3. Trigger SupplyChain manually"
echo "  3. Watch PipelineRun / Build / Package flow"
echo "============================================================"
sleep 3

step "creating SupplyChain via MCP"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&1 | tail -20
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "apply_supplychain",
    "arguments": {
      "namespace": "$NS",
      "name": "$SUPPLYCHAIN_NAME",
      "environment": "$ENV_NAME",
      "repoURL": "$REPO_URL",
      "branch": "$BRANCH",
      "pipelineRef": "ci-pipeline",
      "params": "{}"
    }
  }
}
EOF
sleep 3

step "creating GitHubWebhook via MCP"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&in | tail -15
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "apply_githubwebhook",
    "arguments": {
      "namespace": "$NS",
      "name": "$WEBHOOK_NAME",
      "environment": "$ENV_NAME",
      "repoURL": "$REPO_URL",
      "events": "$EVENTS",
      "secretRef": "$WEBHOOK_SECRET"
    }
  }
}
EOF
sleep 2

step "verifying SupplyChain and Webhook"
kubectl get supplychain -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
kubectl get githubwebhook -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "triggering SupplyChain pipeline via MCP"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&in | tail -15
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "trigger_supplychain",
    "arguments": {
      "namespace": "$NS",
      "supplyChainName": "$SUPPLYCHAIN_NAME",
      "triggeredBy": "demo-user",
      "params": "{}"
    }
  }
}
EOF
sleep 3

step "watching pipeline execution"
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "t+$((i*10))s:"
  kubectl get pipelinerun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || echo "No PipelineRuns yet"
  kubectl get build -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || true
  kubectl get package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || true
  sleep 10
done

step "demo done - SupplyChain executed"
kubectl get supplychain -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
sleep 4

screen -X quit