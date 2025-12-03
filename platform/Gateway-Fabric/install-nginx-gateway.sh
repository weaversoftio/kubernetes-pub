#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="nginx-gateway-fabric"
CHART="nginx-gateway-fabric-1.5.1.tgz"
VALUES_FILE="values.yaml"
GATEWAY_FILE="gateway.yaml"

echo "=============================================="
echo "🚀 Installing NGINX Gateway Fabric"
echo "=============================================="

# 1. Ensure namespace exists
echo "[1/5] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

# 2. Install / Upgrade Helm chart
echo "[2/5] Deploying Helm chart..."
helm upgrade --install \
  $RELEASE_NAME $CHART \
  -f $VALUES_FILE \
  -n $NAMESPACE \
  --wait

# 3. Apply Gateway object
echo "[3/5] Applying Gateway resource..."
kubectl apply -f $GATEWAY_FILE -n $NAMESPACE

# 4. Verify pod is running
echo "[4/5] Checking deployment status..."
kubectl rollout status deployment/$RELEASE_NAME -n $NAMESPACE --timeout=120s

POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$RELEASE_NAME -o jsonpath='{.items[0].metadata.name}')
echo "NGINX Gateway Fabric Pod: $POD"

# 5. Validate LoadBalancer
echo "[5/5] Validating LoadBalancer service..."
kubectl get svc -n $NAMESPACE $RELEASE_NAME -o wide

echo "=============================================="
echo "🎉 NGINX Gateway Fabric installation complete!"
echo "=============================================="
