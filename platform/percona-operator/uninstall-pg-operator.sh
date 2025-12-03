#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="pg-operator"

echo "Uninstalling Percona PostgreSQL Operator..."

echo "[1/2] Removing Helm release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true

echo "[2/2] Cleaning leftover CRDs (operator-specific only)..."
kubectl delete crd perconapgclusters.pgv2.percona.com --ignore-not-found
kubectl delete crd perconapgbackups.pgv2.percona.com --ignore-not-found
kubectl delete crd perconapgrestores.pgv2.percona.com --ignore-not-found

echo "Percona PostgreSQL Operator uninstalled."
