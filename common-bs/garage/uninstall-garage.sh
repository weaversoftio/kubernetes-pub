#!/bin/bash
set -e

#ask for confirmation
read -p "Are you sure you want to uninstall garage? This will delete all data and configuration. (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Uninstall cancelled"
    exit 1
fi
# delete the pvc data-garage-0 meta-garage-0
#delete all garagenodes 
helm delete garage
kubectl delete garagenodes --all
#delete all pvc related to garage
kubectl delete pvc -l app.kubernetes.io/name=garage
