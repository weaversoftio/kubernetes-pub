#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="redis-operator"
CHART="redis-operator-0.22.2.tgz"
VALUES_FILE="redis-operator-values.yaml"

echo "Installing Redis Operator..."

echo "[1/3] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[2/3] Deploying Redis Operator Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART" -f "$VALUES_FILE" -n "$NAMESPACE" --wait

echo "[3/3] Validating Redis Operator pod..."
kubectl rollout status deployment/redis-operator -n "$NAMESPACE" --timeout=120s

echo "Redis Operator installed successfully."
