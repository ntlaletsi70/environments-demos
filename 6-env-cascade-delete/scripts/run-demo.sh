#!/usr/bin/env bash
# Demo 6: Environment Cascade Delete
# Records split-pane: k9s (top) + scripted demo (bottom)

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
  kubectl get build,package,serviceunit,deployment,gitrepository,githubevent,route,domain -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
}

echo "============================================================"
echo " Demo 6: Environment Cascade Delete"
echo
echo " What you'll see:"
echo "  1. Fully populated Environment with all child resources"
echo "  2. Manual delete with cascade (equivalent to MCP delete_environment tool)"
echo "  3. Children deleted in dependency order (leaves first)"
echo "  4. Environment deleted last"
echo "  5. Namespace clean"
echo "============================================================"
sleep 3

step "current state - all resources present"
resources

step "deleting Environment with cascade (equivalent to MCP delete_environment tool)"
# Delete children first (leaves first)
for kind in serviceunit deployment package build gitrepository githubevent route domain; do
  kubectl delete $kind -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" --force --grace-period=0 2>/dev/null || true
done

# Delete Environment last
kubectl delete environment demo-app -n blanketops-environments --force --grace-period=0
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