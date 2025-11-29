#!/bin/bash
# generate usage helper function for createBucket.sh
help() {
    echo "Usage: createBucket.sh <bucketName>"
    echo "This script creates a bucket in the garage s3 and creates a key for the bucket"
    echo "The bucket name is the name of the bucket to create"
    echo "The script will return the secret key for the bucket"
    echo "The script will create a secret in the namespace with the name $bucketName-key"
    echo "The secret will contain the secret key, key name, and bucket name"
}
set -e

#find the garage pod in the cluster
#dont use the namespace it is inherited from the kubectl context
# this script creates a bucket in the garage s3 and creates a key for the bucket
#convert to a bash function
createBucket() {
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
    bucketName=$1
    #List all buckets in the garage s3
    kubectl exec -it $garagePod -c garage -- ./garage bucket create $bucketName
    # create a platform key for the bucket
    kubectl exec -it $garagePod -c garage -- /garage key create $bucketName-key
    # delegate read and write permissions to the platform key
    kubectl exec -it $garagePod -c garage -- /garage bucket allow $bucketName \
    --key $bucketName-key \
    --read --write
    # Get and print the platform key
    SECRET_KEY=$(kubectl exec $garagePod -- ./garage key info --show-secret $bucketName-key | awk -F': *' '/^Secret key/ {print $2}')
    # include the $bucketName-key in the secret
    #create or update the secret
    kubectl create secret generic $bucketName-bucket-secret --from-literal=secret-key=$SECRET_KEY --from-literal=key-name=$bucketName-key --from-literal=bucket-name=$bucketName --dry-run=client -o yaml | kubectl apply -f -
    #print the secret
    echo "Secret created/updated: $bucketName-bucket-secret"
    echo "Secret key: $SECRET_KEY"
    echo "Key name: $bucketName-key"
    echo "Bucket name: $bucketName"
}
# call the function return 
createBucket $1