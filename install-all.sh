#!/usr/bin/env bash
set -euo pipefail

########################################
# Weaver Platform - Install Script
# Initialization & Pre-Flight Section
########################################

PLATFORM_NS="platform"

########################################
# Logging helpers
########################################

log() {
  echo "[INFO ] $*"
}

warn() {
  echo "[WARN ] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
  exit 1
}

########################################
# Pre-flight checks
########################################

check_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command '$cmd' not found. Please install it before running this script."
  fi
}

preflight_checks() {
  echo "========================================="
  echo "   Weaver Platform - Pre-flight checks   "
  echo "========================================="

  log "Checking required commands..."
  check_command kubectl
  check_command helm

  log "Checking connectivity to Kubernetes cluster..."
  if ! kubectl cluster-info >/dev/null 2>&1; then
    error "Cannot connect to Kubernetes cluster (kubectl cluster-info failed)."
  fi

  log "Checking current Kubernetes context..."
  local ctx
  ctx=$(kubectl config current-context || true)
  if [ -z "$ctx" ]; then
    error "No current kubectl context configured."
  fi
  log "Using kubectl context: $ctx"

  log "Pre-flight checks completed successfully."
  echo
}

########################################
# Namespace creation (idempotent)
########################################

ensure_namespace() {
  if kubectl get ns "${PLATFORM_NS}" >/dev/null 2>&1; then
    log "Namespace '${PLATFORM_NS}' already exists. Skipping."
  else
    log "Creating namespace '${PLATFORM_NS}'..."
    kubectl create namespace "${PLATFORM_NS}"
    log "Namespace '${PLATFORM_NS}' created."
  fi
  echo
}

########################################
# Generic wait helper (for later components)
########################################

wait_for_pods() {
  local selector="$1"
  local timeout="${2:-300s}"

  log "Waiting for pods with selector '${selector}' in namespace '${PLATFORM_NS}'..."

  if ! kubectl get pods -n "${PLATFORM_NS}" -l "${selector}" >/dev/null 2>&1; then
    warn "No pods found yet for selector '${selector}' (namespace: ${PLATFORM_NS})."
  fi

  if ! kubectl wait --for=condition=Ready pods -n "${PLATFORM_NS}" -l "${selector}" --timeout="${timeout}"; then
    error "Timeout waiting for pods with selector '${selector}'."
  fi

  log "Pods with selector '${selector}' are Ready."
  echo
}

########################################
# MAIN – Up to the point *before* installing components
########################################

main() {
  echo "========================================="
  echo "      Weaver Platform - Installation     "
  echo "========================================="
  echo

  # Step 1: Pre-flight validation
  preflight_checks

  # Step 2: Ensure namespace exists
  ensure_namespace

  # From here we would normally begin installing the components...
  echo ">>> Pre-flight and namespace steps completed."
  echo ">>> Ready to begin installing components."
  echo
}

main "$@"

########################################
# Install MetalLB
########################################
install_metallb() {
  log "========================================="
  log " Installing MetalLB"
  log "========================================="

  local METALLB_DIR="./MetalLB"
  local METALLB_CHART="${METALLB_DIR}/metallb-0.15.2.tgz"
  local METALLB_VALUES="${METALLB_DIR}/values-metallb.yaml"
  local METALLB_IPPOOL="${METALLB_DIR}/metallb-addresspool.yaml"

  # Ensure files exist
  if [ ! -f "$METALLB_CHART" ]; then
    error "MetalLB chart not found at: $METALLB_CHART"
  fi
  if [ ! -f "$METALLB_VALUES" ]; then
    error "MetalLB values file not found at: $METALLB_VALUES"
  fi
  if [ ! -f "$METALLB_IPPOOL" ]; then
    error "MetalLB address pool file not found at: $METALLB_IPPOOL"
  fi

  log "Deploying MetalLB via Helm (upgrade/install)..."
  helm upgrade --install metallb "$METALLB_CHART" \
    -n "$PLATFORM_NS" \
    -f "$METALLB_VALUES" \
    --create-namespace

  log "Waiting for MetalLB controller to be Ready..."
  wait_for_pods "app=metallb,component=controller"

  log "Waiting for MetalLB speaker to be Ready..."
  wait_for_pods "app=metallb,component=speaker"

  log "Applying MetalLB IPAddressPool + L2Advertisement..."
  kubectl apply -n "$PLATFORM_NS" -f "$METALLB_IPPOOL"

  log "MetalLB installation completed successfully."
  echo
}


