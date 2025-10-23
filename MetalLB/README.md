# MetalLB - Load Balancer for Kubernetes

Samsung Kubernetes Platform

## 📋 Overview

MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.

## 📁 Files

```
MetalLB/
├── install.sh                    # Automated installation script
├── metallb-0.15.2.tgz           # MetalLB Helm chart
├── metallb-addresspool.yaml     # IP pool configuration (legacy - for reference)
└── README.md                    # This file
```

## 🚀 Installation

### Option 1: Automated (Recommended)

```bash
# Edit cluster configuration
vim ../cluster-config.yaml

# Run installation
./install.sh
```

### Option 2: Manual

```bash
# Create namespace
kubectl create namespace metallb-system

# Install MetalLB
helm install metallb metallb-0.15.2.tgz -n metallb-system

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=metallb -n metallb-system --timeout=120s

# Create IP address pool
kubectl apply -f metallb-addresspool.yaml
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
metallb:
  namespace: "metallb-system"
  pool_name: "dcs-pool"
  ip_range: "192.168.33.154-192.168.33.160"  # ← Change this
```

## ✅ Verification

```bash
# Check pods
kubectl get pods -n metallb-system

# Check IP address pool
kubectl get ipaddresspool -n metallb-system

# Check L2Advertisement
kubectl get l2advertisement -n metallb-system
```

## 🔧 Troubleshooting

### Pods not ready
```bash
kubectl describe pods -n metallb-system
kubectl logs -n metallb-system -l component=controller
```

### No external IP assigned
```bash
# Check IP pool configuration
kubectl describe ipaddresspool -n metallb-system

# Check if IP range is available on network
```

## 📚 More Information

- [MetalLB Documentation](https://metallb.universe.tf/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)

