#!/bin/bash
set -e

echo "======================================"
echo "     Installing Percona PostgreSQL"
echo "======================================"

RELEASE="my-db"
CHART="pg-db-2.7.0.tgz"
VALUES="values-db.yaml"

# 1. Install or upgrade using Helm
echo "[1/5] Installing Helm chart..."
helm upgrade --install "$RELEASE" "$CHART" -f "$VALUES" --wait

# 2. Wait for PostgresCluster CR to appear
echo "[2/5] Waiting for PostgresCluster..."
sleep 2
PG_CLUSTER=$(kubectl get postgrescluster -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$PG_CLUSTER" ]; then
    echo "ERROR: PostgresCluster was not created!"
    exit 1
fi

echo "PostgresCluster detected: $PG_CLUSTER"

# 3. Wait for DB instances to be ready
echo "[3/5] Waiting for database pods to be Ready..."
kubectl wait pod -l "postgres-operator.crunchydata.com/cluster=$PG_CLUSTER" \
  --for=condition=Ready --timeout=300s || {
      echo "ERROR: DB pods did not become ready."
      kubectl get pods
      exit 1
  }

# 4. Show pods status
echo "[4/5] Pods:"
kubectl get pods -l "postgres-operator.crunchydata.com/cluster=$PG_CLUSTER"

# 5. Show services
echo "[5/5] Services:"
kubectl get svc | grep "$RELEASE" || true

echo "======================================"
echo "  Percona PostgreSQL Installed ✔"
echo "======================================"
