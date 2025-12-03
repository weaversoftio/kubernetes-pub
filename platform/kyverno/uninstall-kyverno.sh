#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="kyverno"

echo "Uninstalling Kyverno..."

kubectl delete -f add-gateway-parent-ref.yaml --ignore-not-found
kubectl delete -f generate-httproute-from-service.yaml --ignore-not-found
kubectl delete -f validate-service-naming.yaml --ignore-not-found

kubectl delete -f kyverno-gateway-api-rbac.yaml --ignore-not-found
kubectl delete -f kyverno-coc-config.yaml --ignore-not-found

helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true

echo "Kyverno uninstalled."
