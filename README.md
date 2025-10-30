# 🚀 DCS Kubernetes Platform — Developer Quick Start & Deployment Guide

---

> **Welcome to the DCS Kubernetes Platform!**
>
> This guide gives you everything you need to understand, configure, and deploy apps smoothly on the DCS K8s stack. Trident and DEX are present for future use only — ignore them for now.

---

## 📦 Core Components — What’s Running?

- **MetalLB:** Provides bare-metal LoadBalancer IPs for your services.
- **Gateway Fabric:** Gateway API-based ingress layer with HTTPS/TLS for all apps.
- **Kyverno:** Automatically creates HTTPRoutes for your services and enforces naming/policy conventions.
- **Headlamp:** User-friendly Kubernetes dashboard — manage your cluster from any browser.
- **Trident, DEX:** Not installed/enabled. Reserved for future integration. Ignore for now!

---

## 🛠️ 1. Prerequisites
- Kubernetes cluster (v1.24+)
- Access to this repo, `kubectl`, and `helm` on your workstation
- Cluster-admin permissions
- Decide on your desired Cluster Domain and IP range for app exposure (see below)

---

## ⚙️ 2. Configuration — BEFORE Deployment

> **DO NOT edit `cluster-config.yaml` alone!** Edit the underlying YAML files in the matching component’s folder for real effect.

#### Update these files for your environment:

1. **MetalLB IP Range:**
    - Edit: `MetalLB/metallb-addresspool.yaml`
    - Example:
      ```yaml
      addresses:
        - 192.168.88.51-192.168.88.60
      ```

2. **Gateway Domain & IP:**
   - Edit: `Gateway-Fabric/gateway.yaml`
   - Example:
     ```yaml
     hostname: "*.dcs.local"
     # ...
     Gateway LoadBalancer IP: use an IP from the MetalLB range above
     ```
   - Edit: `Gateway-Fabric/values.yaml` for `loadBalancerIP:` too.

3. **Headlamp Dashboard URL:**
   - Edit: `Headlamp/headlamp-httproute-fabric.yaml`
   - Example:
     ```yaml
     hostnames:
       - "headlamp.dcs.local"
     ```

4. **Kyverno Auto-Exposure Domain:**
   - Edit: `kyverno/generate-httproute-from-service.yaml`, update the domain part as needed (see comments inside file).

5. **/etc/hosts or DNS Entries:**
   - Example that matches above:
   ```
   192.168.88.55  headlamp.dcs.local
   192.168.88.55  <YOUR-APP>.dcs.local
   ```

### 🔒 TLS & Wildcard Certificate (HTTPS for Everything)

All exposed services and dashboards use a **single wildcard TLS certificate** (`*.dcs.local`) managed by cert-manager. This certificate is automatically used by the Gateway, providing HTTPS/TLS for every app subdomain (e.g., `headlamp.dcs.local`, `yourapp.dcs.local`).

- Certificate YAML: `Gateway-Fabric/wildcard-certificate.yaml`
- Secret name (for Gateway reference): `dcs-tls-certificate`
- Common Name (CN): `*.dcs.local`

**If you change your cluster's domain, update the `commonName` and `dnsNames` fields in this YAML and re-run the installation.**

No need to manage certificates per app—everything is secured out of the box!

> ⚠️ **Trident & DEX:** Skip all configuration, deployment and files for now! The platform doesn’t use them unless enabled in the future.

---

## 🚀 3. Platform Installation (First Time or Upgrade)

- **ALL IN ONE:**
  ```bash
  chmod +x install-all.sh
  ./install-all.sh
  ```
- **Per Component:**
  Go into the folder (e.g. `cd MetalLB`) and run `./install.sh`

---

## 🌐 4. Exposing Your Application (Automatic Ingress)

> **Kyverno makes it simple:**

