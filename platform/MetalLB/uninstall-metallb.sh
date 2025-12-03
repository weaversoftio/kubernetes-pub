#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="metallb"
POOL_NAME="weaverai-pool"
L2_NAME="weaverai-l2"

echo "=============================================="
echo "🧹 Uninstalling MetalLB"
echo "=============================================="

# 1. Delete IPAddressPool & L2Advertisement
echo "[1/4] Deleting Address Pool + L2Advertisement..."
kubectl delete ipaddresspool -n $NAMESPACE $POOL_NAME --ignore-not-found
kubectl delete l2advertisement -n $NAMESPACE $L2_NAME --ignore-not-found

# 2. Uninstall Helm Release
echo "[2/4] Removing Helm release..."
helm uninstall $RELEASE_NAME -n $NAMESPACE || true

# 3. Delete leftover DaemonSets, Deployments
echo "[3/4] Cleaning leftover resources..."
kubectl delete daemonset -n $NAMESPACE $RELEASE_NAME-speaker --ignore-not-found
kubectl delete deploy -n $NAMESPACE $RELEASE_NAME-controller --ignore-not-found

# 4. Clean any CRDs left (optional)
echo "[4/4] Optionally remove CRDs (you can comment this out):"
kubectl delete crd ipaddresspools.metallb.io --ignore-not-found
kubectl delete crd l2advertisements.metallb.io --ignore-not-found

echo "=============================================="
echo "✅ MetalLB fully removed"
echo "=============================================="
