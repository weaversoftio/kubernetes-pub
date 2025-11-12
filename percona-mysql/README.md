# Create namespace
kubectl create namespace percona-mysql

# Apply ConfigMap with init.sql
kubectl apply -f initdb/configmap-initdb.yaml -n percona-mysql

# Install Percona Operator (from local Helm package)
helm install pxc-operator ./operator/pxc-operator-1.15.0.tgz -n percona-mysql

# Install Percona Database (from local Helm package + custom values)
helm install pxc-db ./database/pxc-db-1.15.0.tgz -n percona-mysql -f values-db.yaml

# (Optional) Run init job manually
kubectl apply -f initdb/job-initdb.yaml -n percona-mysql