# Kyverno - Convention over Configuration (CoC) Policy Controller

Samsung Kubernetes Platform

## 📋 Overview

Kyverno acts as a **Convention over Configuration** policy controller that automates ingress rule provisioning based on naming conventions.

**Instead of manually creating HTTPRoute/Ingress for each Service, developers just add an annotation and Kyverno does the rest!**

## 🎯 What Kyverno Does

### 1. **Auto-Generate HTTPRoute** 🚀
When a developer creates a Service with annotation `expose: "true"`, Kyverno automatically creates:
- HTTPRoute with DNS name: `{service-name}-{namespace}.samsung.local`
- Connection to Gateway
- Backend reference to the Service

### 2. **Enforce Naming Conventions** ✅
Validates that Service names follow DNS-compatible naming:
- Lowercase letters (a-z)
- Numbers (0-9)
- Hyphens (-) only
- Must start/end with letter or number

### 3. **Auto-Add Gateway Reference** 🔗
Ensures all HTTPRoutes are connected to `samsung-gateway-fabric` Gateway

---

## 📁 Files

```
kyverno/
├── install.sh                              # Installation script
├── kyverno-3.3.7.tgz                      # Kyverno Helm chart (offline)
├── values.yaml                            # Kyverno Helm values (enables webhooks)
├── kyverno-gateway-api-rbac.yaml          # RBAC permissions for Gateway API
├── generate-httproute-from-service.yaml   # Policy: Auto-creates HTTPRoute
├── validate-service-naming.yaml           # Policy: Enforces naming conventions
├── add-gateway-parent-ref.yaml            # Policy: Adds Gateway reference
└── README.md                              # This file
```

---

## 🚀 Installation

```bash
cd kyverno
./install.sh
```

This installs:
1. Kyverno policy engine (with webhooks enabled via `values.yaml`)
2. Gateway API RBAC permissions (required for HTTPRoute generation)
3. Three CoC policies:
   - `generate-httproute-from-service` - Auto-creates HTTPRoute
   - `validate-service-naming` - Validates naming (Audit mode)
   - `add-gateway-parent-ref` - Adds Gateway reference

**Note:** The installation uses `--no-hooks` to avoid stuck post-install jobs in air-gapped environments.

---

## 💡 Usage - Convention over Configuration

### **Before (Manual - old way):**

```yaml
# 1. Create Service
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: production
spec:
  ports:
  - port: 80

---
# 2. Manually create HTTPRoute 😓
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: production
spec:
  parentRefs:
  - name: samsung-gateway-fabric
    namespace: nginx-gateway
  hostnames:
  - "my-app-production.samsung.local"
  rules:
  - backendRefs:
    - name: my-app
      port: 80
```

### **After (Convention over Configuration - new way):**

```yaml
# Just add annotation expose: "true" - that's it! ✨
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: production
  annotations:
    expose: "true"  # ← HTTPRoute auto-generated!
spec:
  ports:
  - port: 80
```

**Kyverno automatically creates the HTTPRoute!**

---

## 📝 Naming Convention

**Format:** `{service-name}-{namespace}.{cluster-name}.dns.local`

**Examples:**
- Service: `api` in namespace `production` → `api-production.samsung.local`
- Service: `web-app` in namespace `frontend` → `web-app-frontend.samsung.local`
- Service: `db-service` in namespace `backend` → `db-service-backend.samsung.local`

**Cluster domain can be customized** by editing the policy.

---

## 🔧 How It Works

```
1. Developer creates Service with annotation expose: "true"
          ↓
2. Kyverno validate-service-naming: Checks service name is valid
          ↓
3. Kyverno generate-httproute-from-service: Creates HTTPRoute
    - hostname: {service}-{namespace}.samsung.local
    - parentRef: samsung-gateway-fabric
    - backendRef: points to the Service
          ↓
4. Kyverno add-gateway-parent-ref: Ensures Gateway reference exists
          ↓
5. Gateway API processes the HTTPRoute
          ↓
6. Ingress API Gateway terminates TLS
          ↓
7. MetalLB assigns VIP
          ↓
8. Service is accessible at: https://{service}-{namespace}.samsung.local
```

---

## 📋 Examples

### Example 1: Expose a Simple App

```bash
# Create namespace
kubectl create namespace demo

# Create deployment
kubectl create deployment my-app --image=nginx -n demo

# Create and expose Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: demo
  annotations:
    expose: "true"  # ← Auto-generate HTTPRoute
spec:
  selector:
    app: my-app
  ports:
  - port: 80
EOF

# Verify HTTPRoute was created
kubectl get httproute -n demo

# Access your app
curl https://my-app-demo.samsung.local
```

### Example 2: Expose Existing Service

```bash
# Add annotation to existing Service
kubectl annotate service my-service expose=true -n production

# HTTPRoute will be auto-generated!
kubectl get httproute -n production
```

### Example 3: Remove Exposure

