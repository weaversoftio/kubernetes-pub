#!/bin/bash

# =====================================================
# Samsung Kubernetes Platform - Complete Installation
# =====================================================
# 
# This script installs all components automatically:
# 1. MetalLB - Load Balancer
# 2. NGINX Gateway Fabric - Ingress Gateway
# 3. Kyverno - Convention over Configuration (CoC) Policy Engine
# 4. Headlamp - Kubernetes Dashboard
# 5. DEX - OIDC Authentication (optional)
# 6. Trident - NetApp Storage CSI Driver (optional)
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

# =====================================================
# Helper Functions
# =====================================================

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

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        print_success "kubectl found"
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    else
        print_success "helm found"
    fi
    
    # Check openssl
    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    else
        print_success "openssl found"
    fi
    
    # Check if cluster is accessible
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes cluster is accessible"
    else
        print_error "Cannot connect to Kubernetes cluster"
        echo "Please check your kubeconfig"
        exit 1
    fi
    
    # Report missing tools
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install missing tools and try again"
        exit 1
    fi
    
    echo ""
}

load_configuration() {
    print_header "Loading Configuration"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        echo ""
        echo "Please create cluster-config.yaml with your cluster settings."
        echo "You can use the existing cluster-config.yaml as a template."
        exit 1
    fi
    
    print_success "Configuration loaded from: cluster-config.yaml"
    
    # Display key configuration
    DOMAIN=$(grep -A10 "^cluster:" "$CONFIG_FILE" | grep "domain:" | awk '{print $2}' | tr -d '"')
    IP_RANGE=$(grep -A10 "^metallb:" "$CONFIG_FILE" | grep "ip_range:" | awk '{print $2}' | tr -d '"')
    GATEWAY_IP=$(grep -A20 "^gateway:" "$CONFIG_FILE" | grep "loadbalancer_ip:" | awk '{print $2}' | tr -d '"')
    
    echo ""
    echo "  Domain: $DOMAIN"
    echo "  MetalLB IP Range: $IP_RANGE"
    echo "  Gateway IP: $GATEWAY_IP"
    echo ""
}

