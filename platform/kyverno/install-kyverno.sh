#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="kyverno"
CHART="kyverno-3.3.7.tgz"
VALUES_FILE="values.yaml"

RBAC_FILE="kyverno-gateway-api-rbac.yaml"
CONFIGMAP_FILE="kyverno-coc-config.yaml"

POLICIES=(
  "add-gateway-parent-ref.yaml"
  "generate-httproute-from-service.yaml"
  "validate-service-naming.yaml"
)

echo "Installing Kyverno..."

echo "[1/5] Ensuring namespace exists..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[2/5] Installing Kyverno Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART" -f "$VALUES_FILE" -n "$NAMESPACE" --wait

echo "[3/5] Applying RBAC and ConfigMap..."
kubectl apply -f "$RBAC_FILE"
kubectl apply -f "$CONFIGMAP_FILE"

echo "[4/5] Applying Kyverno ClusterPolicies..."
for p in "${POLICIES[@]}"; do
    kubectl apply -f "$p"
done

echo "[5/5] Validating controllers..."
kubectl rollout status deployment/kyverno-admission-controller -n "$NAMESPACE" --timeout=120s
kubectl rollout status deployment/kyverno-background-controller -n "$NAMESPACE" --timeout=120s
kubectl rollout status deployment/kyverno-cleanup-controller -n "$NAMESPACE" --timeout=120s
kubectl rollout status deployment/kyverno-reports-controller -n "$NAMESPACE" --timeout=120s

echo "Kyverno installation complete."
