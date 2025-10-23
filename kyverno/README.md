# Kyverno - Policy Engine for Kubernetes

Samsung Kubernetes Platform

## 📋 Overview

Kyverno is a policy engine designed for Kubernetes. It can validate, mutate, and generate configurations using admission controls and background scans.

## 📁 Files

```
kyverno/
├── install.sh                      # Automated installation script
├── add-ingress-class-nginx.yaml    # Policy: Auto-add nginx IngressClass
└── README.md                       # This file
```

## 🚀 Installation

### Option 1: Automated (Recommended)

```bash
# Edit cluster configuration (optional)
vim ../cluster-config.yaml

# Run installation
./install.sh
```

### Option 2: Manual

```bash
# Add Helm repository
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# Apply policies
kubectl apply -f add-ingress-class-nginx.yaml
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
kyverno:
  namespace: "kyverno"
  policies:
    auto_ingress_class: true  # Auto-add nginx IngressClass
```

## 📜 Included Policies

### 1. Add IngressClass NGINX

**File:** `add-ingress-class-nginx.yaml`

**What it does:** Automatically adds `ingressClassName: nginx` to all Ingress resources that don't have one specified.

**Example:**
```yaml
# Before (user creates this)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  rules:
  - host: myapp.example.com
    # ... rest of spec

# After (Kyverno mutates it)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  ingressClassName: nginx  # ← Added automatically!
  rules:
  - host: myapp.example.com
    # ... rest of spec
```

## ✅ Verification

```bash
# Check Kyverno pods
kubectl get pods -n kyverno

# List all policies
kubectl get clusterpolicy

# Check policy status
kubectl describe clusterpolicy add-ingress-class-nginx

# Test the policy (create a test Ingress)
kubectl create ingress test --rule="test.example.com/*=test-svc:80" -n default
kubectl get ingress test -n default -o yaml | grep ingressClassName
# Should show: ingressClassName: nginx
```

## 🔧 Adding More Policies

Create a new policy file:

```bash
cat > my-policy.yaml <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-policy
spec:
  rules:
  - name: my-rule
    # ... policy definition
EOF

kubectl apply -f my-policy.yaml
```

## 🛠️ Troubleshooting

### Policy not applying
```bash
# Check policy status
kubectl describe clusterpolicy <policy-name>

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller

# Check webhook
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno
```

### Policy errors
```bash
# View policy reports
kubectl get policyreport -A

# Describe specific report
kubectl describe policyreport <report-name> -n <namespace>
```

## 📚 More Information

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policies Library](https://kyverno.io/policies/)
- [Policy Writing Guide](https://kyverno.io/docs/writing-policies/)

