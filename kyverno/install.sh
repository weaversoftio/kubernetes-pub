#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Kyverno CoC Policy Controller Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/3] Installing Kyverno..."
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kyverno "$SCRIPT_DIR"/kyverno-*.tgz \
    -n kyverno \
    -f "$SCRIPT_DIR/values.yaml" \
    --no-hooks

# Wait for Kyverno to be ready
echo ""
echo "Waiting for Kyverno to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s || true
sleep 5

# Apply Gateway API RBAC
echo ""
echo "[2/4] Applying Gateway API RBAC..."
kubectl apply -f "$SCRIPT_DIR/kyverno-gateway-api-rbac.yaml"

# Apply Convention over Configuration policies
echo ""
echo "[3/4] Applying CoC policies..."

echo "  ✓ Applying: generate-httproute-from-service"
kubectl apply -f "$SCRIPT_DIR/generate-httproute-from-service.yaml"

echo "  ✓ Applying: validate-service-naming"
kubectl apply -f "$SCRIPT_DIR/validate-service-naming.yaml"

echo "  ✓ Applying: add-gateway-parent-ref"
kubectl apply -f "$SCRIPT_DIR/add-gateway-parent-ref.yaml"

# Verify policies
echo ""
echo "[4/4] Verifying policies..."
kubectl get clusterpolicy

echo ""
echo "✓ Kyverno CoC Policy Controller installed successfully!"
echo ""
echo "Policies installed:"
echo "  1. generate-httproute-from-service - Auto-creates HTTPRoute from Service"
echo "  2. validate-service-naming - Enforces naming conventions"
echo "  3. add-gateway-parent-ref - Adds Gateway reference to HTTPRoute"
echo ""
echo "Usage:"
echo "  To expose a Service, add annotation: expose: \"true\""
echo "  Example:"
echo "    kubectl annotate service my-app expose=true"
echo ""
echo "HTTPRoute will be auto-generated with hostname:"
echo "  {service-name}-{namespace}.samsung.local"
echo ""
echo "Verify:"
echo "  kubectl get pods -n kyverno"
echo "  kubectl get clusterpolicy"
echo ""

