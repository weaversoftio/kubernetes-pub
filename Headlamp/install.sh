#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Headlamp Dashboard Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/3] Installing Headlamp..."
kubectl create namespace headlamp --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install headlamp "$SCRIPT_DIR"/headlamp-*.tgz \
    -n headlamp \
    -f "$SCRIPT_DIR/headlamp-values.yaml"

# Create admin user
echo "[2/3] Creating admin user..."
kubectl apply -f "$SCRIPT_DIR/headlamp-admin-user.yaml"

# Create HTTPRoute
echo "[3/3] Creating HTTPRoute..."
kubectl apply -f "$SCRIPT_DIR/headlamp-httproute-fabric.yaml"

echo ""
echo "✓ Headlamp installed successfully!"
echo ""
echo "Access: https://headlamp.samsung.local"
echo ""
echo "Get admin token:"
echo "  kubectl get secret -n headlamp \$(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print \$1}') -o jsonpath='{.data.token}' | base64 -d"
echo ""

