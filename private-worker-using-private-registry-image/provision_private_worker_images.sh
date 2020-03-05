#!/bin/bash
region=${region:-"us-south"}
target_cr=${target_cr:-"mycluster168.icp:8500"}
install_filename="updated-private-worker-install.yaml"
dockerio_mapping_prefix=${dockerio_mapping_prefix:-""}

curl -o $install_filename  https://private-worker-service.$region.devops.cloud.ibm.com/install

# Use yq to lint yaml and prevent continuous string definition for 'image:'' such as
#         image: >-
#          gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/webhook@sha256:7215a25a58c074bbe30a50db93e6a47d2eb5672f9af7570a4e4ab75e50329131
yq read --doc '*' $install_filename | grep -e 'gcr.io/tekton-releases/github.com/tektoncd/pipeline' -e 'image:'  \
  | sed 's/- gcr.io/gcr.io/g' \
  | sed 's/- image: gcr.io/gcr.io/g' \
  | sed 's/image: gcr.io/gcr.io/g' \
  | sed 's/image://g' \
  | awk '{$1=$1;print}' \
  | while read -r image ; do
    echo "Processing $image"
    docker pull $image
    new_image_tag=$image
    # if image tag was including a tag - keep the imagename and tag (not the shaid value)
    new_image_tag=$(echo $new_image_tag | awk -F: '{print $1":"$2}')
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
echo "If target is IBM Cloud Private, change the scope of the images to global - https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_images/change_scope.html"
echo "Run the following command \"kubectl apply --filename $install_filename\" to install the delivery pipeline private worker"