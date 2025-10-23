# Trident - NetApp Storage CSI Driver

Samsung Kubernetes Platform

## 📋 Overview

NetApp Trident is a fully supported, open-source dynamic storage orchestrator for Kubernetes. It enables persistent storage for containerized applications using NetApp storage systems.

**Features:**
- ✅ Dynamic provisioning of persistent volumes
- ✅ Support for NetApp ONTAP (NAS and SAN)
- ✅ Volume snapshots and cloning
- ✅ Volume expansion
- ✅ Storage efficiency (thin provisioning, deduplication, compression)
- ✅ Multi-protocol support (NFS, iSCSI, NVMe/TCP)
- ✅ Integration with Kubernetes CSI

## 📁 Files

```
Trident/
├── install.sh                          # Automated installation script
├── trident-operator-100.2410.0.tgz    # Trident Operator Helm chart
├── trident-orchestrator.yaml          # TridentOrchestrator CR (reference)
├── backend-ontap-nas.yaml             # Backend configuration (reference)
├── secret-template.yaml               # NetApp credentials template
├── storageclass.yaml                  # StorageClass definition (reference)
└── README.md                          # This file
```

## 🚀 Installation

### Prerequisites

- **NetApp ONTAP storage system** with:
  - Management LIF accessible from Kubernetes cluster
  - Data LIF accessible from Kubernetes nodes
  - SVM (Storage Virtual Machine) configured
  - NFS export policies configured
- **Network connectivity** between Kubernetes nodes and NetApp storage
- **NFS utilities** installed on all Kubernetes nodes:
  ```bash
  # On Ubuntu/Debian
  sudo apt-get install -y nfs-common
  
  # On RHEL/CentOS
  sudo yum install -y nfs-utils
  ```

### Option 1: Automated (Recommended)

```bash
# 1. Edit cluster configuration
vim ../cluster-config.yaml

# 2. Enable Trident and configure NetApp backend
# Set: trident.enabled: true
# Update: management_lif, data_lif, svm, credentials

# 3. Run installation
./install.sh
```

The script will:
1. Create namespace
2. Install Trident Operator via Helm
3. Create TridentOrchestrator
4. Create NetApp backend secret
5. Configure NetApp backend
6. Create StorageClass

### Option 2: Manual

```bash
# 1. Create namespace
kubectl create namespace trident

# 2. Install Trident Operator
helm install trident-operator trident-operator-100.2410.0.tgz -n trident

# 3. Wait for operator
kubectl wait --for=condition=ready pod -l app=trident-operator -n trident --timeout=120s

# 4. Create TridentOrchestrator
kubectl apply -f trident-orchestrator.yaml

# 5. Create NetApp credentials secret
# Edit secret-template.yaml with your credentials, then:
kubectl apply -f secret-template.yaml

# 6. Create backend configuration
# Edit backend-ontap-nas.yaml with your NetApp details, then:
kubectl apply -f backend-ontap-nas.yaml

# 7. Create StorageClass
kubectl apply -f storageclass.yaml
```

## ⚙️ Configuration

Edit `cluster-config.yaml`:

```yaml
trident:
  enabled: true  # ← Set to true to install
  namespace: "trident"
  version: "24.10.0"
  
  backend:
    name: "ontap-nas-backend"
    driver: "ontap-nas"
    management_lif: "192.168.1.100"  # ← NetApp management IP
    data_lif: "192.168.1.101"        # ← NetApp data IP
    svm: "svm_name"                  # ← Your SVM name
    
    credentials:
      username: "admin"              # ← NetApp admin user
      password: "password"           # ← NetApp password
    
    storage_prefix: "trident_"
    nfs_mount_options: "nfsvers=4.1"
  
  storageclass:
    name: "netapp-storage"
    is_default: true                 # Set as default StorageClass
    allow_volume_expansion: true
    reclaim_policy: "Delete"
```

## ✅ Verification

### Check Trident Installation

```bash
# Check pods
kubectl get pods -n trident

# Check TridentOrchestrator
kubectl get tridentorchestrator

# Expected output:
# NAME      STATUS      VERSION
# trident   Installed   24.10.0

# Check Trident version
kubectl get tridentversion -n trident
```

### Check Backend Configuration

```bash
# Check TridentBackendConfig
kubectl get tbc -n trident

# Check backend status
kubectl get tridentbackends -n trident

# Expected status: "Bound" or "Online"

# Describe backend for details
kubectl describe tbc backend-tbc-ontap-nas -n trident
```

### Check StorageClass

```bash
# List StorageClasses
kubectl get storageclass

# Check if netapp-storage is default
kubectl get storageclass netapp-storage -o yaml
```

### Test Storage Provisioning