```bash
# Remove annotation to delete HTTPRoute
kubectl annotate service my-app expose- -n demo

# HTTPRoute will be auto-deleted (if synchronize: true)
```

---

## ✅ Verification

### Check Policies

```bash
# List installed policies
kubectl get clusterpolicy

# Should show:
# - generate-httproute-from-service
# - validate-service-naming
# - add-gateway-parent-ref

# Check policy details
kubectl describe clusterpolicy generate-httproute-from-service
```

### Check Auto-Generated HTTPRoutes

```bash
# List all HTTPRoutes
kubectl get httproute -A

# Check specific HTTPRoute
kubectl describe httproute my-app-route -n demo

# Look for:
# - Label: managed-by: kyverno
# - Label: auto-generated: "true"
# - Annotation: kyverno.io/generated-by
```

### Check Kyverno Logs

```bash
# View Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=50

# Check for policy violations
kubectl get events -n kyverno
```

---

## ✅ Verification

After installation, verify that everything is working:

```bash
# Check Kyverno pods
kubectl get pods -n kyverno
# Expected: 4 pods in Running state

# Check policies
kubectl get clusterpolicy
# Expected: 3 policies (generate-httproute-from-service, validate-service-naming, add-gateway-parent-ref)

# Check RBAC
kubectl get clusterrole kyverno-gateway-api
# Expected: ClusterRole exists
```

### Test CoC functionality (optional):

```bash
# Create a test namespace and service
kubectl create ns demo-test
kubectl create deployment nginx --image=nginx --port=80 -n demo-test
kubectl expose deployment nginx --port=80 -n demo-test
kubectl annotate service nginx -n demo-test expose="true"

# Wait 5-10 seconds for Kyverno to process

# Check if HTTPRoute was created
kubectl get httproute -n demo-test
# Expected: nginx-route

# View details
kubectl describe httproute nginx-route -n demo-test
# Expected: hostname: nginx-demo-test.samsung.local

# Cleanup
kubectl delete ns demo-test
```

---

## 🔧 Configuration

### Customize Domain Name

Edit `generate-httproute-from-service.yaml`:

```yaml
hostnames:
- "{{request.object.metadata.name}}-{{request.namespace}}.your-domain.com"
```

### Change Annotation Name

Edit `generate-httproute-from-service.yaml`:

```yaml
annotations:
  your-annotation-name: "true"
```

### Disable Auto-Generation for Specific Namespaces

Already configured to exclude:
- `kube-system`
- `kube-public`
- `kube-node-lease`

Add more in the `exclude` section of the policy.

---

## 🛡️ Policies Explained

### 1. generate-httproute-from-service.yaml

**Purpose:** Auto-creates HTTPRoute when Service has `expose: "true"` annotation

**Trigger:** Service creation/update with annotation

**Action:** Generates HTTPRoute with:
- Name: `{service-name}-route`
- Hostname: `{service}-{namespace}.samsung.local`
- ParentRef to Gateway
- BackendRef to Service

### 2. validate-service-naming.yaml

**Purpose:** Enforces naming convention for exposed services

**Trigger:** Service with `expose: "true"` annotation

**Validates:**
- Lowercase letters, numbers, hyphens only
- Must start with letter
- Must end with letter or number
- Max 63 characters

**Blocks:** Services with invalid names (uppercase, underscores, dots, etc.)

### 3. add-gateway-parent-ref.yaml

**Purpose:** Safety policy - adds Gateway reference if missing

**Trigger:** HTTPRoute without parentRefs

**Action:** Adds `samsung-gateway-fabric` as parent

**Use case:** Manual HTTPRoute creation, migration from old resources

---

## 🔍 Troubleshooting

### HTTPRoute Not Created

```bash
# Check if Service has annotation
kubectl get service my-app -n demo -o yaml | grep expose

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno | grep generate

# Check for policy violations
kubectl describe service my-app -n demo
```

### Naming Validation Failed

```bash
# Error: Service name invalid
# Fix: Use lowercase, hyphens only
# Invalid: My-App, my_app
# Valid: my-app, myapp

kubectl get events -n demo | grep validation
```

### HTTPRoute Not Routing Traffic

```bash
# Check HTTPRoute status
kubectl describe httproute my-app-route -n demo

# Check Gateway status
kubectl describe gateway samsung-gateway-fabric -n nginx-gateway

# Check if hostname resolves
nslookup my-app-demo.samsung.local
```

---

## 📚 More Information

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Generate Policies](https://kyverno.io/docs/writing-policies/generate/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Convention over Configuration](https://en.wikipedia.org/wiki/Convention_over_configuration)

---

## 🎯 Benefits of CoC Approach

✅ **Developers don't write HTTPRoute/Ingress manually**  
✅ **Consistent naming across all services**  
✅ **Automatic DNS-compatible names**  
✅ **Reduced configuration errors**  
✅ **Faster onboarding for new developers**  
✅ **Single source of truth (Service annotation)**  
✅ **Easy to manage at scale**  

---

**Ready to use? See `example-service.yaml` for a complete working example!** 🚀

