#!/bin/bash
set -e

echo "======================================"
echo "   Installing Redis (Opstree Operator)"
echo "======================================"

# 1. Apply the Redis CR manifest
echo "[1/6] Applying redis-standalone.yaml..."
kubectl apply -f redis-standalone.yaml --wait

# 2. Apply the Redis Service manifest
echo "[2/6] Applying redis-svc.yaml..."
kubectl apply -f redis-svc.yaml --wait

# 3. Wait for Redis pod to appear
echo "[3/6] Waiting for Redis pod to be created..."
sleep 2
redisPod=$(kubectl get pods -l app=my-redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$redisPod" ]; then
    echo "ERROR: Redis pod not found after creation."
    exit 1
fi

echo "Redis pod: $redisPod"

# 4. Wait until the Redis pod is Running
echo "[4/6] Checking Redis pod status..."
status=$(kubectl get pod "$redisPod" -o jsonpath='{.status.phase}')

if [ "$status" != "Running" ]; then
    echo "Redis pod not running (current state: $status). Waiting..."
    kubectl wait --for=condition=ready pod/"$redisPod" --timeout=120s || {
        echo "ERROR: Redis pod failed to become ready."
        kubectl logs "$redisPod"
        exit 1
    }
fi

echo "Redis is running successfully ✔"


# 5. Check PVC creation
echo "[5/6] Checking PVC..."
pvcName=$(kubectl get pvc | grep my-redis | awk '{print $1}')

if [ -z "$pvcName" ]; then
    echo "ERROR: No PVC found for Redis!"
    exit 1
fi

pvcSize=$(kubectl get pvc "$pvcName" -o jsonpath='{.spec.resources.requests.storage}')

echo "Found Redis PVC: $pvcName"
echo "Storage size: $pvcSize"


# 6. Check service
echo "[6/6] Checking Redis service..."
svc=$(kubectl get svc my-redis --no-headers 2>/dev/null || true)

if [ -z "$svc" ]; then
    echo "ERROR: Redis service not found!"
    exit 1
fi

echo "Redis service is present ✔"
kubectl get svc my-redis

echo "======================================"
echo "      Redis Installation Complete"
echo "======================================"