confirm_installation() {
    # Check if dry-run mode
    DRY_RUN=$(grep -A10 "^advanced:" "$CONFIG_FILE" | grep "dry_run:" | awk '{print $2}' | tr -d '"')
    
    if [ "$DRY_RUN" == "true" ]; then
        print_warning "DRY-RUN MODE - No changes will be made"
        echo ""
        return
    fi
    
    echo -e "${YELLOW}This will install the following components:${NC}"
    echo "  1. MetalLB (Load Balancer)"
    echo "  2. NGINX Gateway Fabric (Ingress Gateway)"
    echo "  3. Kyverno (CoC - Auto HTTPRoute Generation)"
    echo "  4. Headlamp (Dashboard)"
    
    # Check if DEX is enabled
    DEX_ENABLED=$(grep -A50 "^dex:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"')
    if [ "$DEX_ENABLED" == "true" ]; then
        echo "  5. DEX (OIDC Authentication)"
    fi
    
    # Check if Trident is enabled
    TRIDENT_ENABLED=$(grep -A100 "^trident:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"')
    if [ "$TRIDENT_ENABLED" == "true" ]; then
        echo "  6. Trident (NetApp Storage CSI Driver)"
    fi
    
    echo ""
    echo -e "${YELLOW}Continue with installation? [y/N]${NC} "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo ""
}

install_component() {
    local component_name=$1
    local install_script=$2
    
    print_header "Installing: $component_name"
    
    if [ ! -f "$install_script" ]; then
        print_error "Install script not found: $install_script"
        return 1
    fi
    
    # Make script executable
    chmod +x "$install_script"
    
    # Run installation
    if bash "$install_script"; then
        print_success "$component_name installed successfully"
        return 0
    else
        print_error "$component_name installation failed"
        return 1
    fi
}

# =====================================================
# Main Installation Flow
# =====================================================

main() {
    clear
    
    print_header "Samsung Kubernetes Platform - Installation"
    
    echo "This script will install a complete Kubernetes platform with:"
    echo "  • MetalLB for LoadBalancer services"
    echo "  • NGINX Gateway Fabric for ingress"
    echo "  • Kyverno for auto-generating HTTPRoute (Convention over Configuration)"
    echo "  • Headlamp for cluster management"
    echo "  • DEX for authentication (optional)"
    echo "  • Trident for NetApp storage (optional)"
    echo ""
    
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Load configuration
    load_configuration
    
    # Step 3: Confirm installation
    confirm_installation
    
    # Track installation start time
    START_TIME=$(date +%s)
    
    # Step 4: Install MetalLB
    if ! install_component "MetalLB" "$SCRIPT_DIR/MetalLB/install.sh"; then
        print_error "Installation stopped due to MetalLB failure"
        exit 1
    fi
    
    # Wait a bit for MetalLB to be fully ready
    echo "Waiting for MetalLB to be fully ready..."
    sleep 10
    
    # Step 5: Install Gateway Fabric
    if ! install_component "NGINX Gateway Fabric" "$SCRIPT_DIR/Gateway-Fabric/install.sh"; then
        print_error "Installation stopped due to Gateway Fabric failure"
        exit 1
    fi
    
    # Wait for Gateway to be ready
    echo "Waiting for Gateway to be fully ready..."
    sleep 10
    
    # Step 6: Install Kyverno
    if ! install_component "Kyverno" "$SCRIPT_DIR/kyverno/install.sh"; then
        print_warning "Kyverno installation failed, continuing..."
    fi
    
    # Step 7: Install Headlamp
    if ! install_component "Headlamp" "$SCRIPT_DIR/Headlamp/install.sh"; then
        print_error "Headlamp installation failed"
    fi
    
    # Step 8: Install DEX (if enabled)
    DEX_ENABLED=$(grep -A50 "^dex:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"')
    if [ "$DEX_ENABLED" == "true" ]; then
        if ! install_component "DEX" "$SCRIPT_DIR/DEX/install.sh"; then
            print_warning "DEX installation failed"
        fi
    fi
    
    # Step 9: Install Trident (if enabled)
    TRIDENT_ENABLED=$(grep -A100 "^trident:" "$CONFIG_FILE" | grep "enabled:" | head -1 | awk '{print $2}' | tr -d '"')
    if [ "$TRIDENT_ENABLED" == "true" ]; then
        if ! install_component "Trident" "$SCRIPT_DIR/Trident/install.sh"; then
            print_warning "Trident installation failed"
        fi
    fi
    
    # Calculate installation time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    # Final summary
    print_header "Installation Complete!"
    
    echo -e "${GREEN}All components have been installed successfully!${NC}"
    echo ""
    echo "Installation time: ${MINUTES}m ${SECONDS}s"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1. Add the following to your /etc/hosts (or DNS):"
    echo "   $GATEWAY_IP  headlamp.$DOMAIN"
    if [ "$DEX_ENABLED" == "true" ]; then
        echo "   $GATEWAY_IP  dex.$DOMAIN"
    fi
    echo ""
    echo "2. Access Headlamp:"
    echo "   https://headlamp.$DOMAIN"
    echo ""
    
    if [ "$DEX_ENABLED" != "true" ]; then
        echo "3. Get Headlamp admin token:"
        echo "   kubectl get secret -n headlamp -o jsonpath='{.data.token}' \$(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print \$1}') | base64 -d"
        echo ""
    fi
    
    if [ "$TRIDENT_ENABLED" == "true" ]; then
        echo "3. Verify Trident storage:"
        echo "   kubectl get tridentorchestrator"
        echo "   kubectl get storageclass"
        echo ""
    fi
    
    echo -e "${GREEN}Verification Commands:${NC}"
    echo "  kubectl get pods -A | grep -E 'metallb|nginx-gateway|kyverno|headlamp|dex|trident'"
    echo "  kubectl get gateway -A"
    echo "  kubectl get svc -n nginx-gateway"
    if [ "$TRIDENT_ENABLED" == "true" ]; then
        echo "  kubectl get tridentbackends -n trident"
        echo "  kubectl get storageclass"
    fi
    echo ""
    
    print_success "Enjoy your Samsung Kubernetes Platform! 🚀"
    echo ""
}

# Run main function
main "$@"

