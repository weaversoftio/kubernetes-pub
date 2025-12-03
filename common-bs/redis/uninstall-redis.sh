#!/bin/bash
set -e

echo "======================================"
echo "      Uninstalling Redis Standalone"
echo "======================================"

# Confirm deletion
read -p "WARNING: This will delete Redis, its PVC and its data. Continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Delete Redis CR
echo "[1/5] Deleting Redis CR..."
kubectl delete -f redis-standalone.yaml --ignore-not-found=true

# 2. Delete Redis service
echo "[2/5] Deleting Redis service..."
kubectl delete -f redis-svc.yaml --ignore-not-found=true

# 3. Wait for pods to disappear
echo "[3/5] Waiting for Redis pods to terminate..."
kubectl wait --for=delete pod -l app=my-redis --timeout=60s 2>/dev/null || true

# 4. Delete PVC
echo "[4/5] Checking PVC..."
pvcName=$(kubectl get pvc | grep my-redis | awk '{print $1}')

if [ -n "$pvcName" ]; then
    echo "Deleting PVC: $pvcName"
    kubectl delete pvc "$pvcName" --ignore-not-found=true
else
    echo "No PVC found."
fi

# 5. Delete orphan PVs
echo "[5/5] Checking orphan PVs..."
pvList=$(kubectl get pv -o jsonpath='{.items[*].metadata.name}')

for pv in $pvList; do
    claim=$(kubectl get pv "$pv" -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || true)
    if [[ "$claim" == *"$pvcName"* ]]; then
        echo "Deleting PV: $pv"
        kubectl delete pv "$pv" --ignore-not-found=true
    fi
done

echo "======================================"
echo "     Redis Uninstall Complete ✔"
echo "======================================"
