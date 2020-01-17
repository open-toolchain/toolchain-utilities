#!/bin/bash
region=${region:-"us-south"}
target_cr=${target_cr:-"mycluster168.icp:8500"}
install_filename="updated-private-worker-install.yaml"
dockerio_mapping_prefix=${dockerio_mapping_prefix:-""}

curl -o $install_filename  https://private-worker-service.$region.devops.cloud.ibm.com/install

cat $install_filename | grep -e 'gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd' -e 'image:'  \
  | sed 's/- gcr.io/gcr.io/g' \
  | sed 's/- image: gcr.io/gcr.io/g' \
  | sed 's/image: gcr.io/gcr.io/g' \
  | sed 's/image://g' \
  | awk '{$1=$1;print}' \
  | while read -r image ; do
    echo "Processing $image"
    docker pull $image
    new_image_tag=$image
    # if $image only have a single slash it is coming from dockerhub
    number_of_slashes=$(echo $image | tr -cd '/' | wc -c)
    if [ "$number_of_slashes" == "1" ]; then
      new_image_tag="$target_cr/${dockerio_mapping_prefix}${image}"   
    fi
    # replace the sha id reference in the tag if any
    new_image_tag="${new_image_tag/@sha256/}"
    # replace gcr.io to the target cr domain
    new_image_tag="${new_image_tag/gcr.io/$target_cr}"
    docker tag $image $new_image_tag
    docker push $new_image_tag
    # replace the image reference in the installation.yaml file
    sed -i "s~$image~$new_image_tag~g" $install_filename
done
echo "*****"
echo "Provisioning of docker images to $target_cr done."
echo "Update of the install file $install_filename done"
echo "Change the scope of the images to global before"
echo "running \"kubectl apply --filename $install_filename\" to install the delivery pipeline private worker"