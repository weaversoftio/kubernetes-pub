#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Trident NetApp Storage Installation"
echo "========================================"
echo ""
echo "NOTE: Before running this script:"
echo "  1. Edit secret-template.yaml with your NetApp credentials"
echo "  2. Edit backend-ontap-nas.yaml with your NetApp storage details"
echo "  3. Review storageclass.yaml configuration"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Create namespace
echo "[1/4] Installing Trident Operator..."
kubectl create namespace trident --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install trident-operator "$SCRIPT_DIR"/trident-operator-*.tgz -n trident

# Create TridentOrchestrator
echo "[2/4] Creating TridentOrchestrator..."
sleep 10  # Wait for operator to be ready
kubectl apply -f "$SCRIPT_DIR/trident-orchestrator.yaml"

# Configure NetApp backend
echo "[3/4] Configuring NetApp backend..."
echo "  Applying secret..."
kubectl apply -f "$SCRIPT_DIR/secret-template.yaml"
echo "  Applying backend configuration..."
kubectl apply -f "$SCRIPT_DIR/backend-ontap-nas.yaml"

# Create StorageClass
echo "[4/4] Creating StorageClass..."
kubectl apply -f "$SCRIPT_DIR/storageclass.yaml"

echo ""
echo "✓ Trident installed successfully!"
echo ""
echo "Verify:"
echo "  kubectl get tridentorchestrator"
echo "  kubectl get tridentbackends -n trident"
echo "  kubectl get storageclass"
echo ""
