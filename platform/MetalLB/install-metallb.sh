#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="metallb"
CHART="metallb-0.15.2.tgz"
VALUES_FILE="values-metallb.yaml"
POOL_FILE="metallb-addresspool.yaml"

echo "=============================================="
echo "🚀 Installing MetalLB"
echo "=============================================="

# 1. Ensure namespace exists
echo "[1/5] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

# 2. Install / upgrade MetalLB
echo "[2/5] Deploying MetalLB Helm chart..."
helm upgrade --install \
  $RELEASE_NAME $CHART \
  -f $VALUES_FILE \
  -n $NAMESPACE \
  --wait

# 3. Apply IPAddressPool + L2Advertisement
echo "[3/5] Applying IP Address Pool..."
kubectl apply -f $POOL_FILE -n $NAMESPACE

# 4. Verify Controller + Speaker are running
echo "[4/5] Validating MetalLB pods..."
kubectl rollout status deployment/$RELEASE_NAME-controller -n $NAMESPACE --timeout=120s

echo "[INFO] Speaker DaemonSet status:"
kubectl get daemonset -n $NAMESPACE $RELEASE_NAME-speaker -o wide

# 5. Show the address pool
echo "[5/5] IPAddressPool Info:"
kubectl get ipaddresspool -n $NAMESPACE -o wide

echo "=============================================="
echo "🎉 MetalLB installation complete!"
echo "=============================================="
