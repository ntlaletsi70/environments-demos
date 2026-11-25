#!/usr/bin/env bash
# Demo 6: Environment Cascade Delete
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

resources() {
  echo "--- All resources for $ENV_NAME ---"
  kubectl get all -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
  echo
  kubectl get build,package,serviceunit,deployment,gitrepository,githubevent,route,domain,supplychain,githubwebhook,supplychainpolicy -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
}

echo "============================================================"
echo " Demo 6: Environment Cascade Delete"
echo
echo " What you'll see:"
echo "  1. Fully populated Environment with all child resources"
echo "  2. MCP delete_environment with cascade=true (default)"
echo "  3. Children deleted in dependency order (leaves first)"
echo "  4. Environment deleted last"
echo "  5. Namespace clean"
echo "============================================================"
sleep 3

step "current state - all resources present"
resources

step "deleting Environment with cascade via MCP (delete_environment tool)"
cat <<EOF | blanketops-mcp -kubeconfig=$HOME/.kube/config -transport=stdio 2>&in | tail -30
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "delete_environment",
    "arguments": {
      "namespace": "$NS",
      "name": "$ENV_NAME",
      "cascade": true
    }
  }
}
EOF
sleep 3

step "verifying cascade deletion"
for i in 1 2 3 4 5 6; do
  echo "t+$((i*5))s:"
  resources
  sleep 5
done

step "verifying namespace clean"
kubectl get all -n "$NS" 2>/dev/null | grep -v "No resources found" || echo "Namespace clean - all resources deleted"

step "demo done - Environment and all children deleted"
sleep 4

screen -X quit