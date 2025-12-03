#!/bin/bash
set -e

NAMESPACE="platform"
RELEASE_NAME="headlamp"
CHART="headlamp-0.34.0.tgz"
VALUES_FILE="headlamp-values.yaml"
HTTPROUTE_FILE="headlamp-httproute-fabric.yaml"
RBAC_FILE="headlamp-admin-user.yaml"

echo "==============================================="
echo "Installing Headlamp"
echo "==============================================="

echo "[1/6] Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "[2/6] Applying RBAC..."
kubectl apply -f "$RBAC_FILE" || {
    echo "ERROR: Failed applying RBAC"
    exit 1
}

echo "[3/6] Deploying Headlamp Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART" -f "$VALUES_FILE" -n "$NAMESPACE" --wait || {
    echo "ERROR: Helm install failed"
    exit 1
}

echo "[4/6] Applying HTTPRoute..."
kubectl apply -f "$HTTPROUTE_FILE" -n "$NAMESPACE" || {
    echo "ERROR: Failed applying HTTPRoute"
    exit 1
}

echo "[INFO] HTTPRoute created successfully:"
kubectl get httproute headlamp-route-fabric -n "$NAMESPACE" -o wide

echo "[5/6] Checking deployment rollout..."
kubectl rollout status deployment/"$RELEASE_NAME" -n "$NAMESPACE" --timeout=120s || {
    echo "ERROR: Deployment did not roll out successfully"
    exit 1
}

POD=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=headlamp \
    -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "ERROR: Headlamp pod was not found"
    exit 1
fi

echo "Headlamp Pod: $POD"

echo "[6/6] Validating service..."
kubectl get svc -n "$NAMESPACE" headlamp -o wide || {
    echo "ERROR: Service headlamp not found"
    exit 1
}

echo "==============================================="
echo "Headlamp installation complete"
echo "==============================================="
