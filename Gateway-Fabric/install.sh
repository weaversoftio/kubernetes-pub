#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "NGINX Gateway Fabric Installation"
echo "========================================"
echo ""

# Create namespace
echo "[1/4] Creating namespace..."
kubectl create namespace nginx-gateway --dry-run=client -o yaml | kubectl apply -f -

# Create TLS certificate (self-signed for testing)
echo "[2/4] Creating TLS certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls.key -out /tmp/tls.crt \
    -subj "/CN=*.samsung.local/O=Samsung" \
    -addext "subjectAltName=DNS:*.samsung.local,DNS:samsung.local" 2>/dev/null

kubectl create secret tls samsung-tls-certificate \
    --cert=/tmp/tls.crt --key=/tmp/tls.key \
    -n nginx-gateway --dry-run=client -o yaml | kubectl apply -f -

rm -f /tmp/tls.key /tmp/tls.crt

# Install NGINX Gateway Fabric
echo "[3/4] Installing NGINX Gateway Fabric..."
helm upgrade --install nginx-gateway-fabric "$SCRIPT_DIR"/nginx-gateway-fabric-*.tgz \
    -n nginx-gateway \
    -f "$SCRIPT_DIR/values.yaml"

# Apply Gateway resource
echo "[4/4] Creating Gateway resource..."
kubectl apply -f "$SCRIPT_DIR/gateway.yaml"

echo ""
echo "✓ Gateway Fabric installed successfully!"
echo ""
echo "Verify:"
echo "  kubectl get pods -n nginx-gateway"
echo "  kubectl get gateway -n nginx-gateway"
echo "  kubectl get svc -n nginx-gateway"
echo ""
