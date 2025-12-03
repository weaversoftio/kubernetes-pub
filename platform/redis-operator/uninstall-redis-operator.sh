#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="redis-operator"

echo "Uninstalling Redis Operator..."

echo "[1/2] Removing Helm release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true

echo "[2/2] Cleaning leftover CRDs..."
kubectl delete crd redisclusters.redis.opstreelabs.in --ignore-not-found
kubectl delete crd redis.redis.opstreelabs.in --ignore-not-found
kubectl delete crd redissentinels.redis.opstreelabs.in --ignore-not-found

echo "Redis Operator uninstalled."
