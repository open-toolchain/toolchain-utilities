#!/bin/bash
target_cr=${target_cr:-"mycluster168.icp:8500"}
dockerio_mapping_prefix=${dockerio_mapping_prefix:-""}

docker pull --all-tags ibmcom/pipeline-base-image

docker images ibmcom/pipeline-base-image | tail --lines=+2 | awk '{print $2}' | sort -u | while read -r tag ; do
  image="ibmcom/pipeline-base-image:$tag"
  new_image_tag="$target_cr/${dockerio_mapping_prefix}$image"
  docker tag $image $new_image_tag
  docker push $new_image_tag
done
