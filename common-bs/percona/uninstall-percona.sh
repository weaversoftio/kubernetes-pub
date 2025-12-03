#!/bin/bash
set -e

echo "======================================"
echo "   Uninstalling Percona PostgreSQL"
echo "======================================"

RELEASE="my-db"

# Confirm
read -p "WARNING: This will delete ALL database data. Continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Remove Helm release
echo "[1/5] Helm uninstall..."
helm uninstall "$RELEASE" || true

# 2. Delete PostgresCluster CR (if still exists)
echo "[2/5] Deleting PostgresCluster..."
kubectl delete postgrescluster "$RELEASE-pg-db" --ignore-not-found=true

sleep 2

# 3. Delete PVCs
echo "[3/5] Deleting PVCs..."
PVC_LIST=$(kubectl get pvc | grep "$RELEASE" | awk '{print $1}')

if [ -z "$PVC_LIST" ]; then
    echo "No PVC found."
else
    for pvc in $PVC_LIST; do
        echo "Deleting PVC: $pvc"
        kubectl delete pvc "$pvc" --ignore-not-found=true
    done
fi

# 4. Delete PVs that belong to this DB
echo "[4/5] Deleting orphan PVs..."
PV_LIST=$(kubectl get pv -o jsonpath='{.items[*].metadata.name}')

for pv in $PV_LIST; do
    claim=$(kubectl get pv "$pv" -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || true)
    if [[ "$claim" == *"$RELEASE"* ]]; then
        echo "Deleting PV: $pv"
        kubectl delete pv "$pv" --ignore-not-found=true
    fi
done

# 5. Final check
echo "[5/5] Checking remaining pods..."
kubectl get pods | grep "$RELEASE" || echo "No DB pods remaining."

echo "======================================"
echo "   Percona PostgreSQL Removed ✔"
echo "======================================"
