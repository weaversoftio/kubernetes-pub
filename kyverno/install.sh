#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Kyverno Policy Engine Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/2] Installing Kyverno..."
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kyverno "$SCRIPT_DIR"/kyverno-*.tgz -n kyverno

# Apply policies
echo "[2/2] Applying policies..."
kubectl apply -f "$SCRIPT_DIR/add-gateway-parent-ref.yaml"

echo ""
echo "✓ Kyverno installed successfully!"
echo ""
echo "Verify:"
echo "  kubectl get pods -n kyverno"
echo "  kubectl get clusterpolicy"
echo ""
