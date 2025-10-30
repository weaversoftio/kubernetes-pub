# DEX - OIDC Authentication Provider

Samsung Kubernetes Platform

## 📋 Overview

DEX is an identity service that uses OpenID Connect (OIDC) to provide authentication for other applications.

**Features:**
- ✅ OpenID Connect (OIDC) authentication
- ✅ Static user authentication (for testing/demo)
- ✅ LDAP/Active Directory integration (for production)
- ✅ Integration with Kubernetes API server
- ✅ Integration with Headlamp dashboard
- ✅ Multiple authentication backends

## 📁 Files

```
DEX/
├── install.sh                          # Automated installation script
├── dex-0.18.0.tgz                     # DEX Helm chart
├── dex-values.yaml                    # DEX configuration
├── dex-httproute.yaml                 # HTTPRoute for Gateway
├── rbac-admin-user.yaml               # RBAC for OIDC users
├── headlamp-oidc-values.yaml          # Headlamp OIDC configuration
├── kube-apiserver-oidc-patch.yaml     # Kubernetes API server OIDC configuration
└── README.md                          # This file
```

## 🚀 Installation

### Prerequisites

- MetalLB installed and configured
- NGINX Gateway Fabric installed and running
- Headlamp installed (for dashboard authentication)

### Option 1: Automated (Recommended)

```bash
# 1. Edit cluster configuration
vim ../cluster-config.yaml

# 2. Enable DEX
# Set: dex.enabled: true

# 3. Run installation
./install.sh
```

The script will:
1. Check if DEX is enabled in configuration
2. Create namespace
3. Install DEX via Helm
4. Create HTTPRoute for Gateway access
5. Apply RBAC for OIDC users
6. Wait for pods to be ready

### Option 2: Manual

```bash
# Create namespace
kubectl create namespace dex

# Install DEX
helm install dex dex-0.18.0.tgz \
  -n dex \
  -f dex-values.yaml

# Create HTTPRoute
kubectl apply -f dex-httproute.yaml

# Apply RBAC
kubectl apply -f rbac-admin-user.yaml

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=dex -n dex --timeout=120s
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
cluster:
  domain: "samsung.local"  # ← Change this

dex:
  enabled: true  # ← Set to true to install
  namespace: "dex"
  hostname: "dex.samsung.local"  # ← Change this
  
  # Static users (for testing/demo)
  static_users:
    - email: "admin@samsung.local"
      password_hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
      username: "admin"
  
  # LDAP/AD (for production)
  ldap:
    enabled: false
    host: "ldap.samsung.local:389"
    bind_dn: "cn=admin,dc=samsung,dc=local"
    bind_password: "password"
    base_dn: "dc=samsung,dc=local"
```

## 🔐 Default Users

When using static authentication (for testing):

| Email | Password | Username |
|-------|----------|----------|
| admin@samsung.local | admin | admin |
| user@samsung.local | admin | user |

⚠️ **Security Note:** Change these credentials in production!

## 🔗 Integration with Headlamp

After installing DEX, configure Headlamp to use OIDC:

```bash
# 1. Edit cluster-config.yaml
vim ../cluster-config.yaml

# 2. Enable OIDC for Headlamp
headlamp:
  oidc:
    enabled: true
    issuer_url: "https://dex.samsung.local"
    client_id: "headlamp"
    client_secret: "headlamp-secret-change-me"

# 3. Reinstall Headlamp
cd ../Headlamp
./install.sh
```

## 🔗 Integration with Kubernetes API Server

To enable OIDC authentication for `kubectl`:

1. Apply OIDC configuration to API server:
```bash
kubectl apply -f kube-apiserver-oidc-patch.yaml
```

2. Configure `kubectl` to use OIDC:
```bash
kubectl oidc-login setup \
  --oidc-issuer-url=https://dex.samsung.local \
  --oidc-client-id=kubernetes
```

See `kube-apiserver-oidc-patch.yaml` for details.

## 🔐 Login to Headlamp with DEX OIDC

After configuration, Headlamp will show a "Sign in with OIDC" button.

**Login credentials:**
- **Username:** `admin@dcs.local`
- **Password:** `admin`

After successful login, Headlamp will use DEX authentication and RBAC will control access based on email.

## ✅ Verification

```bash
# Check pods
kubectl get pods -n dex

# Check HTTPRoute
kubectl get httproute -n dex

# Check service
kubectl get svc -n dex

# Test OIDC discovery endpoint
curl -k https://dex.samsung.local/.well-known/openid-configuration

# Verify configuration
kubectl get configmap dex -n dex -o yaml
```

## 🌐 Access DEX

### 1. Add DNS Entry

Add to your `/etc/hosts` or DNS:

```bash
192.168.33.157  dex.samsung.local
```

### 2. Access DEX

Open in browser:
```
https://dex.samsung.local
```

## 🔧 Troubleshooting

### DEX not accessible

```bash
# Check pods
kubectl get pods -n dex
kubectl logs -n dex -l app.kubernetes.io/name=dex

# Check HTTPRoute
kubectl describe httproute dex-route -n dex

# Check if Gateway is ready
kubectl get gateway samsung-gateway-fabric -n nginx-gateway
```

### OIDC authentication not working

```bash
# Check DEX logs
kubectl logs -n dex -l app.kubernetes.io/name=dex

# Verify OIDC configuration
curl -k https://dex.samsung.local/.well-known/openid-configuration

# Check client configuration
kubectl get configmap dex -n dex -o yaml | grep -A10 staticClients
```

### LDAP connection issues

```bash
# Check DEX logs
kubectl logs -n dex -l app.kubernetes.io/name=dex | grep -i ldap

# Verify LDAP configuration
kubectl get configmap dex -n dex -o yaml | grep -A20 connectors

# Test LDAP connectivity
kubectl exec -n dex deployment/dex -- nc -zv ldap.samsung.local 389
```

### Password hash generation

To generate password hash for static users:

```bash
# Install htpasswd if not available
sudo apt-get install apache2-utils

# Generate password hash
echo "your-password" | htpasswd -BinC 10 username | cut -d: -f2
```

## 🔄 Production Setup

For production environments:

1. **Disable static users:**
```yaml
dex:
  static_users: []
```

2. **Enable LDAP/AD:**
```yaml
dex:
  ldap:
    enabled: true
    host: "ldap.company.com:389"
    bind_dn: "cn=service-account,dc=company,dc=com"
    bind_password: "secure-password"
    base_dn: "dc=company,dc=com"
```

3. **Use real TLS certificates:**
- Replace self-signed certificates with certificates from your CA
- Configure DEX to use proper TLS

4. **Change client secrets:**
```yaml
headlamp:
  oidc:
    client_secret: "use-a-strong-random-secret"
```

## 📚 More Information

- [DEX Documentation](https://dexidp.io/docs/)
- [DEX GitHub](https://github.com/dexidp/dex)
- [OpenID Connect Specification](https://openid.net/connect/)
- [Kubernetes OIDC Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)


