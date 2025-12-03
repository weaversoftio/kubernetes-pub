#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="nginx-gateway-fabric"
GATEWAY_NAME="weaverai-gateway-fabric"

echo "=============================================="
echo "🧹 Uninstalling NGINX Gateway Fabric"
echo "=============================================="

# 1. Remove Gateway object
echo "[1/4] Deleting Gateway resource..."
kubectl delete gateway $GATEWAY_NAME -n $NAMESPACE --ignore-not-found

# 2. Helm uninstall
echo "[2/4] Removing Helm release..."
helm uninstall $RELEASE_NAME -n $NAMESPACE || true

# 3. Remove Service (LoadBalancer)
echo "[3/4] Deleting Service..."
kubectl delete svc $RELEASE_NAME -n $NAMESPACE --ignore-not-found

# 4. Delete leftover pods (if any)
echo "[4/4] Cleaning leftover pods..."
kubectl delete pod -n $NAMESPACE -l app.kubernetes.io/name=$RELEASE_NAME --ignore-not-found

echo "=============================================="
echo "✅ NGINX Gateway Fabric fully removed"
echo "=============================================="
