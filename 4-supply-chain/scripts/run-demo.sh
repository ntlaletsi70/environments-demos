#!/usr/bin/env bash
# Demo 4: Supply Chain - GitRepository + Build + Package flow
# Records split-pane: k9s (top) + scripted demo (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
REPO_URL=https://github.com/blanketops/demo-app
BRANCH=main

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

echo "============================================================"
echo " Demo 4: Supply Chain - GitRepository -> Build -> Package flow"
echo
echo " What you'll see:"
echo "  1. GitRepository created for source code"
echo "  2. Build triggered for new revision"
echo "  3. Package created from Build"
echo "  4. Full supply chain traceability"
echo "============================================================="
sleep 3

step "creating GitRepository (equivalent to MCP apply_gitrepository tool)"
kubectl apply -f - <<EOY
apiVersion: sources.blanketops.dev/v1alpha1
kind: GitRepository
metadata:
  name: demo-app-repo
  namespace: blanketops-environments
  labels:
    environments.blanketops.dev/name: demo-app
spec:
  contract:
    url: https://github.com/blanketops/demo-app
    branch: main
    secretRef:
      name: git-ssh-secret
    environmentRef:
      name: demo-app
EOY
sleep 2

step "verifying GitRepository"
kubectl get gitrepository -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide

step "triggering Build for new revision (equivalent to MCP trigger_build tool)"
kubectl patch build demo-app-build -n "$NS" --type=merge -p '{"spec":{"contract":{"source":{"revision":"v1.1.0"}}}}'
sleep 2

step "watching Build and Package flow"
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "t+$((i*10))s:"
  kubectl get buildrun -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || echo "No BuildRuns yet"
  kubectl get build -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || true
  kubectl get package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || true
  sleep 10
done

step "demo done - Supply chain flow demonstrated"
kubectl get build,package -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide
sleep 4

screen -X quit