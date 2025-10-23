# Headlamp - Modern Kubernetes Dashboard

Samsung Kubernetes Platform

## 📋 Overview

Headlamp is a modern, easy-to-use Kubernetes web UI with real-time cluster monitoring and management capabilities.

**Features:**
- ✅ Modern and intuitive user interface
- ✅ Real-time cluster monitoring
- ✅ Resource viewing and editing
- ✅ Token-based authentication
- ✅ OIDC authentication support (optional)
- ✅ Multi-cluster support

## 📁 Files

```
Headlamp/
├── install.sh                          # Automated installation script
├── headlamp-0.34.0.tgz                # Headlamp Helm chart
├── headlamp-admin-user.yaml           # Admin service account configuration
├── headlamp-httproute-fabric.yaml     # HTTPRoute for Gateway (legacy - for reference)
├── headlamp-values.yaml               # Helm values
├── headlamp-token.txt                 # Admin token (generated)
├── headlamp-config/                   # Additional configuration files
└── README.md                          # This file
```

## 🚀 Installation

### Option 1: Automated (Recommended)

```bash
# Edit cluster configuration
vim ../cluster-config.yaml

# Run installation
./install.sh
```

The script will:
1. Create namespace
2. Install Headlamp via Helm
3. Create admin service account with cluster-admin role
4. Create HTTPRoute for Gateway access
5. Wait for pods to be ready

### Option 2: Manual

```bash
# Create namespace
kubectl create namespace headlamp

# Install Headlamp
helm install headlamp headlamp-0.34.0.tgz \
  -n headlamp \
  -f headlamp-values.yaml

# Create admin user
kubectl apply -f headlamp-admin-user.yaml

# Create HTTPRoute
kubectl apply -f headlamp-httproute-fabric.yaml

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=headlamp -n headlamp --timeout=120s
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
cluster:
  domain: "samsung.local"  # ← Change this

headlamp:
  namespace: "headlamp"
  hostname: "headlamp.samsung.local"  # ← Change this
  admin:
    email: "admin@samsung.local"
  oidc:
    enabled: false  # Set to true for DEX integration
```

## 🔐 Access

### 1. Add DNS Entry

Add to your `/etc/hosts` or DNS:

```bash
192.168.33.157  headlamp.samsung.local
```

### 2. Access Headlamp

Open in browser:
```
https://headlamp.samsung.local
```

### 3. Get Admin Token

```bash
kubectl get secret -n headlamp -o jsonpath='{.data.token}' \
  $(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print $1}') \
  | base64 -d
```

Or if token was saved during installation:
```bash
cat headlamp-token.txt
```

## ✅ Verification

```bash
# Check pods
kubectl get pods -n headlamp

# Check HTTPRoute
kubectl get httproute -n headlamp

# Check service
kubectl get svc -n headlamp

# Check admin service account
kubectl get sa headlamp-admin -n headlamp
kubectl get clusterrolebinding headlamp-admin

# Test access
curl -k https://headlamp.samsung.local
```

## 🎯 Features & Usage

### Resource Management
- View and edit all Kubernetes resources
- Real-time updates
- YAML editor with validation
- Resource logs and events

### Cluster Monitoring
- Node status and metrics
- Pod status across namespaces
- Resource usage charts
- Event timeline

### Access Control
- Token-based authentication (default)
- OIDC authentication (with DEX)
- RBAC integration
- Multi-user support

## 🔧 Troubleshooting

### Dashboard not accessible

```bash
# Check pods
kubectl get pods -n headlamp
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp

# Check HTTPRoute
kubectl describe httproute headlamp-route -n headlamp

# Check if Gateway is ready
kubectl get gateway samsung-gateway-fabric -n nginx-gateway
```

### Token not working

```bash
# Regenerate token
kubectl get secret -n headlamp -o jsonpath='{.data.token}' \
  $(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print $1}') \
  | base64 -d

# Check service account
kubectl get sa headlamp-admin -n headlamp

# Check cluster role binding
kubectl get clusterrolebinding headlamp-admin
```

### OIDC authentication issues

```bash
# Make sure DEX is installed and running
kubectl get pods -n dex

# Check OIDC configuration in headlamp-values.yaml
# Verify issuer URL matches DEX URL

# Check Headlamp logs
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp
```

## 🔄 Switching to OIDC Authentication

1. Install DEX:
```bash
cd ../DEX
./install.sh
```

2. Enable OIDC in `cluster-config.yaml`:
```yaml
headlamp:
  oidc:
    enabled: true
    issuer_url: "https://dex.samsung.local"
    client_id: "headlamp"
    client_secret: "headlamp-secret-change-me"
```

3. Reinstall Headlamp:
```bash
./install.sh
```

## 📚 More Information

- [Headlamp Documentation](https://headlamp.dev/docs/)
- [Headlamp GitHub](https://github.com/headlamp-k8s/headlamp)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)