########################################
# Install cert-manager
########################################
install_cert_manager() {
  log "========================================="
  log " Installing cert-manager"
  log "========================================="

  local CM_DIR="./cert-manager"
  local CM_CHART="${CM_DIR}/cert-manager-v1.15.0.tgz"
  local CM_VALUES="${CM_DIR}/cert-manager-values.yaml"
  local CM_ISSUER_SELF="${CM_DIR}/issuer-selfsigned.yaml"
  local CM_ROOT_CA="${CM_DIR}/cluster-root-ca.yaml"
  local CM_CLUSTER_ISSUER="${CM_DIR}/cluster-issuer.yaml"

  # Validate files exist
  for f in "$CM_CHART" "$CM_VALUES" "$CM_ISSUER_SELF" "$CM_ROOT_CA" "$CM_CLUSTER_ISSUER"; do
      if [ ! -f "$f" ]; then
        error "Missing cert-manager file: $f"
      fi
  done

  log "Deploying cert-manager via Helm (upgrade/install)..."
  helm upgrade --install cert-manager "$CM_CHART" \
    -n "$PLATFORM_NS" \
    -f "$CM_VALUES" \
    --create-namespace

  log "Waiting for cert-manager components to be Ready..."
  wait_for_pods "app.kubernetes.io/name=cert-manager"
  wait_for_pods "app.kubernetes.io/name=cainjector"
  wait_for_pods "app.kubernetes.io/name=webhook"

  log "Applying cert-manager Issuers & Root CA..."

  log "1) Applying self-signed issuer..."
  kubectl apply -n "$PLATFORM_NS" -f "$CM_ISSUER_SELF"

  log "2) Applying root CA certificate..."
  kubectl apply -n "$PLATFORM_NS" -f "$CM_ROOT_CA"

  log "3) Applying cluster issuer..."
  kubectl apply -f "$CM_CLUSTER_ISSUER"

  log "cert-manager installation completed successfully."
  echo
}



########################################
# Install NGINX Gateway Fabric
########################################
install_gateway_fabric() {
  log "========================================="
  log " Installing NGINX Gateway Fabric"
  log "========================================="

  local NGF_DIR="./Gateway-Fabric"
  local NGF_CHART="${NGF_DIR}/nginx-gateway-fabric-1.5.1.tgz"
  local NGF_VALUES="${NGF_DIR}/values.yaml"
  local NGF_GATEWAY="${NGF_DIR}/gateway.yaml"
  local NGF_CERT="${NGF_DIR}/wildcard-certificate.yaml"

  # Validate files exist
  for f in "$NGF_CHART" "$NGF_VALUES" "$NGF_GATEWAY" "$NGF_CERT"; do
      if [ ! -f "$f" ]; then
        error "Missing NGINX Gateway Fabric file: $f"
      fi
  done

  log "Deploying NGINX Gateway Fabric via Helm (upgrade/install)..."
  helm upgrade --install nginx-gateway-fabric "$NGF_CHART" \
    -n "$PLATFORM_NS" \
    -f "$NGF_VALUES" \
    --create-namespace

  log "Waiting for the NGINX Gateway Fabric controller to be Ready..."
  wait_for_pods "app.kubernetes.io/name=nginx-gateway-fabric"

  log "Waiting for the NGINX data-plane to be Ready..."
  wait_for_pods "app.kubernetes.io/name=nginx-gateway"

  log "Applying wildcard TLS certificate..."
  kubectl apply -n "$PLATFORM_NS" -f "$NGF_CERT"

  log "Applying Gateway resource..."
  kubectl apply -n "$PLATFORM_NS" -f "$NGF_GATEWAY"

  log "NGINX Gateway Fabric installation completed successfully."
  echo
}


########################################
# Install Kyverno
########################################
install_kyverno() {
  log "========================================="
  log " Installing Kyverno"
  log "========================================="

  local KY_DIR="./kyverno"
  local KY_CHART="${KY_DIR}/kyverno-3.3.7.tgz"
  local KY_VALUES="${KY_DIR}/values.yaml"

  local KY_POLICIES=(
    "${KY_DIR}/add-gateway-parent-ref.yaml"
    "${KY_DIR}/enforce-cluster-ca-for-certificates.yaml"
    "${KY_DIR}/generate-httproute-from-service.yaml"
    "${KY_DIR}/kyverno-gateway-api-rbac.yaml"
    "${KY_DIR}/validate-service-naming.yaml"
  )

  # Validate files exist
  if [ ! -f "$KY_CHART" ]; then error "Missing: $KY_CHART"; fi
  if [ ! -f "$KY_VALUES" ]; then error "Missing: $KY_VALUES"; fi
  for f in "${KY_POLICIES[@]}"; do
    if [ ! -f "$f" ]; then error "Missing Kyverno policy file: $f"; fi
  done

  log "Deploying Kyverno via Helm (upgrade/install)..."
  helm upgrade --install kyverno "$KY_CHART" \
    -n "$PLATFORM_NS" \
    -f "$KY_VALUES" \
    --create-namespace

  log "Waiting for Kyverno controllers to be Ready..."

  # Admission controller
  wait_for_pods "app.kubernetes.io/name=kyverno,app.kubernetes.io/component=admission-controller"

  # Background controller
  wait_for_pods "app.kubernetes.io/name=kyverno,app.kubernetes.io/component=background-controller"

  # Cleanup controller
  wait_for_pods "app.kubernetes.io/name=kyverno,app.kubernetes.io/component=cleanup-controller"

  # Reports controller
  wait_for_pods "app.kubernetes.io/name=kyverno,app.kubernetes.io/component=reports-controller"

  log "Applying Kyverno policies and RBAC configurations..."

  for p in "${KY_POLICIES[@]}"; do
    log "Applying: $(basename "$p")"
    kubectl apply -f "$p"
  done

  log "Kyverno installation completed successfully."
  echo
}


