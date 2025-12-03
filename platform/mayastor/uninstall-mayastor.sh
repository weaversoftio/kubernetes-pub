#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="mayastor"
DS_FILE="nvme-tcp-module-ds.yaml"
SC_FILE="mayastor-sc-3rep.yaml"
DISKPOOLS_FILE="diskpools.yaml"

echo "Uninstalling Mayastor..."

echo "[1/4] Deleting DiskPools..."
kubectl delete -f "$DISKPOOLS_FILE" --ignore-not-found

echo "[2/4] Deleting StorageClass..."
kubectl delete -f "$SC_FILE" --ignore-not-found

echo "[3/4] Deleting NVMe-TCP DaemonSet..."
kubectl delete -f "$DS_FILE" -n "$NAMESPACE" --ignore-not-found

echo "[4/4] Removing Helm release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true

echo "Mayastor uninstalled."
