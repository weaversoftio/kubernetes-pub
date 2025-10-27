#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "DEX OIDC Authentication Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/3] Installing DEX..."
kubectl create namespace dex --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install dex "$SCRIPT_DIR"/dex-*.tgz \
    -n dex \
    -f "$SCRIPT_DIR/dex-values.yaml"

# Create HTTPRoute
echo "[2/3] Creating HTTPRoute..."
kubectl apply -f "$SCRIPT_DIR/dex-httproute.yaml"

# Apply RBAC
echo "[3/3] Applying RBAC..."
kubectl apply -f "$SCRIPT_DIR/rbac-admin-user.yaml"

echo ""
echo "✓ DEX installed successfully!"
echo ""
echo "Access: https://dex.samsung.local"
echo "Default user: admin@samsung.local / admin"
echo ""
echo "IMPORTANT: Update kube-apiserver with OIDC flags!"
echo "See: $SCRIPT_DIR/kube-apiserver-oidc-patch.yaml"
echo ""

