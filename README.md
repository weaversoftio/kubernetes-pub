# 🚀 Samsung Kubernetes Platform

Complete Kubernetes infrastructure deployment toolkit for enterprise environments.

## 📋 Overview

This repository contains automated installation scripts and configurations for deploying a complete Kubernetes platform with:

- **MetalLB** - Load Balancer for bare metal clusters
- **NGINX Gateway Fabric** - Modern Gateway API implementation with TLS
- **Kyverno** - Policy engine for security and automation
- **Headlamp** - Modern Kubernetes dashboard
- **DEX** - OIDC authentication provider (optional)
- **Trident** - NetApp storage CSI driver (optional)

## 🎯 Features

✅ **One-Click Installation** - Install entire stack with a single command  
✅ **Centralized Configuration** - Edit one file (`cluster-config.yaml`) for all settings  
✅ **Production Ready** - Secure defaults with TLS, RBAC, and authentication  
✅ **Offline Support** - Air-gapped installation with pre-downloaded images  
✅ **Idempotent** - Safe to run multiple times  
✅ **Modular** - Install individual components or the complete stack

---

## 📁 Repository Structure

```
samsung-kubernetes-pub/
├── cluster-config.yaml          # ⚙️ Main configuration file
├── install-all.sh              # 🚀 Complete installation script
├── uninstall-all.sh            # 🗑️ Complete removal script
├── README.md                   # 📖 This file
│
├── MetalLB/                    # Load Balancer
│   ├── install.sh
│   ├── README.md
│   └── metallb-0.15.2.tgz
│
├── Gateway-Fabric/             # Ingress Gateway
│   ├── install.sh
│   ├── README.md
│   └── nginx-gateway-fabric-1.5.1.tgz
│
├── kyverno/                    # Policy Engine
│   ├── install.sh
│   ├── README.md
│   ├── kyverno-3.3.7.tgz
│   └── add-gateway-parent-ref.yaml
│
├── Headlamp/                   # Kubernetes Dashboard
│   ├── install.sh
│   ├── README.md
│   └── headlamp-0.34.0.tgz
│
├── DEX/                        # OIDC Authentication
│   ├── install.sh
│   ├── README.md
│   └── dex-0.18.0.tgz
│
├── Trident/                    # NetApp Storage CSI Driver
│   ├── install.sh
│   ├── README.md
│   └── trident-operator-100.2410.0.tgz
│
└── offline-images/             # Offline installation support
    ├── download-images.sh
    ├── load-images.sh
    └── README.md
```

---

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (v1.24+)
- `kubectl` configured and working
- `helm` v3.x installed
- `openssl` for certificate generation
- Cluster admin permissions

### Installation Steps

#### 1️⃣ Clone the Repository

```bash
git clone <repository-url>
cd samsung-kubernetes-pub
```

#### 2️⃣ Edit Configuration

Edit `cluster-config.yaml` with your environment settings:

```bash
vim cluster-config.yaml
```

**Key settings to change:**

```yaml
cluster:
  domain: "samsung.local"        # ← Your domain

metallb:
  ip_range: "192.168.33.154-192.168.33.160"  # ← Your IP range

gateway:
  loadbalancer_ip: "192.168.33.157"  # ← Gateway IP (must be in range)
```

#### 3️⃣ Run Installation

```bash
chmod +x install-all.sh
./install-all.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Validate configuration
- ✅ Install all components in the correct order
- ✅ Configure networking and security
- ✅ Display access information

**Installation time:** ~5-10 minutes

#### 4️⃣ Add DNS/Hosts Entry

Add the following to your `/etc/hosts` (or configure DNS):

```bash
192.168.33.157  headlamp.samsung.local
192.168.33.157  dex.samsung.local  # if DEX is enabled
```

#### 5️⃣ Access Headlamp

Open your browser:

```
https://headlamp.samsung.local
```

Get the admin token:

```bash
kubectl get secret -n headlamp -o jsonpath='{.data.token}' $(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print $1}') | base64 -d
```

---

## 🛠️ Individual Component Installation

You can also install components individually:

```bash
# Install only MetalLB
cd MetalLB
./install.sh

