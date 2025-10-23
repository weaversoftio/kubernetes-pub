#!/bin/bash

# =====================================================
# Samsung Kubernetes Platform - Complete Uninstallation
# =====================================================
# 
# This script removes all installed components
#
# =====================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/cluster-config.yaml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Load namespaces from config
load_namespaces() {
    if [ -f "$CONFIG_FILE" ]; then
        HEADLAMP_NS=$(grep -A30 "^headlamp:" "$CONFIG_FILE" | grep "namespace:" | head -1 | awk '{print $2}' | tr -d '"')
        DEX_NS=$(grep -A50 "^dex:" "$CONFIG_FILE" | grep "namespace:" | head -1 | awk '{print $2}' | tr -d '"')
        KYVERNO_NS=$(grep -A10 "^kyverno:" "$CONFIG_FILE" | grep "namespace:" | awk '{print $2}' | tr -d '"')
        GATEWAY_NS=$(grep -A20 "^gateway:" "$CONFIG_FILE" | grep "namespace:" | head -1 | awk '{print $2}' | tr -d '"')
        METALLB_NS=$(grep -A10 "^metallb:" "$CONFIG_FILE" | grep "namespace:" | awk '{print $2}' | tr -d '"')
    else
        # Defaults
        HEADLAMP_NS="headlamp"
        DEX_NS="dex"
        KYVERNO_NS="kyverno"
        GATEWAY_NS="nginx-gateway"
        METALLB_NS="metallb-system"
    fi
}

confirm_uninstall() {
    print_header "WARNING: Uninstall All Components"
    
    echo -e "${RED}This will remove ALL installed components:${NC}"
    echo "  • DEX (namespace: $DEX_NS)"
    echo "  • Headlamp (namespace: $HEADLAMP_NS)"
    echo "  • Kyverno (namespace: $KYVERNO_NS)"
    echo "  • Gateway Fabric (namespace: $GATEWAY_NS)"
    echo "  • MetalLB (namespace: $METALLB_NS)"
    echo ""
    echo -e "${RED}This action cannot be undone!${NC}"
    echo ""
    echo -e "${YELLOW}Type 'yes' to confirm uninstallation:${NC} "
    read -r response
    
    if [ "$response" != "yes" ]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    
    echo ""
}

uninstall_component() {
    local component_name=$1
    local namespace=$2
    local release_name=$3
    
    echo -e "${YELLOW}Uninstalling $component_name...${NC}"
    
    # Uninstall Helm release
    if helm list -n "$namespace" 2>/dev/null | grep -q "^$release_name"; then
        helm uninstall "$release_name" -n "$namespace" 2>/dev/null || true
        print_success "Helm release '$release_name' removed"
    fi
    
    # Delete namespace
    if kubectl get namespace "$namespace" &>/dev/null; then
        kubectl delete namespace "$namespace" --timeout=60s 2>/dev/null || {
            print_warning "Forcing namespace deletion..."
            kubectl delete namespace "$namespace" --grace-period=0 --force 2>/dev/null || true
        }
        print_success "Namespace '$namespace' removed"
    fi
    
    echo ""
}

main() {
    clear
    
    print_header "Samsung Kubernetes Platform - Uninstallation"
    
    load_namespaces
    confirm_uninstall
    
    START_TIME=$(date +%s)
    
    # Uninstall in reverse order
    
    # 1. DEX
    if kubectl get namespace "$DEX_NS" &>/dev/null; then
        uninstall_component "DEX" "$DEX_NS" "dex"
        # Remove RBAC
        kubectl delete clusterrolebinding oidc-cluster-admin 2>/dev/null || true
        kubectl delete clusterrolebinding oidc-cluster-view 2>/dev/null || true
    fi
    
    # 2. Headlamp
    if kubectl get namespace "$HEADLAMP_NS" &>/dev/null; then
        uninstall_component "Headlamp" "$HEADLAMP_NS" "headlamp"
        # Remove RBAC
        kubectl delete clusterrolebinding headlamp-admin 2>/dev/null || true
    fi
    
    # 3. Kyverno
    if kubectl get namespace "$KYVERNO_NS" &>/dev/null; then
        # Remove policies first
        kubectl delete clusterpolicy --all 2>/dev/null || true
        uninstall_component "Kyverno" "$KYVERNO_NS" "kyverno"
    fi
    
    # 4. Gateway Fabric
    if kubectl get namespace "$GATEWAY_NS" &>/dev/null; then
        # Remove Gateway resources first
        kubectl delete gateway --all -n "$GATEWAY_NS" 2>/dev/null || true
        kubectl delete httproute --all -A 2>/dev/null || true
        uninstall_component "Gateway Fabric" "$GATEWAY_NS" "nginx-gateway-fabric"
    fi
    
    # 5. MetalLB
    if kubectl get namespace "$METALLB_NS" &>/dev/null; then
        # Remove IP pools first
        kubectl delete ipaddresspool --all -n "$METALLB_NS" 2>/dev/null || true
        kubectl delete l2advertisement --all -n "$METALLB_NS" 2>/dev/null || true
        uninstall_component "MetalLB" "$METALLB_NS" "metallb"
    fi
    
    # Calculate time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "Uninstallation Complete"
    
    echo -e "${GREEN}All components have been removed.${NC}"
    echo ""
    echo "Time taken: ${DURATION}s"
    echo ""
    echo "Your cluster is now clean."
    echo ""
}

main "$@"