########################################
# Install Headlamp Dashboard
########################################
install_headlamp() {
  log "========================================="
  log " Installing Headlamp"
  log "========================================="

  local HD_DIR="./Headlamp"
  local HD_CHART="${HD_DIR}/headlamp-0.34.0.tgz"
  local HD_VALUES="${HD_DIR}/headlamp-values.yaml"
  local HD_RBAC="${HD_DIR}/headlamp-admin-user.yaml"
  local HD_ROUTE="${HD_DIR}/headlamp-httproute-fabric.yaml"

  # Validate files exist
  for f in "$HD_CHART" "$HD_VALUES" "$HD_RBAC" "$HD_ROUTE"; do
    if [ ! -f "$f" ]; then
      error "Missing Headlamp file: $f"
    fi
  done

  log "Deploying Headlamp via Helm (upgrade/install)..."
  helm upgrade --install headlamp "$HD_CHART" \
    -n "$PLATFORM_NS" \
    -f "$HD_VALUES" \
    --create-namespace

  log "Waiting for Headlamp server to be Ready..."
  wait_for_pods "app.kubernetes.io/name=headlamp"

  log "Applying Headlamp admin RBAC..."
  kubectl apply -f "$HD_RBAC"

  log "Applying Headlamp HTTPRoute (NGINX Gateway Fabric)..."
  kubectl apply -n "$PLATFORM_NS" -f "$HD_ROUTE"

  log "Headlamp installation completed successfully."
  echo
}


########################################
# Install Mayastor
########################################
install_mayastor() {
  log "========================================="
  log " Installing Mayastor"
  log "========================================="

  local MS_DIR="./mayastor"
  local MS_CHART="${MS_DIR}/mayastor-2.9.3.tgz"
  local MS_VALUES="${MS_DIR}/values-mayastor.yaml"
  local MS_SC="${MS_DIR}/mayastor-sc-3rep.yaml"
  local MS_POOLS="${MS_DIR}/diskpools.yaml"

  # Validate files exist
  for f in "$MS_CHART" "$MS_VALUES" "$MS_SC" "$MS_POOLS"; do
    if [ ! -f "$f" ]; then
      error "Missing Mayastor file: $f"
    fi
  done

  log "Deploying Mayastor via Helm (upgrade/install)..."
  helm upgrade --install mayastor "$MS_CHART" \
    -n "$PLATFORM_NS" \
    -f "$MS_VALUES" \
    --create-namespace

  log "Waiting for Mayastor components to be Ready..."

  # ETCD (3 replicas)
  wait_for_pods "app=mayastor-etcd"

  # Agents
  wait_for_pods "app=mayastor-agent-core"
  wait_for_pods "app=mayastor-agent-ha"

  # Diskpool operator
  wait_for_pods "app=openebs-mayastor-diskpool"

  # IO Engine
  wait_for_pods "app=openebs-mayastor-io-engine"

  # CSI Components
  wait_for_pods "app=openebs-csi-driver-controller"
  wait_for_pods "app=openebs-csi-driver-node"

  log "Applying Mayastor DiskPools..."
  kubectl apply -n "$PLATFORM_NS" -f "$MS_POOLS"

  log "Applying Mayastor StorageClass (3 replicas)..."
  kubectl apply -f "$MS_SC"

  log "Mayastor installation completed successfully."
  echo
}


