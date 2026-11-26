#!/usr/bin/env bash
# Demo 1: Create Environment + child resources via kubectl (MCP server equivalent)
# Records split-pane: k9s (top) + scripted demo (bottom)

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
SECRET_PROVIDER=fake
SECRET_STORE=blanketops-environments-fake

step() {
  echo
  echo "### $1"
  echo
  sleep 2
}

resources() {
  echo "--- Resources in $NS (label: environments.blanketops.dev/name=$ENV_NAME) ---"
  kubectl get all -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
  echo
  kubectl get build,package,serviceunit,deployment,gitrepository,githubevent,route,domain,supplychain,githubwebhook,supplychainpolicy -n "$NS" -l "environments.blanketops.dev/name=$ENV_NAME" 2>/dev/null || true
}

echo "============================================================"
echo " Demo 1: Create Environment + child resources via kubectl"
echo " (equivalent to MCP server apply_environment tool)"
echo
echo " What you'll see:"
echo "  1. Empty namespace - no resources yet"
echo "  2. kubectl apply creates Environment CR"
echo "  3. Controller reconciles: Build + Package + ServiceUnit appear"
echo "  4. GitRepository, Route, Domain created"
echo "  5. All resources labeled with environments.blanketops.dev/name"
echo "============================================================"
sleep 3

step "verifying empty namespace"
resources
sleep 1

step "creating Environment (equivalent to MCP apply_environment tool)"
kubectl apply -f - <<EOENV
apiVersion: environments.blanketops.dev/v1alpha1
kind: Environment
metadata:
  name: $ENV_NAME
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    applicationName: $APP_NAME
    environmentType: $ENV_TYPE
    version: $VERSION
    branch: $BRANCH
    gitOwner: $GIT_OWNER
    gitRepository: $GIT_REPO
    targetCluster: $TARGET_CLUSTER
    secretStore:
      provider: $SECRET_PROVIDER
      storeName: $SECRET_STORE
EOENV
sleep 2

step "creating Build (equivalent to MCP apply_build tool)"
kubectl apply -f - <<EOBUILD
apiVersion: environments.blanketops.dev/v1alpha1
kind: Build
metadata:
  name: ${ENV_NAME}-build
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    image: ghcr.io/blanketops/demo-app:$VERSION
    strategy:
      name: kaniko
    gitRepository:
      name: ${ENV_NAME}-repo
    source:
      revision: $BRANCH
    environmentRef:
      name: $ENV_NAME
EOBUILD
sleep 1

step "creating Package (equivalent to MCP apply_package tool)"
kubectl apply -f - <<EOPKG
apiVersion: environments.blanketops.dev/v1alpha1
kind: Package
metadata:
  name: ${ENV_NAME}-pkg
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    version: $VERSION
    image: ghcr.io/blanketops/demo-app:$VERSION
    buildRef:
      name: ${ENV_NAME}-build
    environmentRef:
      name: $ENV_NAME
EOPKG
sleep 1

step "creating ServiceUnit (equivalent to MCP apply_serviceunit tool)"
kubectl apply -f - <<EOSVC
apiVersion: environments.blanketops.dev/v1alpha1
kind: ServiceUnit
metadata:
  name: ${ENV_NAME}-api
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    type: Deployment
    appType: web
    stackType: go
    image: ghcr.io/blanketops/demo-app:$VERSION
    replicas: "2"
    packageRef:
      name: ${ENV_NAME}-pkg
    environmentRef:
      name: $ENV_NAME
EOSVC
sleep 1

step "creating GitRepository (equivalent to MCP apply_gitrepository tool)"
kubectl apply -f - <<EOGR
apiVersion: sources.blanketops.dev/v1alpha1
kind: GitRepository
metadata:
  name: ${ENV_NAME}-repo
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    url: https://github.com/blanketops/demo-app
    branch: $BRANCH
    secretRef:
      name: git-ssh-secret
    environmentRef:
      name: $ENV_NAME
EOGR
sleep 1

step "creating Route (equivalent to MCP apply_route tool)"
kubectl apply -f - <<EOROUTE
apiVersion: networks.blanketops.dev/v1alpha1
kind: Route
metadata:
  name: ${ENV_NAME}-route
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    host: demo-app.example.com
    path: /
    service:
      name: ${ENV_NAME}-api
      port: "8080"
    environmentRef:
      name: $ENV_NAME
EOROUTE
sleep 1

step "creating Domain (equivalent to MCP apply_domain tool)"
kubectl apply -f - <<EODOMAIN
apiVersion: networks.blanketops.dev/v1alpha1
kind: Domain
metadata:
  name: ${ENV_NAME}-domain
  namespace: $NS
  labels:
    environments.blanketops.dev/name: $ENV_NAME
spec:
  contract:
    host: demo-app.example.com
    tls:
      secretName: ${ENV_NAME}-tls
    environmentRef:
      name: $ENV_NAME
EODOMAIN
sleep 2

step "verifying full hierarchy"
resources

step "demo done - all resources created and labeled"
resources
sleep 4

screen -X quit