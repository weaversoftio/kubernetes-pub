#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "MetalLB Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/3] Creating namespace..."
kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f -

# Install MetalLB
echo "[2/3] Installing MetalLB.."
helm upgrade --install metallb "$SCRIPT_DIR"/metallb-*.tgz -n metallb-system

# Apply IP pool configuration
echo "[3/3] Applying IP pool configuration..."
kubectl apply -f "$SCRIPT_DIR/metallb-addresspool.yaml"

echo ""
echo "✓ MetalLB installed successfully!"
echo ""
echo "Verify:"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl get ipaddresspool -n metallb-system"
echo ""