########################################
# Install Percona PostgreSQL Operator + Database Cluster
########################################
install_percona() {
  log "========================================="
  log " Installing Percona PostgreSQL"
  log "========================================="

  local PC_DIR="./percona"
  local PC_OPERATOR_CHART="${PC_DIR}/pg-operator-2.7.0.tgz"
  local PC_OPERATOR_VALUES="${PC_DIR}/values-operator.yaml"
  local PC_CR_FIXED="${PC_DIR}/pg-fixed.yaml"

  # Validate files exist
  for f in "$PC_OPERATOR_CHART" "$PC_OPERATOR_VALUES" "$PC_CR_FIXED"; do
    if [ ! -f "$f" ]; then
      error "Missing Percona file: $f"
    fi
  done

  log "Deploying Percona PostgreSQL Operator via Helm (upgrade/install)..."
  helm upgrade --install percona-operator "$PC_OPERATOR_CHART" \
    -n "$PLATFORM_NS" \
    -f "$PC_OPERATOR_VALUES" \
    --create-namespace

  log "Waiting for Percona Operator (controller) to be Ready..."
  wait_for_pods "app.kubernetes.io/name=percona-postgresql-operator,app.kubernetes.io/component=operator"

  log "Waiting for Percona Operator Webhook..."
  wait_for_pods "app.kubernetes.io/component=operator-webhook"

  log "Waiting for Percona Operator Scheduler..."
  wait_for_pods "app.kubernetes.io/component=operator-scheduler"

  log "Applying PostgreSQL Cluster CR (pg-fixed.yaml)..."
  kubectl apply -n "$PLATFORM_NS" -f "$PC_CR_FIXED"

  log "Waiting for PostgreSQL Primary instance to be Ready..."
  wait_for_pods "postgres-operator.crunchydata.com/role=master"

  log "Waiting for PostgreSQL Replica instances to be Ready..."
  wait_for_pods "postgres-operator.crunchydata.com/role=replica"

  log "Waiting for PgBouncer pods to be Ready..."
  wait_for_pods "postgres-operator.crunchydata.com/role=pgbouncer"

  log "Percona PostgreSQL installation completed successfully."
  echo
}

########################################
# Install Redis Operator + Redis Instance
########################################
install_redis() {
  log "========================================="
  log " Installing Redis Operator + Redis"
  log "========================================="

  local R_DIR="./redis"
  local R_OPERATOR_CHART="${R_DIR}/redis-operator-0.22.2.tgz"
  local R_OPERATOR_VALUES="${R_DIR}/redis-operator-values.yaml"
  local R_INSTANCE="${R_DIR}/redis-standalone.yaml"
  local R_SERVICE="${R_DIR}/redis-svc.yaml"

  # Validate files exist
  for f in "$R_OPERATOR_CHART" "$R_OPERATOR_VALUES" "$R_INSTANCE" "$R_SERVICE"; do
    if [ ! -f "$f" ]; then
      error "Missing Redis file: $f"
    fi
  done

  log "Deploying Redis Operator via Helm (upgrade/install)..."
  helm upgrade --install redis-operator "$R_OPERATOR_CHART" \
    -n "$PLATFORM_NS" \
    -f "$R_OPERATOR_VALUES" \
    --create-namespace

  log "Waiting for Redis Operator controller to be Ready..."
  wait_for_pods "app.kubernetes.io/name=redis-operator"

  log "Applying Redis standalone instance (CR)..."
  kubectl apply -n "$PLATFORM_NS" -f "$R_INSTANCE"

  log "Applying Redis service..."
  kubectl apply -n "$PLATFORM_NS" -f "$R_SERVICE"

  log "Waiting for Redis pod to be Ready..."
  wait_for_pods "app=my-redis"

  log "Redis installation completed successfully."
  echo
}

###############################################
#                  GARAGE                     #
###############################################

echo ""
echo "=============================================="
echo "🚀 Installing Garage (CRDs + Helm chart)"
echo "=============================================="
echo ""

# 1) CRDs – מתוך הריפו שחולץ: ./garage/garage/script/k8s/crd
echo "[Garage] Applying CRDs..."
kubectl apply -k ./garage/garage/script/k8s/crd
if [ $? -ne 0 ]; then
    echo "❌ Failed to apply Garage CRDs"
    exit 1
fi
echo "✔ Garage CRDs applied successfully."

# 2) התקנת ה-chart מה-TGZ: ./garage/garage-0.9.1.tgz
echo "[Garage] Deploying Garage Helm chart..."
helm upgrade --install garage ./garage/garage-0.9.1.tgz \
  -n platform --create-namespace \
  -f ./garage/values.override.yaml

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Garage Helm chart"
    exit 1
fi
echo "✔ Garage chart deployed."

# 3) לחכות שה-pods יהיו Ready
echo "[Garage] Waiting for pods to become ready..."
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=garage -n platform \
  --timeout=180s

if [ $? -ne 0 ]; then
    echo "❌ Garage pods failed to become ready"
    kubectl get pods -n platform | grep garage
    exit 1
fi

echo ""
echo "=============================================="
echo "✔ Garage installation completed successfully!"
echo "=============================================="
echo ""
kubectl get pods -n platform -l app.kubernetes.io/name=garage -o wide


