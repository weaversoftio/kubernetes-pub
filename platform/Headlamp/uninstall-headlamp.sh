#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="headlamp"
HTTPROUTE_FILE="headlamp-httproute-fabric.yaml"
RBAC_FILE="headlamp-admin-user.yaml"

echo "==============================================="
echo "🗑️ Uninstalling Headlamp"
echo "==============================================="

echo "[1/5] Deleting HTTPRoute..."
kubectl delete -f $HTTPROUTE_FILE -n $NAMESPACE --ignore-not-found

echo "[2/5] Deleting RBAC..."
kubectl delete -f $RBAC_FILE --ignore-not-found

echo "[3/5] Uninstalling Helm release..."
helm uninstall $RELEASE_NAME -n $NAMESPACE || true

echo "[4/5] Waiting for pods to terminate..."
sleep 3
kubectl get pods -n $NAMESPACE | grep headlamp || true

echo "[5/5] Checking if Service still exists..."
kubectl get svc -n $NAMESPACE | grep headlamp || true

echo "==============================================="
echo "✔️ Headlamp uninstallation complete!"
echo "==============================================="