```bash
# Create a test PVC
kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: netapp-storage
EOF

# Check PVC status (should be Bound)
kubectl get pvc test-pvc

# Check PV created
kubectl get pv

# Cleanup
kubectl delete pvc test-pvc
```

## 🎯 Usage Examples

### Example 1: Basic PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: netapp-storage
```

### Example 2: StatefulSet with Persistent Storage

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-database
spec:
  serviceName: my-database
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: netapp-storage
      resources:
        requests:
          storage: 20Gi
```

### Example 3: Volume Snapshot

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-app-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: my-app-data
```

## 🔧 Troubleshooting

### Trident not installing

```bash
# Check operator logs
kubectl logs -n trident -l app=trident-operator

# Check TridentOrchestrator status
kubectl describe tridentorchestrator trident
```

### Backend not connecting

```bash
# Check backend status
kubectl get tbc -n trident
kubectl describe tbc backend-tbc-ontap-nas -n trident

# Common issues:
# - Management LIF not reachable
# - Wrong credentials
# - SVM name incorrect
# - Network connectivity issues

# Test connectivity from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod:
nc -zv <MANAGEMENT_LIF> 443
```

### PVC stuck in Pending

```bash
# Check PVC events
kubectl describe pvc <pvc-name>

# Check Trident logs
kubectl logs -n trident -l app=controller.csi.trident.netapp.io

# Common issues:
# - Backend not online
# - Insufficient storage
# - Export policy restrictions
# - Network issues
```

### NFS mount issues

```bash
# Check node NFS utilities
# On each node:
sudo systemctl status nfs-client.target

# Check NFS exports on NetApp
# On NetApp CLI:
vserver export-policy rule show

# Check mount from node
sudo mount -t nfs <DATA_LIF>:/volume /mnt/test
```

## 🔐 Security Best Practices

### 1. Secure Credentials

```bash
# Use Kubernetes secrets for NetApp credentials
# Never commit credentials to Git!

# Create secret manually:
kubectl create secret generic netapp-credentials \
  --from-literal=username='admin' \
  --from-literal=password='SecurePassword123!' \
  -n trident
```

### 2. Network Security

- Use dedicated VLAN for storage traffic
- Restrict access to management LIF
- Configure export policies properly
- Use TLS for management communication

### 3. RBAC

- Limit who can create PVCs
- Restrict StorageClass usage with RBAC
- Use separate credentials for Trident (not cluster admin)

## 📊 NetApp Backend Types

Trident supports multiple NetApp storage drivers:

| Driver | Protocol | Use Case |
|--------|----------|----------|
| `ontap-nas` | NFS | File storage, shared access |
| `ontap-nas-economy` | NFS | Cost-optimized file storage |
| `ontap-nas-flexgroup` | NFS | Large-scale file storage |
| `ontap-san` | iSCSI/FC | Block storage, databases |
| `ontap-san-economy` | iSCSI/FC | Cost-optimized block storage |

This installation uses `ontap-nas` for NFS-based storage.

## 🔄 Advanced Configuration

### Volume Import

Import existing NetApp volumes:

```bash
tridentctl import volume <backend-name> <volume-name> \
  -f pvc.yaml \
  -n trident
```

### Backend Update

Update backend configuration:

```bash
# Edit backend config
kubectl edit tbc backend-tbc-ontap-nas -n trident

# Trident will automatically reconcile
```

### Multiple Backends

Create additional backends for different storage tiers:

```yaml
# gold-tier backend
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-gold
spec:
  backendName: gold-tier
  # ... configure with SSD aggregate
```

## 🌐 Offline/Air-Gapped Installation

For environments without internet access:

### 1. Images Required

```bash
# Trident images (already in offline-images/):
- docker.io/netapp/trident:24.10.0
- docker.io/netapp/trident-autosupport:24.10.0
- docker.io/netapp/trident-operator:24.10.0
```

### 2. Update Image References

Edit `cluster-config.yaml` to use your private registry:

```yaml
trident:
  images:
    trident: "private-registry.company.com/netapp/trident:24.10.0"
    autosupport: "private-registry.company.com/netapp/trident-autosupport:24.10.0"
```

## 📚 More Information

- [Trident Documentation](https://docs.netapp.com/us-en/trident/)
- [Trident GitHub](https://github.com/NetApp/trident)
- [NetApp ONTAP](https://docs.netapp.com/us-en/ontap/)
- [Kubernetes CSI](https://kubernetes-csi.github.io/docs/)

## 🆘 Support

For NetApp Trident issues:
1. Check Trident logs: `kubectl logs -n trident -l app=controller.csi.trident.netapp.io`
2. Review backend configuration: `kubectl get tbc -n trident -o yaml`
3. Consult [NetApp Documentation](https://docs.netapp.com/us-en/trident/)
4. Check [GitHub Issues](https://github.com/NetApp/trident/issues)