When you want to expose a new Service outside the cluster, simply add this annotation to your Service YAML:
```yaml
metadata:
  annotations:
    expose: "true"
```
- The system auto-creates an HTTPRoute for you.
- The app’s public hostname will be:
  ```
  <service-name>-<namespace>.dcs.local
  ```
- **Naming Rules:** Service names must be DNS-safe (lowercase, hyphens, numbers only).

---

## 🚀 Adding & Exposing Your Application (Developer Quickstart)

To expose an app via the DCS platform:

1. Create your Service and Deployment YAML (see example below).
2. Add the annotation `expose: "true"` to your Service metadata.
3. Service name **must be DNS-safe:** lowercase, hyphens, and numbers only.

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: dev
  annotations:
    expose: "true"
spec:
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myrepo/myapp:latest
        ports:
        - containerPort: 8080
```

**That's it!** The platform will automatically generate an HTTPRoute and expose your app externally at:
  https://<service>-<namespace>.dcs.local

> **Production Note:** In production environments, DNS records for all exposed app domains should be managed by DevOps/infrastructure, pointing each `*.dcs.local` host to the LoadBalancer IP. Developers never need to use /etc/hosts outside of local testing/first-time dev.

> **Do NOT change core platform/infra configs for normal application deployments.**

---

## ✅ 5. Pre-Deployment Developer Checklist

- [ ] All relevant YAML files above are edited for your environment/domain/IP
- [ ] All pods are Running (MetalLB, Gateway Fabric, Kyverno, Headlamp):
  ```bash
  kubectl get pods -A | grep -E 'metallb|nginx-gateway|kyverno|headlamp'
  ```
- [ ] Gateway (Ingress) service shows assigned external IP:
  ```bash
  kubectl get svc -n nginx-gateway
  ```
- [ ] /etc/hosts or DNS records include every dashboard/app domain you’ll be testing
- [ ] You have a Headlamp admin token (see below)

---

## 🖥️ 6. Accessing Headlamp Dashboard

- Open: [https://headlamp.dcs.local](https://headlamp.dcs.local) (or your configured URL)
- Get a fresh admin token:
  ```bash
  kubectl get secret -n headlamp -o jsonpath='{.data.token}' \
    $(kubectl get secret -n headlamp | grep headlamp-admin-token | awk '{print $1}') | base64 -d
  ```

---

## 🏆 7. Troubleshooting & Resources

- **Pods won’t run or crash?** Check component logs. Example:
  ```bash
  kubectl logs -n metallb-system -l app=metallb
  kubectl logs -n nginx-gateway -l app.kubernetes.io/instance=nginx-gateway-fabric
  kubectl logs -n kyverno -l app.kubernetes.io/instance=kyverno
  kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp
  ```
- **Cannot access via browser?**
  - Double check DNS/hosts and that Gateway service has an external IP
  - Make sure Headlamp pod is running and ready
  - Re-generate the admin token if authentication fails
- **Component/feature docs:**
  - [MetalLB/README.md](MetalLB/README.md)
  - [Gateway-Fabric/README.md](Gateway-Fabric/README.md)
  - [kyverno/README.md](kyverno/README.md)
  - [Headlamp/README.md](Headlamp/README.md)

---

## 🛑 8. Trident & DEX (Storage & SSO) — Not Enabled
- Trident (NetApp storage) and DEX (OIDC SSO) are present for future scenarios.
- All files/values for them can be ignored unless specifically instructed otherwise by DevOps.
- They will NOT affect deployment or system function as long as `enabled: false` in config files.

---

## 🗺️ (Optional) Platform Architecture

```
Internet
   │
LoadBalancer IP (MetalLB)
   │
 DCS Gateway Fabric
   │
 ├───> Headlamp (dashboard)
 ├───> Apps (via HTTPRoutes)
 │
 └───> ... (future: DEX, Trident)
```

---

## 🎉 You’re Ready!
- Deploy, expose, and test your apps.
- For any further information, each component folder contains an English README.
- For platform edge-cases or for offline install, see this file’s Troubleshooting and official links.

---


