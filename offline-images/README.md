# 📦 Offline Images Backup - 4 Kubernetes Tools

Container images backup for:
- **Headlamp** - Kubernetes Dashboard
- **Kyverno** - Policy Engine  
- **MetalLB** - Load Balancer
- **Ingress NGINX** - Ingress Controller

---

## 📁 Directory Structure

```
offline-images/
├── images-list.txt         # List of 10 images
├── download-images.sh      # Download script
├── load-images.sh          # Load script
├── README.md               # This guide
└── images-tar/             # .tar files (created automatically)
    ├── ghcr.io_headlamp-k8s_headlamp_v0.34.0.tar
    ├── reg.kyverno.io_kyverno_kyverno_v1.15.1.tar
    └── ... (10 files)
```

---

## 🚀 Usage

### Step 1: Download Images

```bash
cd /home/master/dcs-k8s-configs/offline-images
chmod +x download-images.sh load-images.sh
./download-images.sh
```

**⏱️ Estimated time:** 10-20 minutes (depends on network speed)  
**💾 Estimated size:** ~1.0 GB

---

### Step 2: Load Images (on another machine/offline)

Transfer the directory to the target machine, then:

```bash
cd offline-images
./load-images.sh
```

---

## 📦 File Transfer

### Option 1: tar.gz Archive

```bash
# Package
cd /home/master/dcs-k8s-configs
tar -czf offline-images-backup.tar.gz offline-images/

# Archive size
ls -lh offline-images-backup.tar.gz

# On target machine - extract
tar -xzf offline-images-backup.tar.gz
cd offline-images
./load-images.sh
```

### Option 2: USB/External Drive

```bash
cp -r /home/master/dcs-k8s-configs/offline-images /media/usb/
```

### Option 3: SCP/rsync

```bash
scp -r offline-images/ user@remote-server:/path/to/destination/
```

---

## 📊 Images List

### 1️⃣ Headlamp (1 image)
- `ghcr.io/headlamp-k8s/headlamp:v0.34.0`

### 2️⃣ Kyverno (4 images)
- `reg.kyverno.io/kyverno/kyverno:v1.15.1`
- `reg.kyverno.io/kyverno/background-controller:v1.15.1`
- `reg.kyverno.io/kyverno/cleanup-controller:v1.15.1`
- `reg.kyverno.io/kyverno/reports-controller:v1.15.1`

### 3️⃣ MetalLB (3 images)
- `quay.io/metallb/controller:v0.15.2`
- `quay.io/metallb/speaker:v0.15.2`
- `quay.io/frrouting/frr:9.1.0`

### 4️⃣ Ingress NGINX (2 images)
- `registry.k8s.io/ingress-nginx/controller:v1.11.3`
- `registry.k8s.io/defaultbackend-amd64:1.5`

**Total: 10 images**

---

## 🔄 Update Images

When updating tool versions:

1. Edit `images-list.txt` with new versions
2. Run `./download-images.sh` again
3. Only new images will be downloaded (old ones are not deleted)

---

## ✅ Verification

```bash
# Check images loaded to containerd
sudo crictl images

# Check directory size
du -sh images-tar/

# Count files
ls -1 images-tar/*.tar | wc -l

# List files with sizes
ls -lh images-tar/
```

---

## 🔧 Troubleshooting

### Issue: "Permission denied"
```bash
# Ensure sudo permissions
sudo -v
```

### Issue: "Image already exists"
```bash
# This is OK - script skips existing images
```

### Issue: "No space left on device"
```bash
# Check free space
df -h
# Clean old images
sudo crictl rmi --prune
```

---

## 📝 Important Notes

- ✅ Scripts require `sudo` (to work with containerd)
- ✅ Images are saved in containerd namespace: `k8s.io`
- ✅ Tar files are compatible with containerd/docker/cri-o
- ✅ Files can also be used with `docker load`
- ⚠️ File size can reach 2 GB - ensure sufficient space

---

## 📅 Creation Date

Created: `$(date '+%Y-%m-%d %H:%M:%S')`  
Kubernetes version: v1.29.6  
System: Ubuntu 20.04 LTS

---

## 🆘 Support

For questions or issues:
1. Check script logs
2. Check `sudo crictl images` - are the images present?
3. Check `journalctl -u containerd` - containerd logs

---

✅ **All rights reserved © 2025**