# Install only Gateway Fabric
cd Gateway-Fabric
./install.sh

# Install only Headlamp
cd Headlamp
./install.sh
```

Each component reads from the main `cluster-config.yaml` file.

---

## ⚙️ Configuration Guide

### cluster-config.yaml Structure

```yaml
# General cluster settings
cluster:
  domain: "samsung.local"        # Base domain for all services

# MetalLB configuration
metallb:
  namespace: "metallb-system"
  ip_range: "192.168.33.154-192.168.33.160"

# Gateway configuration
gateway:
  namespace: "nginx-gateway"
  loadbalancer_ip: "192.168.33.157"
  tls_secret_name: "samsung-tls-certificate"

# Headlamp configuration
headlamp:
  namespace: "headlamp"
  hostname: "headlamp.samsung.local"
  oidc:
    enabled: false  # Set to true for DEX integration

# DEX configuration (optional)
dex:
  enabled: false  # Set to true to install DEX
  hostname: "dex.samsung.local"
```

See `cluster-config.yaml` for all available options and documentation.

---

## 🔐 Security Features

### TLS/SSL

- ✅ Automatic self-signed certificate generation
- ✅ TLS termination at the Gateway
- ✅ All services accessible via HTTPS

### Authentication

- ✅ Token-based authentication (default)
- ✅ OIDC authentication with DEX (optional)
- ✅ RBAC integration

### Network Security

- ✅ ClusterIP services (not exposed directly)
- ✅ Single LoadBalancer entry point (Gateway)
- ✅ HTTPRoute-based routing

---

## 📊 Component Details

### MetalLB

**Purpose:** Provides LoadBalancer service type support on bare metal

**What it does:**
- Assigns external IPs to LoadBalancer services
- L2 advertisement for IP reachability

**Configuration:**
- IP address pool
- L2 advertisement settings

### NGINX Gateway Fabric

**Purpose:** Modern ingress controller using Gateway API

**What it does:**
- TLS termination
- HTTP/HTTPS routing
- Gateway API implementation

**Configuration:**
- LoadBalancer IP
- TLS certificate
- Gateway listeners (HTTP/HTTPS)

### Kyverno

**Purpose:** Policy engine for Kubernetes

**What it does:**
- Automatic policy enforcement
- Resource mutation
- Validation and generation

**Included Policies:**
- Auto-add `ingressClassName: nginx` to Ingress resources

### Headlamp

**Purpose:** Modern Kubernetes web dashboard

**What it does:**
- Cluster management UI
- Resource viewing and editing
- Real-time monitoring

**Configuration:**
- Access URL
- Admin user setup
- OIDC integration (optional)

### DEX (Optional)

**Purpose:** OIDC authentication provider

**What it does:**
- Single Sign-On (SSO)
- LDAP/AD integration
- User authentication

**Configuration:**
- Static users (for testing)
- LDAP connector (for production)

### Trident (Optional)

**Purpose:** NetApp storage CSI driver for persistent volumes

**What it does:**
- Dynamic volume provisioning
- NetApp ONTAP integration
- Volume snapshots and clones
- Storage efficiency features

**Configuration:**
- NetApp ONTAP backend
- StorageClass definition
- NFS or iSCSI protocols

---

## 🧪 Verification

After installation, verify all components:

```bash
# Check all pods
kubectl get pods -A | grep -E 'metallb|nginx-gateway|kyverno|headlamp|dex'

# Check Gateway
kubectl get gateway -A

# Check LoadBalancer services
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Check HTTPRoutes
kubectl get httproute -A

# Test Gateway endpoint
curl -k https://headlamp.samsung.local
```

---

## 🔄 Updates and Maintenance

### Updating Components

```bash
# Update individual component
cd <component-directory>
./install.sh  # Re-run installation (idempotent)

# Or update all
./install-all.sh  # Safe to re-run
```

### Viewing Logs

```bash
# MetalLB
kubectl logs -n metallb-system -l component=controller

# Gateway Fabric
kubectl logs -n nginx-gateway -l app.kubernetes.io/instance=nginx-gateway-fabric

# Kyverno
kubectl logs -n kyverno -l app.kubernetes.io/instance=kyverno

