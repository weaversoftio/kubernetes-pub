## How to expose a Service with Kyverno (Convention over Configuration)

Concept: add the annotation `expose: "true"` to a Service and Kyverno will auto‑create an `HTTPRoute` with the host pattern:
`{app}-{namespace}.{clusterName}.{dnsSuffix}`

The placeholders `{clusterName}` and `{dnsSuffix}` are loaded from the `ConfigMap` `kyverno-coc-config` in the `kyverno` namespace.

### Prerequisites
- Gateway API CRDs are installed (`HTTPRoute`, etc.).
- Your Gateway (NGINX Gateway Fabric by default) is running. The policies assume `Gateway` name `dcs-gateway-fabric` in namespace `nginx-gateway` (adjust if needed).
- Create the ConfigMap with lowercase values only:
```bash
kubectl -n kyverno create configmap kyverno-coc-config \
  --from-literal=clusterName=cluster-ui \
  --from-literal=dnsSuffix=dns.local \
  -o yaml --dry-run=client | kubectl apply -f -
```

### Create an app and expose it
1) Create a namespace, a Deployment and a Service, then add the annotation `expose: "true"`:
```bash
kubectl create ns demo-coc || true
kubectl -n demo-coc create deployment nginx --image=nginx --port=80 || true
kubectl -n demo-coc expose deployment nginx --port=80 || true
kubectl -n demo-coc annotate service nginx expose="true" --overwrite
```

2) Wait 3–10 seconds and verify the `HTTPRoute` and hostname:
```bash
kubectl -n demo-coc get httproute
kubectl -n demo-coc get httproute nginx-route -o jsonpath='{.spec.hostnames[0]}'; echo
```

3) Point DNS/hosts to your Gateway VIP (via MetalLB):
```bash
# Example: add to /etc/hosts on a test workstation
<GATEWAY_VIP>  nginx-demo-coc.cluster-ui.dns.local
```

4) End‑to‑end verification:
```bash
kubectl -n demo-coc describe httproute nginx-route | sed -n '1,120p'
curl -k https://nginx-demo-coc.cluster-ui.dns.local
```

### Common customizations
- Change domain/cluster name: update only the `kyverno-coc-config` ConfigMap (no policy change needed).
- Change Gateway: update `parentRefs` (`name`/`namespace`) in both policies:
  - `generate-httproute-from-service.yaml`
  - `add-gateway-parent-ref.yaml`
- Services not on port 80: tweak the policy to select another port (e.g., `spec.ports[0]` or a named port).

### Remove exposure
- To unexpose a Service:
```bash
kubectl -n <ns> annotate svc <name> expose-
```
The policy uses `synchronize: true` so the `HTTPRoute` will be deleted automatically.

### Troubleshooting
- No `HTTPRoute` created:
  - Ensure the Service has `metadata.annotations.expose: "true"`.
  - Check Kyverno logs:
    ```bash
    kubectl -n kyverno logs deploy/kyverno-admission-controller --since=10m | tail -n 120
    kubectl -n kyverno logs deploy/kyverno-background-controller --since=10m | tail -n 120
    ```
  - Hostname must be lowercase (Gateway API DNS requirement). Update the ConfigMap to lowercase values.
- Permissions: ensure `ClusterRole/ClusterRoleBinding` from `kyverno-gateway-api-rbac.yaml` exist and that `auth can-i create httproutes` returns `yes` for Kyverno service accounts.


