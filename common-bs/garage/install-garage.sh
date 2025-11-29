#!/bin/bash
set -e
# install or upgrade garage
helm upgrade --install garage garage-0.9.1.tgz -f values.override.yaml --wait

garagePod=$(kubectl get pods -l app.kubernetes.io/name=garage -o custom-columns=:metadata.name --no-headers | head -n1)
if [ -z "$garagePod" ]; then
    echo "No garage pod found"
    exit 1
fi
echo "Garage pod: $garagePod"
#check if the garage pod is running
if [ $(kubectl get pods $garagePod -o jsonpath='{.status.phase}') != "Running" ]; then
    echo "Garage pod is not running"
    exit 1
fi

#get the data garage pvc size in integer value
pvcSize=$(kubectl get pvc data-garage-0 -o jsonpath='{.spec.resources.requests.storage}' | awk -F'Gi' '{print $1}')
if [ -z "$pvcSize" ]; then
    echo "No pvc size found"
    exit 1
fi
echo "Found garage Pvc size: $pvcSize"

#get the node id
nodeId=$(kubectl get garagenode -o custom-columns=:metadata.name --no-headers | head -n1)
if [ -z "$nodeId" ]; then
    echo "No node found"
    exit 1
fi
echo "Node id: $nodeId"
#initialize the garage layout
#get the node id
echo "Initializing garage layout with size: $pvcSize"
#print the command
echo "kubectl exec -it $garagePod -c garage -- ./garage layout assign -z dc1 -c ${pvcSize}G $nodeId"
kubectl exec -it $garagePod -c garage -- ./garage layout assign -z dc1 -c ${pvcSize}G $nodeId  &> /dev/null
#show the layout
kubectl exec -it $garagePod -c garage -- ./garage layout show
#apply the layout
kubectl exec -it $garagePod -c garage -- ./garage layout apply --version 1