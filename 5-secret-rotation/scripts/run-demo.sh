#!/usr/bin/env bash
# Demo 5: Secret Rotation via ExternalSecrets + Vault
# Records split-pane: k9s (top) + scripted MCP calls (bottom)

set -euo pipefail

NS=blanketops-environments
ENV_NAME=demo-app
SECRET_KEY=github-token
NEW_TOKEN=ghp_rotated_token_$(date +%s)

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

echo "============================================================"
echo " Demo 5: Secret Rotation (ExternalSecrets + Vault)"
echo
echo " What you'll see:"
echo "  1. Current secret in Vault + synced K8s Secret"
echo "  2. Update secret in Vault (simulated)"
echo "  3. ExternalSecrets controller syncs new value"
echo "  4. Build/Deployment picks up new credentials"
echo "============================================================"
sleep 3

step "current GitHub token secret in Vault (simulated)"
echo "Vault path: secret/data/blanketops/environments/github-token"
echo "Current value: ghp_old_token_12345"
echo

step "current synced K8s Secret"
kubectl get secret -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME,external-secrets.io/managed=true" 2>/dev/null || echo "No managed secrets yet"
echo

step "rotating secret in Vault (simulated - would use vault CLI)"
echo "vault kv put secret/blanketops/environments/github-token value=$NEW_TOKEN"
echo "Vault updated with new token"
echo

step "waiting for ExternalSecrets sync (polling every 10s)"
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "t+$((i*10))s:"
  kubectl get externalsecret -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" -o wide 2>/dev/null || echo "No ExternalSecrets yet"
  kubectl get secret -n "$NS" -l "external-secrets.io/managed=true" -o wide 2>/dev/null || true
  sleep 10
done

step "verifying new token in synced secret"
echo "Secret should now contain: $NEW_TOKEN"
kubectl get secret -n "$NS" -l "external-secrets.io/managed=true" -o yaml 2>/dev/null | grep -A2 "github-token" || echo "Check manually"

step "demo done - Secret rotated and synced"
sleep 4

screen -X quit