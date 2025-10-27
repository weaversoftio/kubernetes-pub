# NGINX Gateway Fabric - Kubernetes Gateway API

Samsung Kubernetes Platform

## 📋 Overview

NGINX Gateway Fabric is an implementation of the Kubernetes Gateway API using NGINX as the data plane.

**Features:**
- ✅ Gateway API support (HTTPRoute, TLSRoute, etc.)
- ✅ Automatic TLS termination
- ✅ LoadBalancer integration with MetalLB
- ✅ High performance NGINX data plane

## 📁 Files

```
Gateway-Fabric/
├── install.sh                          # Automated installation script
├── nginx-gateway-fabric-1.5.1.tgz     # NGINX Gateway Fabric Helm chart
├── gateway.yaml                        # Gateway resource (legacy - for reference)
├── tls-certificate.yaml                # TLS certificate template
├── values.yaml                         # Helm values (legacy - for reference)
└── README.md                           # This file
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
2. Generate self-signed TLS certificate
3. Install NGINX Gateway Fabric
4. Create Gateway resource with TLS

### Option 2: Manual

```bash
# Create namespace
kubectl create namespace nginx-gateway

# Create TLS certificate
kubectl create secret tls samsung-tls-certificate \
  --cert=tls.crt --key=tls.key \
  -n nginx-gateway

# Install NGINX Gateway Fabric
helm install nginx-gateway-fabric nginx-gateway-fabric-1.5.1.tgz \
  -n nginx-gateway \
  -f values.yaml

# Create Gateway
kubectl apply -f gateway.yaml
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
cluster:
  domain: "samsung.local"  # ← Change this

gateway:
  namespace: "nginx-gateway"
  loadbalancer_ip: "192.168.33.157"  # ← Change this (must be in MetalLB range)
  tls_secret_name: "samsung-tls-certificate"
```

## ✅ Verification

```bash
# Check pods
kubectl get pods -n nginx-gateway

# Check Gateway resource
kubectl get gateway -n nginx-gateway
kubectl describe gateway samsung-gateway-fabric -n nginx-gateway

# Check service (should have EXTERNAL-IP)
kubectl get svc -n nginx-gateway

# Test HTTPS
curl -k https://<LOADBALANCER_IP>
```

## 🌐 Using the Gateway

To route traffic through the Gateway, create HTTPRoute resources:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: my-app
spec:
  parentRefs:
  - name: samsung-gateway-fabric
    namespace: nginx-gateway
  hostnames:
  - "myapp.samsung.local"
  rules:
  - backendRefs:
    - name: my-app-service
      port: 80
```

## 🔧 Troubleshooting

### Gateway not accepting routes
```bash
kubectl describe gateway samsung-gateway-fabric -n nginx-gateway
# Check "Conditions" section
```

### TLS certificate issues
```bash
kubectl get secret samsung-tls-certificate -n nginx-gateway
kubectl describe secret samsung-tls-certificate -n nginx-gateway
```

### No LoadBalancer IP assigned
```bash
# Make sure MetalLB is installed and configured
kubectl get ipaddresspool -n metallb-system
```

## 📚 More Information

- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)


