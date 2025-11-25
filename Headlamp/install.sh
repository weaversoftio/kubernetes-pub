#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USAGE="Usage: $0 [NAMESPACE] [HOSTNAME]
    NAMESPACE - target namespace to install Headlamp into (default: headlamp)
    HOSTNAME  - hostname for HTTPRoute (default: headlamp.prod.weaversoft.io)"

NAMESPACE=${1:-${NAMESPACE:-headlamp}}
HOSTNAME=${2:-${HOSTNAME:-headlamp.prod.weaversoft.io}}

echo "========================================"
echo "Headlamp Dashboard Installation"
echo "Namespace: $NAMESPACE"
echo "Hostname:  $HOSTNAME"
echo "========================================"
echo ""

echo "[1/4] Ensuring namespace exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "[2/4] Installing Headlamp Helm chart into namespace $NAMESPACE..."
helm upgrade --install headlamp "$SCRIPT_DIR"/headlamp-*.tgz \
        -n "$NAMESPACE" \
        -f "$SCRIPT_DIR/headlamp-values.yaml"

echo "[3/4] Creating ServiceAccount and Secret in namespace $NAMESPACE..."
# Apply ServiceAccount and related Secret into the target namespace (files are namespace-agnostic)
kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/headlamp-admin-user.yaml"

echo "[4/4] Creating ClusterRoleBinding and HTTPRoute..."
# Create ClusterRoleBinding that binds the serviceaccount in the target namespace
kubectl create clusterrolebinding headlamp-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=${NAMESPACE}:headlamp-admin \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply HTTPRoute after substituting hostname and using target namespace
sed -e "s/namespace: headlamp/namespace: ${NAMESPACE}/g" \
        -e "s/headlamp.prod.weaversoft.io/${HOSTNAME}/g" \
        "$SCRIPT_DIR/headlamp-httproute-fabric.yaml" | kubectl apply -n "$NAMESPACE" -f -

echo ""
echo "✓ Headlamp installed successfully into namespace '$NAMESPACE'"
echo ""
echo "Access: https://${HOSTNAME}"
echo ""
echo "Get admin token:"
echo "  kubectl get secret -n ${NAMESPACE} \$(kubectl get secret -n ${NAMESPACE} | grep headlamp-admin-token | awk '{print \\$1}') -o jsonpath='{.data.token}' | base64 -d"
echo ""

