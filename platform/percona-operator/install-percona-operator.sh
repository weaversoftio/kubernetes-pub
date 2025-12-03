#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="pg-operator"
CHART="pg-operator-2.7.0.tgz"
VALUES_FILE="values-operator.yaml"

echo "Installing Percona PostgreSQL Operator..."

echo "[1/3] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[2/3] Deploying PostgreSQL Operator Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART" -f "$VALUES_FILE" -n "$NAMESPACE" --wait

echo "[3/3] Validating Operator pod..."
kubectl rollout status deployment/percona-postgresql-operator -n "$NAMESPACE" --timeout=120s

echo "Percona PostgreSQL Operator installed successfully."
