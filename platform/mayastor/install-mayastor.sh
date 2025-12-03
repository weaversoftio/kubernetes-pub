#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="mayastor"
CHART="mayastor-2.9.3.tgz"
VALUES_FILE="values-mayastor.yaml"
DS_FILE="nvme-tcp-module-ds.yaml"
SC_FILE="mayastor-sc-3rep.yaml"
DISKPOOLS_FILE="diskpools.yaml"

echo "Installing Mayastor..."

echo "[1/5] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[2/5] Applying NVMe-TCP module DaemonSet..."
kubectl apply -f "$DS_FILE" -n "$NAMESPACE"

echo "[3/5] Installing Mayastor Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART" -f "$VALUES_FILE" -n "$NAMESPACE" --wait

echo "[4/5] Applying StorageClass..."
kubectl apply -f "$SC_FILE"

echo "[5/5] Applying DiskPools (make sure disks are correct in $DISKPOOLS_FILE)..."
kubectl apply -f "$DISKPOOLS_FILE"

echo "Validating Mayastor components..."

kubectl rollout status deployment/mayastor-agent-core -n "$NAMESPACE" --timeout=180s
kubectl rollout status deployment/mayastor-agent-ha-node -n "$NAMESPACE" --timeout=180s
kubectl rollout status statefulset/mayastor-etcd -n "$NAMESPACE" --timeout=180s
kubectl rollout status deployment/mayastor-api-rest -n "$NAMESPACE" --timeout=180s
kubectl rollout status deployment/mayastor-csi-controller -n "$NAMESPACE" --timeout=180s
kubectl rollout status daemonset/mayastor-csi-node -n "$NAMESPACE" --timeout=180s
kubectl rollout status daemonset/mayastor-io-engine -n "$NAMESPACE" --timeout=180s

echo "Mayastor installation complete."