# Headlamp
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp

# DEX
kubectl logs -n dex -l app.kubernetes.io/name=dex
```

---

## 🗑️ Uninstallation

To remove all components:

```bash
chmod +x uninstall-all.sh
./uninstall-all.sh
```

**Warning:** This will remove ALL installed components and cannot be undone.

To remove individual components:

```bash
# Remove Helm release
helm uninstall <release-name> -n <namespace>

# Remove namespace
kubectl delete namespace <namespace>
```

---

## 🌐 Offline Installation

For air-gapped environments:

### 1. Download Images (on internet-connected machine)

```bash
cd offline-images
./download-images.sh
```

### 2. Transfer to Target Environment

```bash
# Create archive
tar -czf offline-images.tar.gz offline-images/

# Transfer to target machine
scp offline-images.tar.gz user@target:/path/
```

### 3. Load Images (on target machine)

```bash
tar -xzf offline-images.tar.gz
cd offline-images
./load-images.sh
```

### 4. Install Platform

```bash
# Edit configuration
vim cluster-config.yaml

# Set offline mode
# offline:
#   enabled: true

# Install
./install-all.sh
```

See `offline-images/README.md` for details.

---

## 🛠️ Troubleshooting

### MetalLB not assigning IPs

```bash
# Check IP pool
kubectl get ipaddresspool -n metallb-system
kubectl describe ipaddresspool -n metallb-system

# Check speaker pods
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l component=speaker
```

### Gateway not accessible

```bash
# Check Gateway status
kubectl describe gateway -n nginx-gateway

# Check service has external IP
kubectl get svc -n nginx-gateway

# Check pods
kubectl get pods -n nginx-gateway
```

### Headlamp not accessible

```bash
# Check HTTPRoute
kubectl describe httproute headlamp-route -n headlamp

# Check if Gateway is ready
kubectl get gateway -n nginx-gateway

# Check Headlamp pods
kubectl get pods -n headlamp
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp
```

### DNS not resolving

Add to `/etc/hosts`:

```bash
echo "192.168.33.157  headlamp.samsung.local" | sudo tee -a /etc/hosts
echo "192.168.33.157  dex.samsung.local" | sudo tee -a /etc/hosts
```

---

## 📚 Documentation

Each component has detailed documentation:

- [MetalLB/README.md](MetalLB/README.md)
- [Gateway-Fabric/README.md](Gateway-Fabric/README.md)
- [kyverno/README.md](kyverno/README.md)
- [Headlamp/README.md](Headlamp/README.md)
- [DEX/README.md](DEX/README.md)
- [Trident/README.md](Trident/README.md)
- [offline-images/README.md](offline-images/README.md)

External Documentation:
- [MetalLB Documentation](https://metallb.universe.tf/)
- [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/)
- [Kyverno](https://kyverno.io/docs/)
- [Headlamp](https://headlamp.dev/docs/)
- [DEX](https://dexidp.io/docs/)
- [Trident](https://docs.netapp.com/us-en/trident/)

---

## 🤝 Support

For issues or questions:

1. Check component-specific README files
2. Review logs: `kubectl logs -n <namespace>`
3. Verify configuration in `cluster-config.yaml`
4. Check troubleshooting section above

---

## 📄 License

Copyright © 2025 Samsung Kubernetes Platform

---

## 🎯 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet / Users                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (443)
                         ▼
              ┌──────────────────────┐
              │  NGINX Gateway Fabric │  LoadBalancer IP: 192.168.33.157
              │  (TLS Termination)    │  Domain: *.samsung.local
              └──────────┬───────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌──────────┐    ┌─────────┐
    │ Headlamp│    │   DEX    │    │  Other  │
    │Dashboard│    │  (OIDC)  │    │  Apps   │
    └─────────┘    └──────────┘    └─────────┘
         │               │               │
         └───────────────┴───────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Kubernetes API      │
              │  (RBAC + OIDC)       │
              └──────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Kyverno Policies   │
              │  (Auto-enforcement)  │
              └──────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Cluster Resources   │
              └──────────────────────┘
```

---

**🚀 Ready to deploy? Run `./install-all.sh` to get started!**

