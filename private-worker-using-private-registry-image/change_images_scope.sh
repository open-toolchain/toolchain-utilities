#!/bin/bash
pw_namespace=tekton-releases
kubectl get image -n$pw_namespace | tail --lines=+2 | awk '{print $1}' | while read -r image ; do 
  echo "Changing scope of image $image to global"
  kubectl get image -n=$pw_namespace $image -o yaml | sed 's/scope: namespace/scope: global/g' | kubectl replace -f -
done

image=pipeline-private-worker
pw_namespace=ibmcom
echo "Changing scope of image $image to global"
kubectl get image -n=$pw_namespace $image -o yaml | sed 's/scope: namespace/scope: global/g' | kubectl replace -f -

image=pipeline-base-image
pw_namespace=ibmcom
echo "Changing scope of image $image to global"
kubectl get image -n=$pw_namespace $image -o yaml | sed 's/scope: namespace/scope: global/g' | kubectl replace -f -
